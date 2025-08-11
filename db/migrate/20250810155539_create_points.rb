
class CreatePoints < ActiveRecord::Migration[7.0]
  def change
    create_table :points do |t|
      t.references :user, null: false, foreign_key: true
      t.references :prediction, null: false, foreign_key: true
      t.integer :points, null: false
      t.string :choice, null: false
      t.string :result, null: false
      t.datetime :awarded_at, null: false
      t.timestamps
    end
    add_index :points, [:user_id, :prediction_id], unique: true
  end
end
