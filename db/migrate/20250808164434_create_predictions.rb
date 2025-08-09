class CreatePredictions < ActiveRecord::Migration[7.0]
  def change
    create_table :predictions do |t|
      t.string :topic
      t.string :category
      t.jsonb :vote_options, default: { yes: 0, no: 0, maybe: 0 }
      t.datetime :expires_at

      t.timestamps
    end
  end
end