module Polytaggable
  require 'polytaggable/string_extensions'
  #puts "Polytaggable initialized"
  def self.included(base) 
    base.extend ActMethods 
  end 
  module ActMethods 
    def acts_as_polytaggable(*args)
      options = args.extract_options!
      has_many :taggings, :as => :taggable, :include => :tag
      has_many :tags, :through => :taggings, :dependent => :destroy
      before_save :set_tags
      unless included_modules.include? InstanceMethods 
        class_inheritable_accessor :options
        extend ClassMethods 
        include InstanceMethods 
      end 
      self.options = options
      
    end 
  end 
  module ClassMethods
    def helpers
      ActionController::Base.helpers
    end
    
    # Pass either a tag, string, or an array of strings or tags.
    # 
    # Options:
    #   :exclude - Find models that are not tagged with the given tags
    #   :match_all - Find models that match all of the given tags, not just one
    #   :conditions - A piece of SQL conditions to add to the query
    def find_tagged_with(*args)
      options = find_options_for_find_tagged_with(*args)
      options.blank? ? [] : find(:all, options)
    end
    def find_options_for_find_tagged_with(finder_tags, options = {})
      #tags = tags.is_a?(Array) ? TagList.new(tags.map(&:to_s)) : TagList.from(tags)
      # TODO: revise this to process the tags better.
      search_tags = finder_tags.split(" ")
      return {} if search_tags.empty?

      conditions = []
      conditions << sanitize_sql(options.delete(:conditions)) if options[:conditions]
      
      groups = []
      groups << sanitize_sql(options.delete(:group)) if options[:group]
      
      unless (on = options.delete(:on)).nil?
        conditions << sanitize_sql(["context = ?",on.to_s])
      end

      taggings_alias, tags_alias = "#{table_name}_taggings", "#{table_name}_tags"

      if options.delete(:exclude)
        tags_conditions = search_tags.map { |t| sanitize_sql(["#{Tag.table_name}.name LIKE ?", t]) }.join(" OR ")
        conditions << sanitize_sql(["#{table_name}.id NOT IN (SELECT #{Tagging.table_name}.taggable_id FROM #{Tagging.table_name} LEFT OUTER JOIN #{Tag.table_name} ON #{Tagging.table_name}.tag_id = #{Tag.table_name}.id WHERE (#{tags_conditions}) AND #{Tagging.table_name}.taggable_type = #{quote_value(base_class.name)})", search_tags])
      else
        # Has to match all tags
        conditions << search_tags.map { |t| sanitize_sql(["#{tags_alias}.name LIKE ?", t]) }.join(" OR ")
        if options.delete(:match_all)
          groups << "#{taggings_alias}.taggable_id HAVING COUNT(#{taggings_alias}.taggable_id) = #{search_tags.size}"
        end
      end
      if groups.blank?
        { :select => "DISTINCT #{table_name}.*",
          :joins => "LEFT OUTER JOIN #{Tagging.table_name} #{taggings_alias} ON #{taggings_alias}.taggable_id = #{table_name}.#{primary_key} AND #{taggings_alias}.taggable_type = #{quote_value(base_class.name)} " +
                    "LEFT OUTER JOIN #{Tag.table_name} #{tags_alias} ON #{tags_alias}.id = #{taggings_alias}.tag_id",
          :conditions => conditions.join(" AND ")
        }.update(options)
      else
        { :select => "DISTINCT #{table_name}.*",
          :joins => "LEFT OUTER JOIN #{Tagging.table_name} #{taggings_alias} ON #{taggings_alias}.taggable_id = #{table_name}.#{primary_key} AND #{taggings_alias}.taggable_type = #{quote_value(base_class.name)} " +
                    "LEFT OUTER JOIN #{Tag.table_name} #{tags_alias} ON #{tags_alias}.id = #{taggings_alias}.tag_id",
          :conditions => conditions.join(" AND "),
          :group      => groups.join(", ")
        }.update(options)
      end
    end
    
  end 
  module InstanceMethods
    def tag_attributes
      @tag_attributes ||= tag_list
    end
    def tag_attributes=(val)
      @tag_attributes = val
    end
    def set_tags
      self.tag_list = {:tags => tag_attributes.blank? ? "" : tag_attributes, :tagger_id => send("#{options[:tagger]}_id"), :tagger_type => "#{options[:tagger].capitalize}"}
    end
    def tag_list
      all_tags = self.tags

      # Remove smart tags from standard tags for the tag list. Should be a user preference.
      # TODO: This is causing the smart tags to be duplicated in the taggings table. Need a better solution.
      #all_tags.reject!{|a| 
        #logger.debug("******* TAG DEBUG: \n  tag: #{a.name}   smart: #{a.is_smart_tag?}")
        #a.is_smart_tag? 
      #}

      self.tags.collect{|t| (t.user_friendly_name.include? " ") ? "\"#{t.user_friendly_name}\"" : t.user_friendly_name }.join(" ")
    end
    def tag_list=(attributes)
      
      old_tags = self.tags

      # scan for all tags even in quotes
      tag_array = attributes[:tags].scan(/\"([^\"]*)\"|(\S+)/)
      tag_array.flatten!

      # Remove duplicates
      tag_array.uniq!
      # Remove blanks
      tag_array.reject!(&:blank?)
      # Remove whitespace
      tag_array.map!(&:strip)
      #find or create tag
      tag_array.each do |tag_from_array|
        new_tag_string = tag_from_array.url_friendly
        #debugger
        self.class.transaction do
          # Tags also get their stem extended string view config/initializers/stemmable.rb
          # Stems prevent duplicates with the same word meaning but different spellings ie: marker markers markings marked
          # TODO: Add spell checking?
          new_tag = Tag.find(:first, :conditions => {:name_stem => new_tag_string.stem, :tagger_id => attributes[:tagger_id], :tagger_type => attributes[:tagger_type]})


          if new_tag.nil?
            # new_tag_string is normalized making it all lowercase and removing special characters.
            new_tag = Tag.create(:name => new_tag_string, :user_friendly_name => tag_from_array.remove_smart_tag, :name_stem => new_tag_string.stem, :tagger_id => attributes[:tagger_id], :tagger_type => attributes[:tagger_type])
          end

          tag_exists = old_tags.detect{|old_tag| old_tag.name_stem == new_tag.name_stem }

          if tag_exists.blank?
            old_tags << new_tag
          end
          

        end
        dead_tags = old_tags.reject { |old_tag| tag_array.detect{|tag| tag.url_friendly == old_tag.name } }
        if dead_tags.any?
          taggings.find(:all, :conditions => ["tag_id IN (?)", dead_tags.map(&:id)]).each(&:destroy)
          taggings.reset
        end
      end

      if tag_array.blank?
        taggings.find(:all).each(&:destroy)
        taggings.reset
      end
    end
  end
end
ActiveRecord::Base.send :include, Polytaggable if defined?( ActiveRecord::Base )