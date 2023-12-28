class CreateConferences < ActiveRecord::Migration[7.0]
  def change
    create_table :conferences do |t|
      t.string :conference_id, unique: true, foreign_key: true
      t.string :name
      t.string :acronym
      t.timestamps
    end
  end
end

