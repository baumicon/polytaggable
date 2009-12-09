#$: << File.join(File.dirname(__FILE__), '..', 'lib')
require 'rubygems'
require 'activerecord'
require 'lib/polytaggable.rb'
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Schema.define(:version => 1) do
  create_table :assets do |t|
    t.string   :name
  end
  create_table :users do |t|
    t.string :email
  end
  create_table :taggings do |t|
    t.string    :taggable_type
    t.datetime  :created_at
    t.integer   :tag_id, :null => true
    t.integer   :taggable_id, :null => true
  end

  create_table :tags do |t|
    t.string  :name
    t.string  :name_stem
    t.integer :taggings_count, :default => 0
    t.string  :tagger_type
    t.string  :user_friendly_name
    t.integer :tagger_id, :null => true
  end
  
end

class Asset < ActiveRecord::Base
  acts_as_polytaggable(:tagger => "user")
end
class Tag < ActiveRecord::Base
  belongs_to :user, :dependent => :destroy
  belongs_to :tagger, :polymorphic => true
  has_many :taggings, :dependent => :destroy
  has_many :assets, :through => :taggings, :source => :taggable, :source_type => "Asset"
end
class Tagging < ActiveRecord::Base
  belongs_to :tag, :counter_cache => true
  belongs_to :taggable, :polymorphic => true
  # Turn this off only as a user preference. 
  def after_destroy
    if tag.taggings.count.zero?
      tag.destroy
    end
  end
  
end
class User < ActiveRecord::Base
  has_many :tags, :as => :tagger, :dependent => :destroy, :order => "user_friendly_name ASC"
end