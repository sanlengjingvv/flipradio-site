require "open-uri"

class CrawlerJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.debug "CrawlerJob Started"
    host = "https://fearnation.club"
    flip_item = FlipItem.where("link LIKE ?", "https://fearnation.club/%").order(created_at: :desc).limit(1).first
    last_post = flip_item&.link
    last_post ||= "#{host}/shi-jie-ku-cha-5yue-11ri-xin-wen-32tiao/" # first post
    post = Nokogiri::HTML(URI.open(last_post))

    while post.css('[aria-label="Next post"]').attr("href") do
      next_post = post.css('[aria-label="Next post"]').attr("href").value
      link = "#{host}#{next_post}"
      post = Nokogiri::HTML(URI.open(link))
      title = post.css("article h1.single-title").text.strip
      date = post.css("article time").text.strip
      content = date + " " + post.xpath("//*[contains(@class, 'single-content')]//text()").map(&:text).join("\n").split("你希望我在透明茶室讨论什么新闻欢迎你告诉我").first.strip
      FlipItem.create(title: title, link: link, content: content)
      Rails.logger.info "Newsletter: #{title} saved"
    end
  end
end
