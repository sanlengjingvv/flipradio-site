class AddIndexToSpotifyItems < ActiveRecord::Migration[8.0]
  def change
    add_index :spotify_items, :link, unique: true
  end
end
