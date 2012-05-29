class Image < ActiveRecord::Base
  belongs_to :user
  has_attached_file :image, :styles => {:thumb => ["50x50#"], :attributed => ["%wx%h"]},
                      :processors => [:attributor_append, :thumbnail]

  before_create :check_image_presence
  before_save :check_image_presence

  validates_presence_of :user_id, :name, :publication_status

  named_scope :published, :conditions => { :publication_status => 'published' }
  named_scope :private_status, :conditions => { :publication_status => 'private' }
  named_scope :draft_status, :conditions => { :publication_status => 'draft' }
  named_scope :by_user, proc { |u| { :conditions => {:user_id => u.id} } }
  named_scope :with_status, proc { |s| { :conditions => { :publication_status => s } } }
  named_scope :not_private, { :conditions => "#{self.table_name}.publication_status IN ('published', 'draft')" }

  named_scope :visible_to_user, proc { |u| { :conditions =>
    [ "#{self.table_name}.publication_status = 'published' OR
      (#{self.table_name}.publication_status = 'private' AND #{self.table_name}.user_id = ?)", u.nil? ? u : u.id ]
  }}
  named_scope :visible_to_user_with_drafts, proc { |u| { :conditions =>
    [ "#{self.table_name}.publication_status IN ('published', 'draft') OR
      (#{self.table_name}.publication_status = 'private' AND #{self.table_name}.user_id = ?)", u.nil? ? u : u.id ]
  }}
  named_scope :no_drafts, :conditions => "#{self.table_name}.publication_status NOT IN ('draft')"

  named_scope :like, lambda { |name|
    name = "%#{name}%"
    { :conditions => ["#{self.table_name}.name LIKE ? OR #{self.table_name}.attribution LIKE ?", name,name] }
  }

  named_scope :ordered_by, lambda { |order| { :order => order } }

  # special named scope for combining other named scopes in an OR fashion
  # FIXME This is probably terribly inefficient
  named_scope :match_any, lambda { |scopes| {
    :conditions => "(#{scopes.map{|s| "#{self.table_name}.id IN (#{s.send(:construct_finder_sql,{:select => :id})})" }.join(" OR ")})"
  }}

  include Changeable
  include Publishable

  self.extend SearchableModel
  @@searchable_attributes = %w{name attribution}
  class <<self
    def can_be_created_by?(user)
      user.has_role?('admin', 'manager', 'researcher', 'author') || (Admin::Project.default_project.teachers_can_author? && user.portal_teacher)
    end

    def searchable_attributes
      @@searchable_attributes
    end

    def search_list(options)
      name = options[:name]
      name_matches = Image.like(name)
      is_visible = options[:include_drafts] ? name_matches.not_private : name_matches.published

      images = nil

      if options[:user]
        by_user = name_matches.by_user(options[:user]) if options[:user]
        images = Image.match_any([is_visible, by_user])
      else
        images = is_visible
      end

      unless options[:sort_order].blank?
        images = images.ordered_by(options[:sort_order])
      end

      if options[:paginate]
        images = images.paginate(:page => options[:page] || 1, :per_page => options[:per_page] || 20)
      end

      images
    end
  end

  def check_image_presence
    unless self.image_file_name
      self.errors.add(:image, :blank)
      return false
    end
    return true
  end

  def display_name
    res = []
    res << "[#{self.publication_status.upcase}]" if %w(draft private).include?(self.publication_status)
    res << self.name
    res.join(" ")
  end
end
