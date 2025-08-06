class UpdateFlipItemsSearchIndex < ActiveRecord::Migration[8.0]
  def up
    # Remove old search index if it exists
    execute "DROP INDEX IF EXISTS search_idx"

    # Remove zhparser_token column if it exists
    remove_column :flip_items, :zhparser_token, :text if column_exists?(:flip_items, :zhparser_token)

    # Create new BM25 search index with jieba tokenizer
    execute <<~SQL
      CREATE INDEX search_idx ON public.flip_items
      USING bm25 (id, title, content)
      WITH (
          key_field = 'id',
          text_fields = '{
              "title": {
                "tokenizer": {"type": "jieba"}
              },
              "content": {
                "tokenizer": {"type": "jieba"}
              }
          }'
      )
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS search_idx"
    add_column :flip_items, :zhparser_token, :text if !column_exists?(:flip_items, :zhparser_token)
  end
end
