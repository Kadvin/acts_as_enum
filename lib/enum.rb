module ActiveModel #:nodoc:
  module Acts #:nodoc:
    module Enum
      # base is the active-record base class
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.send(:class_inheritable_hash, :enums)
        base.enums = {}
        base.send(:alias_method_chain, :write_attribute, :enum) if base.respond_to? :write_attribute
      end

      module ClassMethods
        #
        # == Declare a field acts as enum
        # That is to say, this field's value should be limited in several values your defined
        # 
        # *field*: the attribute name
        # *args*:  the enum values in first, the options last
        #
        # Example:
        #    acts_as_enum :gender, :male, :female
        #    acts_as_enum :rank, 1..5,
        #                 :allow_nil => false
        #                 :aliases  => %w[bad common good excellent awsome]
        #                 :labels   => %w[Badone Common Goodman Excellent Awsome]
        #
        def acts_as_enum(field, *args)
          field = field.to_sym
          self.enums[field] = store = {}
          options = args.extract_options!
          options.symbolize_keys!
          store[:values] = if args.length == 1 and args.first.is_a?(Range) #采用Range声明
            args.first.to_a
          else # declared in form of an expanded array
            args
          end
          store[:aliases] = if options[:aliases]
            raise "You should specify an array as aliases" unless options[:aliases].is_a?(Array)
            raise "The aliases length doesn't equal to enum values" if options[:aliases].length != store[:values].length
            options[:aliases]
          else
            store[:values].map{|v| v.to_s.underscore}
          end
          store[:labels] = if options[:labels]
            raise "You should specify an array as labels" unless options[:labels].is_a?(Array)
            raise "The labels length doesn't equal to enum values" if options[:labels].length != store[:values].length
            options[:labels]
          else
            i18n_labels(field, store[:aliases])
          end
          store[:options] = []
          store[:values].each_with_index do |value, idx|
            store[:options] << [store[:labels][idx], value]
          end
          field_name = field.to_s
          class_eval <<-CODE
            def self.#{field_name.pluralize}
              enums[:#{field}][:values]
            end
            def self.#{field_name}_aliases
              enums[:#{field}][:aliases]
            end
            def self.#{field_name}_labels
              enums[:#{field}][:labels]
            end
            def self.#{field_name}_options
              enums[:#{field}][:options]
            end
          CODE
          class_eval do
            define_method field_name + "_alias" do
              target_by_value(store[:aliases], store[:values], field_name)
            end
            define_method field_name + "_label" do
              target_by_value(store[:labels], store[:values], field_name)
            end
            store[:aliases].each do |alias_value|
              define_method format("%s_%s?",alias_value.to_s.underscore, field) do
                alias_value == target_by_value(store[:aliases], store[:values], field_name)
              end
            end
            # For active-model to alias_method_chain 
            define_method field_name + "=" do |value|
              instance_variable_set("@#{field_name}", converted_enum(field_name, value))
            end unless respond_to?(:write_attribute) # None Active-Record
          end
          # validates for models with active-model validations
          allow_nil = options[:allow_nil].nil? ? true : options[:allow_nil]
          self.validates field, :inclusion => {:in => store[:values]},
            :allow_nil => allow_nil if self.respond_to?(:validates)
          # scope for active records
          store[:aliases].each_with_index do |alias_value, index|
            value = store[:values][index]
            self.scope format("%s_%ss", alias_value, field), lambda{where("#{field} = ?", value)}
          end if (self <=> ActiveRecord::Base) == 1 # Only define scope for active records
        end

        # Judge a field is enum or not
        def enum?(field)
          !!self.enums[field.to_sym]
        end
        
        private
        def i18n_labels(field, aliases)
          aliases.map do |alias_value|
            I18n.t(alias_value, :scope=>[self.name.underscore, field], :raise=>true) rescue alias_value.humanize
          end
        end

      end

      module InstanceMethods
        # define methods for instance
        def target_by_value(targets, values, field)
          value = self.send(field)
          return nil if value.nil?
          value = converted_enum(field, value)
          index = values.index(value)
          targets[index]
        end
        def converted_enum(attr, value)
          if store = self.class.enums[attr.to_sym]
            if value.nil? # Nil need not be converted
              value
            elsif store[:values].index(value) # value was found in the enum values
              value
            else # conver the value according to the sample value klass
              sample = store[:values].first
              if value.class == sample.class # need not be converted for same klass
                value
              else
                case sample
                when Symbol then value.to_sym
                when String then value.to_s
                when Numeric then if Symbol === value
                    value.to_s.to_i # :'1'.to_i => 120202, :'1'.to_s => '1'.to_i => 1
                  else
                    value.to_i
                  end
                end
              end
            end
          else
            value
          end
        end
        private :target_by_value, :converted_enum
        # Active record:: when a enum value was set ,convert it if necessary
        def write_attribute_with_enum(attr, value)
          write_attribute_without_enum attr, converted_enum(attr, value)
        end

      end

    end

  end
end
