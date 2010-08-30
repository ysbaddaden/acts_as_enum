ActsAsEnum
==========

This acts_as extension for ActiveRecord 3.0 provides the capabilities for
mapping a column to symbols, while adding useful scopes as well as translations.

Column may be an integer or a string. It may be something else, but it's untested.

Example
=======

    create_table :users do |t|
      t.column :sex, :integer
    end
    
    class User < ActiveRecord::Base
      acts_as_enum :gender, {
        :male => 1,
        :female => 2
      }
      validates_as_enum :gender, :allow_nil => true
    end

You will generally want integers, but strings are possible too:

    create_table :users do |t|
      t.column :sex, :string
    end
    
    class User < ActiveRecord::Base
      acts_as_enum :gender, {
        :male => 'man',
        :female => 'woman'
      }
    end

You may also add a **suffix** to the column name. In that case you won't be
using the `users.sex` column but the `users.sex_cd` column (for instance).
You will then be able to interact with `User.sex` (as symbols) and
`User.sex_enum` (as integers):

    create_table :users do |t|
      t.column :sex_cd, :integer
    end
    
    class User < ActiveRecord::Base
      acts_as_enum :gender, {
        :male => 1,
        :female => 2
      }, :suffix => 'enum'
    end

Generated instance methods

    user.gender = :male     # => :male
    user.gender = 'female'  # => :female
    user.gender = 1         # => :male
    
    user.male?
    user.female?
    
    user.gender         # => :male
    user.human_gender   # => "Male"

Generated class methods

    User.genders        # => {:male => 1, :female => 2}
    User.human_genders  # => [["Female", :female], ["Male", :male]]

Generated scopes

    User.males          # => where(:gender => 0)
    User.females        # => where(:gender => 1)

Views

    <%= form_for user do |f| %>
      <%= f.select :gender, User.human_genders %>
    <% end %>

I18n
====

It uses the following scope:
`"activerecord.enums.#{model_name.underscore}.genders"`. If not present
it fallbacks to `humanize`.

Example:

    fr:
      activerecord:
        enums:
          user:
            genders:
              male: Homme
              female: Femme

TODO
====

ActsAsEnum should not be tied to ActiveRecord but usable by any ActiveModel
compliant ruby Object.

