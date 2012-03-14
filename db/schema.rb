# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120314154127) do

  create_table "answers", :force => true do |t|
    t.string   "type"
    t.float    "confidence"
    t.boolean  "answer"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "judgements"
    t.integer  "article_id"
    t.string   "source",     :default => "CrowdFlower"
    t.integer  "user_id",                               :null => false
  end

  create_table "articles", :force => true do |t|
    t.string   "source"
    t.date     "pub_date"
    t.string   "byline",              :limit => 500
    t.string   "headline",            :limit => 500
    t.string   "page"
    t.string   "src_url",             :limit => 1000
    t.string   "abstract",            :limit => 2000
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "total_pages"
    t.integer  "word_count"
    t.string   "src_url_md5"
    t.string   "section"
    t.string   "queue_status"
    t.string   "scan_src_url",        :limit => 1000
    t.string   "scan_local_filename"
    t.string   "scan_file_url",       :limit => 1000
    t.string   "blacklist_tag"
    t.boolean  "golden",                              :default => false
    t.string   "sampletag"
  end

  add_index "articles", ["queue_status"], :name => "index_articles_on_queue_status"
  add_index "articles", ["source"], :name => "source_index"
  add_index "articles", ["src_url_md5"], :name => "src_url_md5_index", :unique => true

  create_table "golds", :force => true do |t|
    t.integer  "article_id"
    t.string   "type"
    t.boolean  "answer"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "username"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
