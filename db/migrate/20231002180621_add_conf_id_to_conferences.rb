class AddConfIdToConferences < ActiveRecord::Migration[7.0]
  def change
    add_column :conferences, :ConfId, :string
  end
end
