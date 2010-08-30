module ActiveRecord
  module Acts #:nodoc:
    module Enum #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_enum(column_name, enum, options = {})
          column_name = column_name.to_s
          real_column_name = column_name
          real_column_name += '_' + options[:suffix] if options[:suffix]
          
          plural = ActiveSupport::Inflector.pluralize(column_name)
          
          methods = []
          scopes  = []
          
          enum.each do |sym, int|
            methods.push("def #{sym}?() read_attribute(:#{real_column_name}) == #{int} end")
            scopes.push("scope :#{ActiveSupport::Inflector.pluralize(sym.to_s)}, where(:#{real_column_name} => #{int})")
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
              value = self.class.#{plural}.invert[read_attribute(:#{real_column_name})]
              return @#{column_name}_enum if value.nil?
              value
            end
            
            def #{column_name}=(value)
              unless value.kind_of?(Fixnum) || (value.respond_to?(:to_i) && value.to_i.to_s == value.to_s)
                if value.respond_to?(:to_sym)
                  value = value.to_sym
                  value = self.class.#{plural}[value] unless self.class.#{plural}[value].nil?
                end
              end
              
              # does enum exists?
              if self.class.#{plural}.keys.include?(value) || self.class.#{plural}.values.include?(value)
                write_attribute(:#{real_column_name}, value)
              else
                @#{column_name}_enum = value
                write_attribute(:#{real_column_name}, -1)
              end
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
