class Logotype < ActiveRecord::Base
  acts_as_content :has_media => :attachment_fu
  has_attachment :max_size => 2.megabyte,
                 :content_type => :image, 
                 :thumbnails => { :space => '150x150>' , :photo => '120x120>'},
                 :resize_to => '300x300>'
                 
  alias_attribute :media, :uploaded_data
  belongs_to :db_file
  belongs_to :logotypable , :polymorphic =>true
  validates_as_attachment
end
