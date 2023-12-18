class Author < ApplicationRecord
    self.primary_key = :author_id
    has_many :follows
    has_many :works
    has_many :publications, through: :works
end
