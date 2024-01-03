class AddConferenceRefToPublications < ActiveRecord::Migration[7.0]
  def change
    add_belongs_to :publications, :conference
  end
end
