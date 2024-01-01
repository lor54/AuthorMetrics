class CreatePublications < ActiveRecord::Migration[7.0]
  def change
    create_table :publications do |t|
      t.string :publication_id, unique: true, foreign_key: true
      t.string :title
      t.string :url
      t.string :articleType
      t.integer :releaseDate
      t.belongs_to :conference, foreign_key: true

      t.timestamps
    end
  end
end
