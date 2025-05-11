class AddZhparserTokenToFlipItems < ActiveRecord::Migration[8.0]
  def change
    add_column :flip_items, :zhparser_token, :text, array: true, default: []
  end
end
