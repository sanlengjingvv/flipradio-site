class FlipItem < ApplicationRecord
  validates :title, presence: true
  validates :link, presence: true, uniqueness: true
  validates :content, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def self.search(query)
    where("title like ? OR content like ?", "%#{query}%", "%#{query}%")
  end
end
