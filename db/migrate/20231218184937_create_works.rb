class CreateWorks < ActiveRecord::Migration[7.0]
  def change
    create_table :works do |t|
      t.belongs_to :publication
      t.string :author_id, null: false
      t.timestamps
    end
  end
end
