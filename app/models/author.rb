class Author < ApplicationRecord
    has_many :follows, class_name: 'Follow', foreign_key: 'authorid'
end
