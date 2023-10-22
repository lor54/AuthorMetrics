class Follow < ApplicationRecord
  belongs_to :user
  belongs_to :author, foreign_key: :authorid
end
