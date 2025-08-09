class CreateRewards < ActiveRecord::Migration[7.0]
  def change
    create_table :rewards do |t|
      t.string :name, null: false
      t.text :description
      t.integer :points_cost, null: false
      t.string :reward_type, null: false # e.g., 'airtime', 'data', 'badge'
      t.integer :stock, null: false, default: 0
      t.timestamps
    end
  end
end