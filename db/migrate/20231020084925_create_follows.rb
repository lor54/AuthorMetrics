class CreateFollows < ActiveRecord::Migration[7.0]
  def change
    create_table :follows do |t|
      t.references :user, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: true 

      add_index :authors, :authorid, unique: true
      add_foreign_key :follows, :users, column: :user_id
      add_foreign_key :follows, :authors, column: :authorid

      t.timestamps
    end
  end
end
