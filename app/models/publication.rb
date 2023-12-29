class Publication < ApplicationRecord
    has_many :works
    has_many :authors, through: :works
end
