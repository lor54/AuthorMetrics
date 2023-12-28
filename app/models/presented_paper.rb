class PresentedPaper < ApplicationRecord
  belongs_to :conference
  belongs_to :publication
end
