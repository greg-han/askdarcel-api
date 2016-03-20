class CreateResources < ActiveRecord::Migration
  def change
    create_table :resources do |t|
      t.timestamps null: false

      t.string :name, null: false
      t.string :short_description
      t.text :long_description
      t.string :website
    end
  end
end
