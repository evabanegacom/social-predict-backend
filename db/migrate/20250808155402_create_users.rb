# db/migrate/YYYYMMDDHHMMSS_create_users.rb
class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :username
      t.string :phone
      t.string :password_digest
      t.string :jti

      t.timestamps
    end
    add_index :users, :username, unique: true
    add_index :users, :phone, unique: true
    add_index :users, :jti, unique: true
  end
end