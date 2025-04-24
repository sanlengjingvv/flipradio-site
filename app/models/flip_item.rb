class FlipItem < ApplicationRecord
  validates :title, presence: true
  validates :link, presence: true, uniqueness: true
  validates :content, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
