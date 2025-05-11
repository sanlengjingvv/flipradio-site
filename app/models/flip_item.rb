class FlipItem < ApplicationRecord
  has_neighbors :embedding
  validates :title, presence: true
  validates :link, presence: true, uniqueness: true

  scope :recent, -> { order(release_date: :desc, created_at: :desc) }

  def self.search(params)
    if params[:commit] == "Keyword Search"
      where("title like ? OR content like ?", "%#{params[:query]}%", "%#{params[:query]}%")
    elsif params[:commit] == "Full Text Search"
      where("title @@@ ? OR zhparser_token @@@ ?", "#{params[:query]}", "#{params[:query]}").order(Arel.sql("paradedb.score(id) DESC, title, zhparser_token"))
    end
  end

  def self.update_embeddings
    all.each do |flip_item|
      embedding = RubyLLM.embed(
        flip_item.title,
        model: "text-embedding-004"
      )
      flip_item.update(embedding: embedding.vectors)
    end
  end
end
