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
          
          enum.each do |sym, value|
            methods.push("def #{sym}?() read_attribute(:#{real_column_name}) == #{value.inspect} end")
            scopes.push("scope :#{ActiveSupport::Inflector.pluralize(sym.to_s)}, where(:#{real_column_name} => #{value.inspect})")
          end
          
          class_eval <<-EOV
            def self.#{plural}
              #{enum.inspect}
            end
            
            def self.human_#{plural}(options = {})
              options[:sort] = true unless options[:sort] == false
              
              hsh = #{plural}.keys.map do |sym|
                [enum_human_attribute_name(:#{column_name}, sym), sym]
              end
              
              return hsh.sort { |a,b| a[0] <=> b[0] } if options[:sort]
              hsh
            end
            
            def self.human_#{column_name}(key)
              enum_human_attribute_name(:#{column_name}, key)
            end
            
            def human_#{column_name}
              self.class.enum_human_attribute_name(:#{column_name}, #{column_name})
            end
            
            def #{column_name}
              value = self.class.#{plural}.invert[read_attribute(:#{real_column_name})]
              return @invalid_#{column_name}_enum if value.nil?
              value
            end
            
            def #{column_name}=(value)
              unless value.nil?
                if self.class.#{plural}[value.to_sym]
                  @invalid_#{column_name}_enum = nil
                  value = self.class.#{plural}[value.to_sym]
                else
                  @invalid_#{column_name}_enum = value
                  value = nil
                end
              else
                @invalid_#{column_name}_enum = nil
              end
              
              write_attribute(:#{real_column_name}, value)
            end
            
            #{methods.join("\n")}
            #{scopes.join("\n")}
          EOV
        end
        
        # IMPROVE: handle pluralization (using a :count option?).
        # FiXME: sorting should be done with transliterated strings.
        def enum_human_attribute_name(column_name, key)
          I18n.t(key, :scope => [:activerecord, :enums, model_name.underscore, column_name.to_sym],
            :default => lambda { |key, options| ActiveSupport::Inflector.humanize(key) })
        end
        
        def validates_enum(*args)
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
