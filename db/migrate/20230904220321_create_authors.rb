class CreateAuthors < ActiveRecord::Migration[7.0]
  def change
    create_table :authors do |t|
      t.integer :author_id, unique: true, foreign_key: true
      t.string :name
      t.string :orcid
      t.string :orcidStatus
      t.float :h_index
      t.integer :citationNumber
      t.integer :works_count
      t.string :last_known_institution
      t.string :last_known_institution_type
      t.string :last_known_institution_countrycode
      t.boolean :completed, default: false, null: false
      
      t.timestamps
    end
  end
end
