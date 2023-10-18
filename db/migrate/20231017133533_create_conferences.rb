class CreateConferences < ActiveRecord::Migration[7.0]
  def change
    create_table :conferences do |t|
      t.string :confId, unique: true
      t.string :name
      t.string :acronym
      t.timestamps
    end
  end
end

