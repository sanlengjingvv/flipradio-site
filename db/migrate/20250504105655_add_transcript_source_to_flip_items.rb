class AddTranscriptSourceToFlipItems < ActiveRecord::Migration[8.0]
  def change
    add_column :flip_items, :transcript_source, :string
  end
end
