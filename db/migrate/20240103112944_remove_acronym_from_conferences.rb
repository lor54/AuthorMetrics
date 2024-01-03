class RemoveAcronymFromConferences < ActiveRecord::Migration[7.0]
  def change
    remove_column :conferences, :acronym
  end
end
