class CreateWorks < ActiveRecord::Migration[7.0]
  def change
    create_table :works do |t|
      t.string :publication_id, null: false
      t.string :author_id, null: false
      t.timestamps
    end
  end
end
