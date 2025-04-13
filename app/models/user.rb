class CreateUsers < ActiveRecord::Migration[6.0]
    def change
      create_table :users do |t|
        t.string :email, null: false, unique: true
        t.string :password_digest, null: false
        t.integer :user_type, default: 0, null: false  # 0 for Donor, 1 for Charity
        t.timestamps
      end
  
      add_index :users, :email, unique: true
    end
  end
  