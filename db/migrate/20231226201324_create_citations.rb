class CreateCitations < ActiveRecord::Migration[7.0]
  def change
    create_table :citations, primary_key: :citation_id do |t|
      t.integer :year
      t.integer :citation_count
      t.string :author_id, null: false

      t.timestamps
    end
  end
end
