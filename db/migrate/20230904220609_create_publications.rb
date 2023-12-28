class CreatePublications < ActiveRecord::Migration[7.0]
  def change
    create_table :publications do |t|
      t.string :publication_id, unique: true, foreign_key: true
      t.string :title
      t.string :url
      t.date :releasedate

      t.timestamps
    end
  end
end
