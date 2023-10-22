class Follow < ApplicationRecord
  belongs_to :user, class_name: 'User'
  belongs_to :author, class_name: 'Author'
end
