class CreatePresentedPapers < ActiveRecord::Migration[7.0]
  def change
    create_table :presented_papers do |t|
      t.string :publication, null: false
      t.string :conference, null: false
      t.integer :year
      t.timestamps
    end

    add_foreign_key :presented_papers, :publications, column: :publication, foreign_key: "publication_id", on_delete: :cascade
    add_foreign_key :presented_papers, :conferences, column: :conference, foreign_key: "conference_id", on_delete: :cascade

  end
end
