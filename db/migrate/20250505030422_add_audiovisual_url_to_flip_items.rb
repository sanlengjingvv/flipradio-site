class AddAudiovisualUrlToFlipItems < ActiveRecord::Migration[8.0]
  def change
    add_column :flip_items, :audiovisual_url, :string
  end
end
