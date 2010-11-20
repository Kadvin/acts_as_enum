require 'enum'
ActiveRecord::Base.send :include, ActiveRecord::Acts::Enum
# 所有的Column都支持判断是否是enum的方法
ActiveRecord::ConnectionAdapters::Column.send(:include, ActiveRecord::Acts::Enum::EnumAware)

require 'active_record_helper'