require 'test/unit'
require 'rubygems'
require 'logger'

gem 'activerecord', '>= 3.0.0'
require 'active_record'

gem 'i18n', '>= 0.4.1'
require 'i18n'

if RUBY_VERSION >= "1.9"
  require_relative "../init"
else
  require "#{File.dirname(__FILE__)}/../init"
end

ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + '/test.log')
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

ActiveRecord::Schema.define do
  create_table :users do |t|
    t.column :sex, :integer
  end
  
  create_table :admins do |t|
    t.column :sex_cd, :string
  end
end

class User < ActiveRecord::Base
  acts_as_enum :sex, {
    :male => 0,
    :female => 1
  }
  validates_enum :sex, :allow_nil => true
end

class Admin < ActiveRecord::Base
  acts_as_enum :sex, {
    :male => 'man',
    :female => 'woman'
  }, :suffix => 'cd'
  validates_enum :sex, :allow_nil => true
end

I18n.backend.store_translations(:fr, {
  :activerecord => {
    :enums => {
      :user => {
        :sex => {
          :male   => {:one => "homme", :other => "hommes"},
          :female => {:one => "femme", :other => "femmes"}
        }
      },
      :admin => {
        :sex => {
          :male   => {:one => "homme", :other => "hommes"},
          :female => {:one => "femme", :other => "femmes"}
        }
      }
    }
  }
})

class UserEnumTest < Test::Unit::TestCase
  def class_name
    User
  end

  def setup
    (1..5).each do |counter|
      sex = (counter % 2 == 0) ? :male : :female
      class_name.new do |u|
        u.id = counter
        u.sex = sex
        u.save!
      end
    end
  end

  def teardown
    class_name.delete_all
  end

  def test_generated_methods
    assert class_name.respond_to? :sexes
    assert class_name.respond_to? :males
    assert class_name.respond_to? :females
    
    assert class_name.new.respond_to? :sex
    assert class_name.new.respond_to? :sex=
    
    assert class_name.new.respond_to? :male?
    assert class_name.new.respond_to? :female?
    
    assert class_name.respond_to? :human_sexes
    assert class_name.new.respond_to? :human_sex
  end

  def test_get_symbol
    assert_equal :female, class_name.find(1).sex
    assert_equal :male,   class_name.find(2).sex
    assert_equal :female, class_name.find(5).sex
  end

  def test_set_symbol
    u = class_name.find(3)
    u.sex = :male
    assert_equal :male, u.sex
    
    u = class_name.find(1)
    u.sex = :female
    assert_equal :female, u.sex
  end

  def test_unknown_symbol
    u = class_name.find(3)
    
    u.sex = :alien
    assert_equal :alien, u.sex
    
    u.sex = nil
    assert_nil u.sex
  end

  def test_set_string
    u = class_name.find(1)
    u.sex = 'male'
    assert_equal :male, u.sex
    
    u = class_name.find(5)
    u.sex = 'female'
    assert_equal :female, u.sex
  end

  def test_set_empty_string
    u = class_name.new(:sex => "")
    assert_nil u.sex

    u = class_name.find(1)
    u.sex = " "
    assert_nil u.sex
  end

  def test_bool_methods
    assert class_name.find(1).female?
    assert !class_name.find(1).male?
    assert class_name.find(2).male?
  end

  def test_scopes
    assert_equal [2, 4], class_name.males.collect(&:id)
    assert_equal [1, 3, 5], class_name.females.collect(&:id)
  end

  def test_human
    assert_equal 'Male', class_name.human_sex(:male)
    assert_equal 'Female', class_name.human_sex(:female)
    
    assert_equal 'Female', class_name.find(1).human_sex
    assert_equal 'Male', class_name.find(2).human_sex
    
    assert_equal [['Female', :female], ['Male', :male]], class_name.human_sexes
    assert_equal [['Male', :male], ['Female', :female]], class_name.human_sexes(:sort => false)
  end

  def test_human_with_count
    assert_equal 'Male', class_name.human_sex(:male, :count => 1)
    assert_equal 'Males', class_name.human_sex(:male, :count => 2)
    
    assert_equal [['Female', :female], ['Male', :male]], class_name.human_sexes(:count => 1)
    assert_equal [['Males', :male], ['Females', :female]], class_name.human_sexes(:count => 2, :sort => false)
  end

  def test_human_pluralization
    assert_equal 'Males', class_name.human_sex(:male, :plural => true)
    assert_equal 'Females', class_name.human_sex(:female, :plural => true)
    
    assert_equal [['Females', :female], ['Males', :male]], class_name.human_sexes(:plural => true)
    assert_equal [['Males', :male], ['Females', :female]], class_name.human_sexes(:plural => true, :sort => false)
  end

  def test_i18n
    I18n.with_locale :fr do
      assert_equal 'homme', class_name.human_sex(:male)
      assert_equal 'femme', class_name.human_sex(:female)
      
      assert_equal 'hommes', class_name.human_sex(:male, :plural => true)
      assert_equal 'femmes', class_name.human_sex(:female, :plural => true)
      
      assert_equal 'homme', class_name.human_sex(:male, :count => 1)
      assert_equal 'femme', class_name.human_sex(:female, :count => 1)
      
      assert_equal 'hommes', class_name.human_sex(:male, :count => 2)
      assert_equal 'femmes', class_name.human_sex(:female, :count => 2)
    end
  end

  def test_validation
    assert class_name.create(:sex => :female).valid?, "sex => :female"
    assert class_name.create(:sex => :male).valid?, "sex => :male"
    
    assert class_name.create(:sex => nil).valid?, "nil should be allowed"
    
    assert !class_name.create(:sex => :alien).valid?, ":alien shouldn't be allowed"
    assert !class_name.create(:sex => 'martian').valid?, "'martian' shouldn't be allowed"
  end

  def test_where_enum
    assert_equal 2, class_name.where_sex(:male).count
    assert_equal 2, class_name.where_sex('male').count
    assert_equal 3, class_name.where_sex(:female).count
    assert_equal 3, class_name.where_sex('female').count
    
    assert_equal 5, class_name.where_sex([:female, :male]).count
    assert_equal 5, class_name.where_sex(['female', :male]).count
  end
end

class AdminEnumTest < UserEnumTest
  def class_name
    Admin
  end
end
