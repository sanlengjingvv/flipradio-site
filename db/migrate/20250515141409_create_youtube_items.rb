class CreateYoutubeItems < ActiveRecord::Migration[8.0]
  def change
    create_table :youtube_items do |t|
      t.string :title
      t.string :webpage_url
      t.text :subtitle
      t.date :upload_date

      t.timestamps
    end
  end
end
