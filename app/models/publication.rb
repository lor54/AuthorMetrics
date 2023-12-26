class Publication < ApplicationRecord
    self.primary_key = :publication_id
    has_many :works
    has_many :authors, through: :works
    belongs_to :citation, foreign_key: :citation_id
end
