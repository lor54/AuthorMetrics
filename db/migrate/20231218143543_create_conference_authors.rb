class CreateConferenceAuthors < ActiveRecord::Migration[7.0]
  def change
    create_table :conference_authors do |t|
      t.string :author, null: false
      t.string :conference, null: false
      t.integer :publication_number
      t.timestamps
    end

    add_foreign_key :conference_authors, :authors, column: :author, foreign_key: "author_id", on_delete: :cascade
    add_foreign_key :conference_authors, :conferences, column: :conference, foreign_key: "conference_id", on_delete: :cascade

  end
end
