class Publication < ApplicationRecord
    has_many :works
    has_many :authors, through: :works
    belongs_to :conference, foreign_key: "conference_id", optional: true
end
