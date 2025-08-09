class AddStatusAndUserToPredictions < ActiveRecord::Migration[7.0]
  def change
    add_column :predictions, :status, :string, default: 'pending'
    add_reference :predictions, :user, foreign_key: true
  end
end