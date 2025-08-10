class AddRewardIdToPoints < ActiveRecord::Migration[7.0]
  def change
    add_reference :points, :reward, foreign_key: true
    remove_index :points, [:user_id, :prediction_id]
    add_index :points, [:user_id, :prediction_id], unique: true, where: "prediction_id IS NOT NULL"
    add_index :points, [:user_id, :reward_id], unique: true, where: "reward_id IS NOT NULL"
  end
end
