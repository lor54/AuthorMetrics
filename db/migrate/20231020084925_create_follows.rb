class CreateFollows < ActiveRecord::Migration[7.0]
  def change
    create_table :follows do |t|
      t.references :user, null: false
      t.string :author_id, null: false 

      t.timestamps
    end
  end
end
