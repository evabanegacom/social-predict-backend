class AddResultToPredictions < ActiveRecord::Migration[7.0]
  def change
    add_column :predictions, :result, :string
  end
end