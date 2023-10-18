class Edition < ApplicationRecord
  belongs_to :conference, foreign_key: :confId, primary_key: [:editionId, :confId]
end
