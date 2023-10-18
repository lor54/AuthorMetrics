class CreateEditions < ActiveRecord::Migration[7.0]
  def change
    create_table :editions, primary_key: [:editionId, :confId] do |t|
      t.string :name
      t.string :confId, null:false
      t.integer :editionId, null:false
      t.timestamps
    end
  end
end
