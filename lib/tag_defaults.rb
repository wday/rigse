module TagDefaults

  ##
  ## Called when a class is extended by this module
  ##
  def self.included(clazz)
    clazz.extend(ClassMethods)
    #clazz.class_eval do
      #after_save :update_available_tags
    #end
  end
  # class methods
  module ClassMethods
    def found_tags
      results = {}
      self.tag_types.each do |type|
        results[type] ||= []
        results[type] = results[type] +  self.tag_counts_on(type).map { |tc| tc.name }
        results[type] = results[type].uniq.sort
      end
      results
    end

    def read_defaults
      yaml_file = RAILS_ROOT + "/config/tag_defaults.yml"
      sample_file = RAILS_ROOT + "/config/tag_defaults.sample.yml"
      begin
        YAML.load_file(yaml_file)
      rescue
        Rails.logger.warn("can't read default tags file #{yaml_file}")
        begin
          Rails.logger.warn("copying sample:  #{sample_file} to #{yaml_file}")
          %x[cp #{sample_file} #{yaml_file}]
          YAML.load_file(yaml_file)
        rescue
          Rails.logger.error("Can't load tag defaults. See lib/tag_defaults.rb")
        end
      end
    end

    def default_tags
      unless defined? @@default_tags
        @@default_tags = read_defaults
      end
      @@default_tags
    end

    def add_tag(scope,tag)
      unless self.default_tags[scope]
        self.default_tags[scope] = []
      end
      self.default_tags[scope] << tag.strip
      self.default_tags[scope].uniq!
      self.default_tags[scope].sort!
      self.default_tags[scope]
    end

    def available_tags(scope=nil)
      if scope
        if self.default_tags[scope] && self.default_tags[scope].size > 0
          return self.default_tags[scope].map { |i| i.strip}
        else
          return []
        end
      end
      return self.default_tags.values.flatten.uniq.map { |i| i.strip}
    end

    def find_by_bin(grade_level,subject_area)
      results = {}
      found = self.published.tagged_with(grade_level, :on => :grade_level).tagged_with(subject_area, :on => :subject_area)
      found.each do |act|
        act.units.each do |unit|
          results[unit] ||= []
          results[unit] << act
        end
      end
    end

    def list_bins(opts = {})
      portal_clazz = opts[:portal_clazz]
      user = opts[:user]
      offerings = nil
      off_runnables = []

      if portal_clazz && portal_clazz.teacher
        user ||= portal_clazz.teacher.user
        offerings = portal_clazz.offerings
        off_runnables= offerings.map { |o| o.runnable }
      end
      
      # Add exemplar activities
      activities = opts[:activities] || self.published_exemplars # self should be publishable
      key_map = activities.map { |a| {:activity => a, :keys => a.bin_keys }}
      if user
        # Add all un archived activities of the user:
        # this is using the ar extensions
        users_own = self.find(:all, :conditions => {:user_id => user.id, :publication_status => ['published', 'private']});
        users_key_map = users_own.map do |a|
          # todo
          grade_level = "My #{self.name.humanize.pluralize}"
          subject_area = ""
          unit = ""
          key = [grade_level,subject_area,unit]
          {
            :activity => a,
            :keys => [key]
          }
        end
        key_map = key_map + users_key_map

        # Add published activities by others (non-exemplars)
        if (user.portal_teacher || user.has_role?("admin") || user.has_role?("manager") || user.has_role?("author"))
          other_activities = self.published_non_exemplars
          other_activities.reject! { |activity| activity.user == user }
          others_key_map = other_activities.map do |a|
            # todo
            grade_level = "Other #{self.name.humanize.pluralize}"
            subject_area = ""
            author = a.user.name
            key = [grade_level,subject_area,author]
            {
              :activity => a,
              :keys => [key]
            }
          end
          key_map = key_map + others_key_map
        end
      end

      results = {}
      key_counter = 0
      key_map.each do |key_map|
        keys = key_map[:keys]
        act  = key_map[:activity]
        keys.each do |key|
          grade_level = key[0]
          subject = key[1]
          unit = key[2]
          key_string = "#{grade_level}#{subject}".gsub(/\s+/,"").downcase
          # hacky ordering of grade levels
          order = 5
          case key_string
          when /^elem/i
            order = 1
          when /^midd/i
            order = 2
          when /^high/i
            order = 3
          when /^math/i
            order = 4
          when /^testselem/i    # throwing tests at end -- not sure where they should go
            order = 7
          when /^testsmidd/i
            order = 8
          when /^testshigh/i
            order = 9
          end
          key_string = "#{order}#{key_string}"
          unless results[key_string]
            results[key_string] = {
              :order => order,
              :name => "#{key[0]} #{key[1]}",
              :grade_level => grade_level,
              :subject_area => subject,
              :activities => [],
              :units => {},
            }
          end
          results[key_string][:activities] << act
          results[key_string][:units][unit] ||= {:activities => [], :count => 0, :name => unit}
          results[key_string][:units][unit][:activities] << act
        end
      end

      # update aggregate values
      results.each_key do |key|
        record=results[key]
        record[:query] = record[:activities]
        record[:count] = record[:activities].size
        record[:off_count] = (record[:activities] & off_runnables).size
        record[:activities].sort!{ |a,b| a.name <=> b.name }
        record[:units].each_key do |unit_key|
          unit = record[:units][unit_key]
          unit[:activities].sort!{ |a,b| a.name <=> b.name }
          unit[:count] = unit[:activities].size
        end
      end
      results
    end
  end

  ## Instance Methods:
  
  ## Tag this instance with random tags:
  def random_tags
    self.grade_level_list = self.class.default_tags[:grade_levels].rand
    self.unit_list = self.class.default_tags[:units].rand
    self.subject_area_list = self.class.default_tags[:subject_areas].rand
  end

  ## Return the set of tag-keys[grade,subject,unit] for this instance.
  def bin_keys
    results = []
    self.grade_level_list.each do |grade|
      self.subject_area_list.each do |subject|
        self.unit_list.each do |unit|
          results << [grade,subject,unit]
        end
      end
    end
    results
  end
end