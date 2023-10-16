class CreateFollows < ActiveRecord::Migration[7.0]
  def change
    create_table :follows do |t|
      t.integer :user_id
      t.integer :author_id

      t.timestamps
    end
  end
end
