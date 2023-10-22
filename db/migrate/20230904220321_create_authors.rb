class CreateAuthors < ActiveRecord::Migration[7.0]
  def change
    create_table :authors, id: false, primary_key: :author_id do |t|
      t.integer :author_id, null: false
      t.string :name
      t.string :surname
      t.float :hindex
      t.string :institution
      t.integer :citationsnumber

      t.timestamps
      t.index :author_id, unique: true
    end
  end
end
