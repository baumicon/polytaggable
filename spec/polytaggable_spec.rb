require 'spec_helper'
describe "Asset" do
  def valid_attributes(args = {})
    {
      "name"            => "Asset",
      "tag_attributes"  => "room category type"
    }.merge(args)
  end
  before(:each) do
    @user = User.create!(:email => "fake@user.com")
    @asset = @user.assets.build
    @tag = "George Washington's, '1-F'"
  end
  
  # Play with taglist
  it "should create user friendly name" do
    @asset.attributes = valid_attributes(:tag_attributes => "\"#{@tag}\"")
    @asset.save!
    
    @asset.tags.first.user_friendly_name.should eql(@tag)
  end
  it "should create normalized name" do
    @asset.attributes = valid_attributes(:tag_attributes => "\"#{@tag}\"")
    @asset.save!
    
    @asset.tags.first.name.should eql(@tag.url_friendly)
  end
  it "should delineate by spaces" do
    @asset.attributes = valid_attributes(:tag_attributes => "tater tot")
    @asset.save!
    @asset.tags.length.should eql(2)
  end
  it "should delineate by double quotes" do
    @asset.attributes = valid_attributes(:tag_attributes => "\"tater tot\" \"special tag\"")
    @asset.save!
    
    @asset.tags.length.should eql(2)
  end
  it "should create multiple types of tags" do
    @asset.attributes = valid_attributes(:tag_attributes => "\"tater tot\" watermelon gum carrie")
    @asset.save!
    
    @asset.tags.length.should eql(4)      
  end
  it "should remove whitespace" do 
    @asset.attributes = valid_attributes(:tag_attributes => "\"    tater tot        \"       watermelon")
    @asset.save!
    
    @asset.tags.length.should eql(2)      
    @asset.tags.last.name.should eql("watermelon".url_friendly)
    @asset.tags.first.name.should eql("tater tot".url_friendly)
  end
  it "should remove duplicate tags" do
    @asset.attributes = valid_attributes(:tag_attributes => "\"#{@tag}\" \"#{@tag}\"")
    @asset.save!
    
    @asset.tags.length.should eql(1)
  end
  
  it "should not create blank tag" do
    @asset.attributes = valid_attributes(:tag_attributes => " ")
    @asset.save!
    
    @asset.tags.length.should eql(0)
  end
  it "should not delineate by commas" do
    @asset.attributes = valid_attributes(:tag_attributes => "tater,tot")
    @asset.save!
    
    @asset.tags.length.should eql(1)
  end
end
