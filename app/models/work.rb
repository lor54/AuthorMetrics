class Work < ApplicationRecord
    belongs_to :publication
    belongs_to :author, foreign_key: :author_id
end
