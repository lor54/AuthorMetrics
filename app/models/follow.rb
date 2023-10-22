class Follow < ApplicationRecord
  belongs_to :user
  belongs_to :author, foreign_key: :author_id
end
