class AddReleaseDateToFlipItems < ActiveRecord::Migration[8.0]
  def change
    add_column :flip_items, :release_date, :date
    add_index :flip_items, :link, unique: true
  end
end
