$:.unshift "#{File.dirname(__FILE__)}/lib"
require 'active_record/acts/enum'
ActiveRecord::Base.class_eval { include ActiveRecord::Acts::Enum }
