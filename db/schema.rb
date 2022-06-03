# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_06_03_170459) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "jobber_accounts", force: :cascade do |t|
    t.string("jobber_id")
    t.string("name")
    t.string("jobber_access_token")
    t.datetime("jobber_access_token_expired_by")
    t.string("jobber_refresh_token")
    t.datetime("created_at", precision: 6, null: false)
    t.datetime("updated_at", precision: 6, null: false)
    t.index(["jobber_id"], name: "index_jobber_accounts_on_jobber_id", unique: true)
  end
end
