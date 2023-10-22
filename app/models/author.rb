class Author < ApplicationRecord
    self.primary_key = :authorid
    has_many :follows
end
