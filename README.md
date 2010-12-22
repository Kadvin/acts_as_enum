ActsAsEnum
==========

With this gem/plugin, you can constraint your model's field value in several limited values.

Even more, this limited value can be:
* Declared in migration
* Titlized in model DSL
* Titlized in model i18n resources

Example
=======

  def self.up
    create_table "person", :force => true do |t|
      t.string   "name"
      t.string   "gender"
      t.integer  "rank",      :null => false
      t.timestamps
    end
  end

  class Person < ActiveRecord::Base
    # the person's gender only be male or female
    acts_as_enum :gender, :male, :female
  
    # the person was ranked in 1-5 level
    acts_as_enum :rank, 1..5, 
                 :allow_nil => false
                 :alias   => %w[bad common good excellent awsome]
                 :label   => %w[Badone Common Goodman Excellent Awsome]
  end

Generated class methods:

  Person.genders             # => [:male, :female]
  Person.gender_aliases      # => %w[male female]
  Person.gender_labels       # => %w[Male Female]
  Person.gender_options # => [["Female", :female], ["Male", :male]]
  
  Person.ranks             # => [1,2,3,4,5]
  Person.rank_aliases      # => %w[bad common good excellent awsome]
  Person.rank_labels       # => %w[Badone Common Goodman Excellent Awsome]
  Person.rank_options # => [['Badone', 1], ['Common', 2], ['Goodman', 3], ['Excellent', 4], ['Awsome', 5]]

Generated instance methods:

  person = Person.new(:gender=>:male, :rank => 5)
  person.male_gender?    # => true
  person.female_gender?  # => false
  
  person.rank_label      # => 'Awsome'
  person.rank_alias      # => 'awsome'
  person.bad_rank?       # => false
  person.common_rank?    # => false
  person.good_rank?      # => false
  person.excellent_rank? # => false
  person.awsome_rank?    # => true
 
Generated Scopes:
  Person.male_genders    # where(:gender => :male)
  Person.female_genders  # where(:gender => :female)
  Person.bad_ranks       # where(:rank => 1)
  Person.common_ranks    # where(:rank => 2)
  Person.good_ranks      # where(:rank => 3)
  Person.excellent_ranks # where(:rank => 4)
  Person.awsome_ranks    # where(:rank => 5)

Views

<%= form_for person do |f| %>
  <%= f.select :gender, Person.gender_enum_options %>
<% end %>
  
I18n
====

  It uses the following scope: activerecord.enums.#{model}.#{column}.#{enum_value}

Example:

en:
  activerecord:
    enums:
      user:
        gender:
          male: Homme
          female: Femme

Todo:
the Code is not aligned with the README now

Copyright (c) 2009 Kadvin, released under the MIT license
