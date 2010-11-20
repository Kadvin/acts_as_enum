module ActiveRecord #:nodoc:
  module Acts #:nodoc:
    module Enum

      def self.included(base)
        base.extend(ClassMethods)

        base.metaclass.send :alias_method, :columns_without_enum, :columns
        base.metaclass.send :alias_method, :columns, :columns_with_enum
      end

      module ClassMethods
        #
        # ==为ActiveRecord模型声明某个字段为枚举类型
        #   TODO 增加 validates_inclusion_of
        # 声明方式：
        # * 采用数组展开式声明，其枚举仅包含值，不包含枚举的显示值(我们会到资源文件中寻找相应的显示值)
        #   acts_as_enum :gender, :male, :female, :taijian 
        #   acts_as_enum :gender, *%w[male female taijian]
        # * 采用Range进行声明，其枚举仅包含值，不包含枚举的显示值
        #   acts_as_enum :income, 1..3
        #  也可以为这类调用加上显示参数:
        #   acts_as_enum :gender, :male, :female, :taijian , "male"" => "男性, "female" => "女性", "taijian" => "太监"
        #   acts_as_enum :income, 1..3, 1 => "穷人", 2 => "中产", 3 => "富人"
        # * 如果不在乎枚举的顺序，可以直接声明显示值，而不设置枚举值，这样的话，枚举值将会从显示Hash的Values中获取
        #   acts_as_enum :gender, "male"" => "男性, "female" => "女性", "taijian" => "太监"
        #
        # 任意一个column，都可以判断是否是enum类型
        #  column = Approach.columns_hash["name"]
        #  column.enum?    => false
        # 定义了枚举值限制之后，用户就可以直接使用以下方法:
        #  column = Approach.columns_hash["type"]
        #  column.enum_values                 => 'PnpApproach', 'PortalApproach'
        #  column.enum_options                => ['PNP推广','PnpApproach'], ['门户推广','PortalApproach']
        #  column.enum_hash_options           => 'PNP推广'=>'PnpApproach', '门户推广'=>'PortalApproach'
        #  column.enum_display('PnpApproach') => 'PNP推广'
        #  column.enum_value("PNP推广")       => PnpApproach
        # 也支持如下实例方法
        #  approach = Approach.new
        #  approach.pnp_approach_type?
        #  approach.sms_content_catalog?
        #  
        # 相应枚举值的中文名，其寻找的Key为: approach.catalog.sms_content
        # 如果寻找不到，则将其显示名设置为值，如果数组中有重复的值，则会合并
        def acts_as_enum(field, *args)
          column = columns_hash[field.to_s]
          raise format("Can't find column with name = %s to declair as enum", field) if column.nil?
          text_options = args.extract_options!
          enum_options = if( args.empty? )# 仅有显示参数，枚举值需要从显示hash里面抽取
            text_options.invert
          elsif args.length == 1 and args.first.is_a?(Range) #采用Range声明
            range_values = args.first.to_a
            range_values.map{|item| [display_value(field, item, text_options), item]}
          else #采用数组展开式声明
            args.map{|item| [display_value(field, item, text_options), item]}
          end
          #只有是Enum的Column实例才会有这些方法
          column.instance_eval do
            @enum_options = enum_options
            def enum_options; @enum_options end
            def enum_values
              @enum_options.collect{|pair| pair.last}
            end
            def enum_hash_options
              hash = {}
              @enum_options.each{|pair| hash[pair.first] = pair.last}
              hash
            end
            def enum_value(display)
              pair = @enum_options.find{|option| option.first == display}
              pair.nil? ? nil : pair.last
            end
            def enum_display(value)
              pair = @enum_options.find{|option| option.last.to_s == value.to_s}
              pair.nil? ? nil : pair.first
            end
            def enum_text(value); enum_display(value) end
          end
          # 对象实例方法
          column.enum_values.each do |value|
            next if value.to_s =~ /^[-.\d]+$/
            class_eval <<-CODE
              def #{value.to_s.underscore}_#{field}?
                self.#{field} == '#{value}'
              end
            CODE
          end
           class_eval <<-CODE
            def #{field}_display
              column = self.class.columns_hash['#{field}']
              value = self.send('#{field}')
              column.enum_display(value)
            end
          CODE
        end

        def excluded_klasses
          [ActiveRecord::Base]
        end

        #
        # 如果父类声明了某个字段acts_as_enum，但子类的column并不会知道
        #   例如 EtlTask 声明了 acts_as_enum :type, ...
        #   EtlTask.type_column.enum? #=>true
        # 但 EtlTableTasl.type_column.enum?将会返回false
        # 对于这种问题，有多种解决方案
        #   一种是通过对columns方法进行alias_method_chain来解决
        #   另外一种是监听基类的extended，而后替换自己的@columns属性中相应的值
        #
        def columns_with_enum
          # 父类没有关联表，例如AR::Base, Dimension等
          # 这个地方的逻辑很麻烦，这样写是当前能有的唯一方法
          # begin
          #   superclass.columns
          # rescue
          #   return columns_without_enum
          # end
          # 这种写法也会出错，因为当
          # self = XxxDimension
          # superclass = ActiveWarehouse::Dimension.columns的时候
          # superclass.superclass = ActiveRecord::Base
          # 最终是
          # begin
          #   superclass.columns  # 1. ActiveWarehouse::Dimension.columns -> error
          # rescue
          #   return columns_without_enum  # 2. XxxDimension.columns_without_enum
          # end
          return columns_without_enum if excluded_klasses.include?(superclass)
          @columns ||= begin
            columns = columns_without_enum
            enum_columns = superclass.columns.select{|column| column.enum?}
            enum_columns.each do |enum_column|
              columns.each_with_index{|common_column,index|
                columns[index] = enum_column if enum_column.name == common_column.name
              }
            end
            columns
          rescue
            columns_without_enum
          end
        end
        private
          def display_value(field, value, text_options = {})
            return text_options[value] if text_options.has_key?(value)
            value = (Numeric === value) ? value.to_s : value.to_s.underscore
            I18n.t "#{self.name.underscore}.#{field}.#{value}", :raise=>true
          rescue
            value.to_s.camelize
          end
      end
      
      module EnumAware
        def enum?
          respond_to?(:enum_options)
        end
      end
    end

  end
end
