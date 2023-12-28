class CreateAuthors < ActiveRecord::Migration[7.0]
  def change
    create_table :authors do |t|
      t.integer :author_id, unique: true, foreign_key: true
      t.string :name
      t.string :surname
      t.float :hindex
      t.string :institution
      t.integer :citationsnumber

      t.timestamps
    end
  end
end
