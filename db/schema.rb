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

ActiveRecord::Schema[8.0].define(version: 2025_04_20_131850) do
  create_schema "monitor"
  create_schema "repack"

  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gin"
  enable_extension "btree_gist"
  enable_extension "file_fdw"
  enable_extension "intagg"
  enable_extension "intarray"
  enable_extension "monitor.pageinspect"
  enable_extension "monitor.pg_buffercache"
  enable_extension "monitor.pg_freespacemap"
  enable_extension "monitor.pg_prewarm"
  enable_extension "monitor.pg_stat_statements"
  enable_extension "monitor.pg_visibility"
  enable_extension "monitor.pgstattuple"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_repack"
  enable_extension "pg_trgm"
  enable_extension "postgres_fdw"

  create_table "flip_items", force: :cascade do |t|
    t.string "title"
    t.string "link"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
