class CreateAuthors < ActiveRecord::Migration[7.0]
  def change
    create_table :authors, id: false, primary_key: :authorid do |t|
      t.integer :authorid, null: false
      t.string :name
      t.string :surname
      t.float :hindex
      t.string :institution
      t.integer :citationsnumber

      t.timestamps
      t.index :authorid, unique: true
    end
  end
end
