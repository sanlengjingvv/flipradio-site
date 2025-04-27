class AddDefaultToFlipItemContent < ActiveRecord::Migration[8.0]
  def change
    change_column_default :flip_items, :content, from: nil, to: ""
  end
end
