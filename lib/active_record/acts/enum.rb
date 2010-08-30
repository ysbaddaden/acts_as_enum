module ActiveRecord
  module Acts #:nodoc:
    module Enum #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_enum(column_name, enum, options = {})
          plural = ActiveSupport::Inflector.pluralize(column_name.to_s)
          
          methods = []
          scopes  = []
          
          enum.each do |sym, int|
            methods.push("def #{sym}?() read_attribute(:#{column_name}) == #{int} end")
            scopes.push("scope :#{ActiveSupport::Inflector.pluralize(sym.to_s)}, where(:#{column_name} => #{int})")
          end
          
          class_eval <<-EOV
            def self.#{plural}
              #{enum.inspect}
            end
            
            def self.human_#{plural}
              hsh = #{plural}.map do |sym,int|
                [enum_human_attribute_name(:#{column_name}, sym), sym]
              end
              hsh.sort { |a,b| a[0] <=> b[0] }
            end
            
            def human_#{column_name}
              self.class.enum_human_attribute_name(:#{column_name}, #{column_name})
            end
            
            def #{column_name}
              value = self.class.#{plural}.invert[read_attribute(:#{column_name})]
              return @#{column_name}_enum_sym if value.nil?
              value
            end
            
            def #{column_name}=(value)
              unless value.kind_of?(Fixnum) || value.to_i.to_s == value.to_s
                if value.respond_to?(:to_sym)
                  value = value.to_sym
                  value = self.class.#{plural}[value] unless self.class.#{plural}[value].nil?
                end
              end
              
              @#{column_name}_enum_sym = value
              write_attribute(:#{column_name}, value)
            end
            
            #{methods.join("\n")}
            #{scopes.join("\n")}
          EOV
        end
        
        def enum_human_attribute_name(column_name, value)
          I18n.t(value, :scope => [:activerecord, :enums, model_name.underscore, column_name.to_sym],
            :default => lambda { |key, options| ActiveSupport::Inflector.humanize(value) })
        end
        
        def validates_as_enum(*args)
          validates_each *args do |record, attr, value|
            plural = ActiveSupport::Inflector.pluralize(attr.to_s)
            keys = send(plural).keys
            record.errors.add(attr, :invalid_enum) unless keys.include?(value)
          end
        end
      end
    end
  end
end
