require 'test/unit'
require 'rubygems'

gem 'activerecord', '>= 3.0.0'
require 'active_record'

gem 'i18n', '>= 0.4.1'
require 'i18n'

require "#{File.dirname(__FILE__)}/../init"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

def setup_db
  ActiveRecord::Schema.define do
    create_table :users do |t|
      t.column :sex, :integer
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class User < ActiveRecord::Base
  acts_as_enum :sex, {
    :male => 0,
    :female => 1
  }
  validates_as_enum :sex, :allow_nil => true
end

class EnumTest < Test::Unit::TestCase
  def setup
    setup_db
    (1..5).each { |counter| User.create! :sex => counter % 2 }
  end

  def teardown
    teardown_db
  end

  def test_generated_methods
    assert User.respond_to? :sexes
    assert User.respond_to? :males
    assert User.respond_to? :females
    
    assert User.new.respond_to? :sex
    assert User.new.respond_to? :sex=
    
    assert User.new.respond_to? :male?
    assert User.new.respond_to? :female?
    
    assert User.respond_to? :human_sexes
    assert User.new.respond_to? :human_sex
  end

  def test_get_symbol
    assert_equal :female, User.find(1).sex
    assert_equal :male,   User.find(2).sex
    assert_equal :female, User.find(5).sex
  end

  def test_set_symbol
    u = User.find(3)
    u.sex = :male
    assert_equal :male, u.sex
    
    u = User.find(1)
    u.sex = :female
    assert_equal :female, u.sex
  end

  def test_unknown_symbol
    u = User.find(3)
    u.sex = :alien
    assert_equal :alien, u.sex
  end

  def test_set_string
    u = User.find(1)
    u.sex = 'male'
    assert_equal :male, u.sex
    
    u = User.find(5)
    u.sex = 'female'
    assert_equal :female, u.sex
  end

  def test_set_integer
    u = User.find(1)
    u.sex = 0
    assert_equal :male, u.sex
    
    u = User.find(3)
    u.sex = 1
    assert_equal :female, u.sex
  end

  def test_bool_methods
    assert User.find(1).female?
    assert !User.find(1).male?
    assert User.find(2).male?
  end

  def test_scopes
    assert_equal [2, 4], User.males.collect(&:id)
    assert_equal [1, 3, 5], User.females.collect(&:id)
  end

  def test_human
    assert_equal 'Female', User.find(1).human_sex
    assert_equal 'Male', User.find(2).human_sex
    assert_equal [['Female', :female], ['Male', :male]], User.human_sexes
  end

  # TODO: How to test with i18n translations?
#  def test_translations
#    assert_equal 'Man', User.find(1).human_sex
#    assert_equal 'Woman', User.find(2).human_sex
#    assert_equal [['Man', :male], ['Woman', :female]], User.human_sexes
#  end

  def test_validation
    assert User.create(:sex => :female).valid?, "sex => :female"
    assert User.create(:sex => :male).valid?, "sex => :male"
    
    assert User.create(:sex => nil).valid?, "nil should be allowed"
    
    assert !User.create(:sex => :alien).valid?, ":alien shouldn't be allowed"
    assert !User.create(:sex => 'martian').valid?, "'martian' shouldn't be allowed"
  end
end
