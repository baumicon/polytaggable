Polytaggable
==============================================================================
Tagging implementation where you can specify the tagger through a polymorphic 
association.

Usage
------------------------------------------------------------------------------
```ruby
class User < ActiveRecord::Base
  acts_as_polytaggable(:tagger => "account")
end
```

```ruby
class Account < ActiveRecord::Base
  has_many :tags, :as => :tagger, :dependent => :destroy, :order => "user_friendly_name ASC"
end
```

**Finding users with specific tag**
```ruby
User.tagged_with("awesome")
```

**Creating a new Object**
```ruby
User.create!(:tag_attributes => "awesome anothertag tag3")
```

Migration
------------------------------------------------------------------------------

```ruby
class AddPolytaggable < ActiveRecord::Migration
  def self.up
    create_table "taggings", :force => true do |t|
      t.string   "taggable_type"
      t.datetime "created_at"
      t.integer   "tag_id", :null => true
      t.integer   "taggable_id", :null => true
    end
    
    create_table "tags", :force => true do |t|
      t.string  "name"
      t.string  "name_stem"
      t.integer "taggings_count",                   :default => 0
      t.string  "tagger_type"
      t.string  "user_friendly_name"
      t.integer  "tagger_id", :null => true
    end
    add_index "taggings", ["tag_id", "taggable_id", "taggable_type"], :name => "by_tag_and_poly"
    add_index "taggings", ["taggable_id"], :name => "by_taggable_id"
    
  end

  def self.down
    drop_table :tags
    drop_table :taggings
  end
end
```
