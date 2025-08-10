class ChangePredictionIdNullableInPoints < ActiveRecord::Migration[7.0]
  def change
    change_column_null :points, :prediction_id, true
  end
end
