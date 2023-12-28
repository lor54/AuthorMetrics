class CreateCitations < ActiveRecord::Migration[7.0]
  def change
    create_table :citations do |t|
      t.integer :year
      t.integer :citation_count

      t.timestamps
    end
  end
end
