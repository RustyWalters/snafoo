class CreateSuggestions < ActiveRecord::Migration
  def change
    create_table :suggestions do |t|
      t.string :name
      t.string :location
      t.date :lastPurchasedDate
      t.integer :votes
      t.integer :suggestedMonth

      t.timestamps
    end
  end
end
