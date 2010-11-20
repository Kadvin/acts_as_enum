
module ActionView
  module Helpers
    module FormHelper
      # helper to create a select drop down list for the enumerated values. This
      # is the default input tag.
      def enum_select(object_name, method, options = {})
        InstanceTag.new(object_name, method, self, options.delete(:object)).to_enum_select_tag(options)
      end

      # Creates a set of radio buttons for all the enumerated values.
      def enum_radio(object_name, method, options = {})
        InstanceTag.new(object_name, method, self, options.delete(:object)).to_enum_radio_tag(options)        
      end
    end

    class FormBuilder
      def enum_select(method, options = {})
        @template.enum_select(@object_name, method, options)
      end

      def enum_radio(method, options = {})
        @template.enum_radio(@object_name, method, options)
      end
    end
    
    class InstanceTag #:nodoc:
      alias __to_tag_enum to_tag

      # 拿到列的信息
      def column
        object.send(:column_for_attribute, @method_name)
      end
      # Add the enumeration tag support. Defaults using the select tag to
      # display the options.
      def to_tag(options = {})
        if column.enum?
          to_enum_select_tag(options)
        else
          __to_tag_enum(options)
        end
      end

      # Create a select tag and one option for each of the
      # enumeration values.
      def to_enum_select_tag(options = {})
        # Remove when we no longer support 1.1.
        begin
          v = value(object)
        rescue ArgumentError
          v = value
        end
        # 得到二维数组enum options
        enum_options = enum_options_from(options) || enum_options_from_model
        raise ArgumentError, "Can't find enum options" unless enum_options
        # 根据options指定的exclude过滤
        enum_options.reject!{|k,_v| options[:exclude].member?(k) } if options[:exclude]
        # 根据options指定的only过滤
        enum_options.reject!{|k,_v| !options[:only].member?(k) } if options[:only]
        add_default_name_and_id(options)
        tag_text = "<select"
        tag_text << tag_options(options)
        tag_text << ">"
        if prompt = options.delete(:include_blank) || options.delete(:prompt)
          tag_text << "<option value=\"\">#{prompt}</option>\n"
        end
        enum_options.each do |text, enum|
          tag_text << "<option value=\"#{enum}\""
          tag_text << ' selected="selected"' if v and v.to_s == enum.to_s
          tag_text << ">#{text}</option>"
        end
        tag_text << "</select>"
      end

      # Creates a set of radio buttons and labels.
      def to_enum_radio_tag(options = {})
        # Remove when we no longer support 1.1.
        begin
          v = value(object)
        rescue ArgumentError
          v = value
        end
        add_default_name_and_id(options)
        # 得到二维数组enum options
        enum_options = enum_options_from(options) || enum_options_from_model
        raise ArgumentError, "Can't find enum options" unless enum_options
        # 根据options指定的exclude过滤
        enum_options.reject!{|_t,value| options[:exclude].member?(value) } if options[:exclude]
        # 根据options指定的only过滤
        enum_options.reject!{|_t,value| !options[:only].member?(value) } if options[:only]
        tag_text = []
        template = options.dup
        template.delete('checked')
        
        enum_options.each do |text, enum|
          opts = template.dup
          opts['checked'] = 'checked' if v and v.to_s == enum.to_s
          opts['id'] = "#{opts['id']}_#{enum}"
          output = "<label class='enum' for=#{opts['id']}>#{text}: </label>"
          output << to_radio_button_tag(enum, opts)
          tag_text << output
        end
        tag_text.join("<span style='display:inline;padding:0 10px'> </span>")
      end

      # 根据options Hash里面的配置项
      def enum_options_from( options )
        options.delete(:enum_options)
      end

      # 根据模型获取Enum的选项
      def enum_options_from_model
        column.enum? && column.enum_options
      end

    end
  end
end
