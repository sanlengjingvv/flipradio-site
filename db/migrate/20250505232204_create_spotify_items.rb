class CreateSpotifyItems < ActiveRecord::Migration[8.0]
  def change
    create_table :spotify_items do |t|
      t.string :name
      t.string :link
      t.string :episode_id
      t.date :release_date
      t.text :transcript

      t.timestamps
    end
  end
end
