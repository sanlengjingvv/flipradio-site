class CreatePodchaserItems < ActiveRecord::Migration[8.0]
  def change
    create_table :podchaser_items do |t|
      t.string :title, null: false
      t.datetime :air_date
      t.string :audio_url
      t.string :url
      t.string :episode_id, index: { unique: true, name: "unique_episode_id" }
      t.string :image_url

      t.timestamps
    end
  end
end
