class Follow < ApplicationRecord
  validates :user_id, uniqueness: { scope: :author_id } 
  belongs_to :user
  belongs_to :author
end
