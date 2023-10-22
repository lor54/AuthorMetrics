class Author < ApplicationRecord
    self.primary_key = :author_id
    has_many :follows
end
