class CreateVotes < ActiveRecord::Migration[7.0]
  def change
    create_table :votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :prediction, null: false, foreign_key: true
      t.string :choice

      t.timestamps
    end
    add_index :votes, [:user_id, :prediction_id], unique: true
  end
end