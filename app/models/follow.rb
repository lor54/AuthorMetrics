class Follow < ApplicationRecord
    belongs_to :user_id, class_name: 'User'
end
