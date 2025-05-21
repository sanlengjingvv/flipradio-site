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

ActiveRecord::Schema[8.0].define(version: 2025_05_21_122650) do
  create_schema "monitor"
  create_schema "paradedb"
  create_schema "repack"
  create_schema "zhparser"

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
  enable_extension "paradedb.pg_search"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_repack"
  enable_extension "pg_trgm"
  enable_extension "postgres_fdw"
  enable_extension "vector"
  enable_extension "zhparser"

  create_table "chats", force: :cascade do |t|
    t.string "model_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "flip_items", force: :cascade do |t|
    t.string "title"
    t.string "link"
    t.text "content", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "release_date"
    t.string "transcript_source"
    t.string "audiovisual_url"
    t.text "zhparser_token", default: [], array: true
    t.vector "embedding", limit: 768
    t.index ["id", "title", "zhparser_token"], name: "search_idx", using: :bm25
    t.index ["link"], name: "index_flip_items_on_link", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.string "role"
    t.text "content"
    t.string "model_id"
    t.integer "input_tokens"
    t.integer "output_tokens"
    t.bigint "tool_call_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["tool_call_id"], name: "index_messages_on_tool_call_id"
  end

  create_table "podchaser_items", force: :cascade do |t|
    t.string "title", null: false
    t.datetime "air_date"
    t.string "audio_url"
    t.string "url"
    t.string "episode_id"
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["episode_id"], name: "unique_episode_id", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "spotify_items", force: :cascade do |t|
    t.string "name"
    t.string "link"
    t.string "episode_id"
    t.date "release_date"
    t.text "transcript"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["link"], name: "index_spotify_items_on_link", unique: true
  end

  create_table "tool_calls", force: :cascade do |t|
    t.bigint "message_id", null: false
    t.string "tool_call_id", null: false
    t.string "name", null: false
    t.jsonb "arguments", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_tool_calls_on_message_id"
    t.index ["tool_call_id"], name: "index_tool_calls_on_tool_call_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "xyzfm_items", force: :cascade do |t|
    t.string "title"
    t.string "enclosure_url"
    t.datetime "pub_date"
    t.string "link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "youtube_items", force: :cascade do |t|
    t.string "title"
    t.string "webpage_url"
    t.text "subtitle"
    t.date "upload_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "messages", "chats"
  add_foreign_key "sessions", "users"
  add_foreign_key "tool_calls", "messages"
end
