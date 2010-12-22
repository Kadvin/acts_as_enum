require 'enum'
ActiveRecord::Base.send :include, ActiveModel::Acts::Enum

require 'active_record_helper'