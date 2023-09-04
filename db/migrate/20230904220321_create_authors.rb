class CreateAuthors < ActiveRecord::Migration[7.0]
  def change
    create_table :authors do |t|
      t.integer :authorid
      t.string :name
      t.string :surname
      t.float :hindex
      t.string :institution
      t.integer :citationsnumber

      t.timestamps
    end
  end
end
