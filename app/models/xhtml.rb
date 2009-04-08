class Xhtml < ActiveRecord::Base
  belongs_to :user
  has_many :page_elements, :as => :embeddable
  has_many :pages, :through =>:page_elements

  acts_as_replicatable

  include Changeable

  self.extend SearchableModel
  
  @@searchable_attributes = %w{name description content}
  
  class <<self
    def searchable_attributes
      @@searchable_attributes
    end
  end

  default_value_for :name, "xhtml content"
  default_value_for :description, "description ..."
  default_value_for :content, <<-HEREDOC
  <p>Xhtml content goes here ...</p>
  HEREDOC
end
