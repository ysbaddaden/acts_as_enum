module ActiveRecord
  module Acts #:nodoc:
    module Enum #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_enum(column_name, enum, options = {})
          real_column_name = column_name.to_s
          real_column_name += '_' + options[:suffix] if options[:suffix]
          
          plural = ActiveSupport::Inflector.pluralize(column_name.to_s)
          
          i18n_scope = options[:i18n_scope]
          i18n_scope ||= [:activerecord, :enums, model_name.underscore, column_name]
          
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
            
            def #{column_name}
              value = self.class.#{plural}.invert[read_attribute(:#{real_column_name})]
              return @invalid_#{column_name}_enum if value.nil?
              value
            end
            
            def #{column_name}=(value)
              value = nil if value.blank?
              
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
            
            def self.#{column_name}_i18n_scope
              #{i18n_scope.inspect}
            end
            
            def self.where_#{column_name}(value)
              where_enum_column(:#{real_column_name}, value, :#{plural})
            end
            
            #{methods.join("\n")}
            #{scopes.join("\n")}
            
            def self.human_#{plural}(options = {})
              sort = options.delete(:sort)
              
              hsh = #{plural}.keys.map do |sym|
                [enum_human_attribute_name(:#{column_name}, sym, options), sym]
              end
              
              unless sort == false
                hsh.sort! do |a, b|
                  ActiveSupport::Inflector.transliterate(a[0]) <=> ActiveSupport::Inflector.transliterate(b[0])
                end
              end
              
              hsh
            end
            
            def self.human_#{column_name}(key, options = {})
              enum_human_attribute_name(:#{column_name}, key, options)
            end
            
            def human_#{column_name}(options = {})
              self.class.enum_human_attribute_name(:#{column_name}, #{column_name}, options)
            end
          EOV
        end
        
        def enum_human_attribute_name(column_name, key, options = {})
          options = options.dup
          plural = options.delete(:plural)
          options[:count] = plural ? 2 : 1 unless options[:count]
          options[:scope] = send(:"#{column_name}_i18n_scope")
          options[:default] = lambda { |key, options|
            trans = ActiveSupport::Inflector.humanize(key)
            trans = ActiveSupport::Inflector.pluralize(trans) unless options[:count] == 1
            trans
          }
          I18n.t(key, options)
        end

        def validates_enum(*args)
          validates_each *args do |record, attr, value|
            plural = ActiveSupport::Inflector.pluralize(attr.to_s)
            keys = send(plural).keys
            record.errors.add(attr, :invalid_enum) unless keys.include?(value)
          end
        end

        def where_enum_column(column_name, value, collection_name) # :nodoc:
          collection_name = collection_name.to_sym
          
          if value.kind_of?(Array)
            value.map! { |v| send(collection_name)[v.to_sym] }
          else
            value = send(collection_name)[value.to_sym]
          end
          
          where(column_name => value)
        end
      end
    end
  end
end
