class ConferenceAuthor < ApplicationRecord
  belongs_to :conference
  belongs_to :author
end
