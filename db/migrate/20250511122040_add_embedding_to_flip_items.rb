class AddEmbeddingToFlipItems < ActiveRecord::Migration[8.0]
  def change
    add_column :flip_items, :embedding, :vector, limit: 768
  end
end
