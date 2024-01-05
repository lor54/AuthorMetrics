class CreatePublications < ActiveRecord::Migration[7.0]
  def change
    create_table :publications, id: false, primary_key: :publication_id do |t|
      t.string :publication_id, null: false
      t.integer :year
      t.string :title
      t.string :url
      t.string :articleType
      t.date :releaseDate

      t.timestamps
      t.index :publication_id, unique: true
    end
  end
end
