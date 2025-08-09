class CreateActivities < ActiveRecord::Migration[7.0]
  def change
    create_table :activities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action, null: false # e.g., 'voted', 'created_prediction', 'redeemed_reward'
      t.string :target_type # e.g., 'Prediction', 'Reward'
      t.integer :target_id
      t.timestamps
    end
  end
end