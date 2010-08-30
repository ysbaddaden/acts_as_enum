ActsAsEnum
==========

This acts_as extension for ActiveRecord 3.0 provides the capabilities for
mapping an integer column to symbols, while adding useful scopes as well as
translations.

Example
=======

    class User < ActiveRecord::Base
      acts_as_enum :gender, {
        :male => 1,
        :female => 2
      }
      validates_as_enum :gender, :allow_nil => true
    end

Generated instance methods

    user.gender = :male     # => :male
    user.gender = 1         # => :male
    user.gender = 'female'  # => :female
  
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

It should not be tied to ActiveRecord but usable by any ActiveModel compliant
ruby Object.

