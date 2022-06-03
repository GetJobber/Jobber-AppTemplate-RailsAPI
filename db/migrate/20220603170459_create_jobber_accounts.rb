# frozen_string_literal: true

class CreateJobberAccounts < ActiveRecord::Migration[6.1]
  def change
    create_table(:jobber_accounts) do |t|
      t.string(:jobber_id)
      t.string(:name)
      t.string(:jobber_access_token)
      t.datetime(:jobber_access_token_expired_by)
      t.string(:jobber_refresh_token)

      t.timestamps
    end
    add_index(:jobber_accounts, :jobber_id, unique: true)
  end
end
