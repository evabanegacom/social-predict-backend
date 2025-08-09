class CreateUserRewards < ActiveRecord::Migration[7.0]
  def change
    create_table :user_rewards do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reward, null: false, foreign_key: true
      t.datetime :redeemed_at, null: false
      t.string :code # Unique code for airtime/data
      t.timestamps
    end
  end
end