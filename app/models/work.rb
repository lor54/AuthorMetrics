class Work < ApplicationRecord
    belongs_to :publication
    belongs_to :author
end
