class FlipItem < ApplicationRecord
  validates :title, presence: true
  validates :link, presence: true, uniqueness: true

  scope :recent, -> { order(release_date: :desc, created_at: :desc) }

  def self.search(query)
    where("title like ? OR content like ?", "%#{query}%", "%#{query}%")
  end
end
