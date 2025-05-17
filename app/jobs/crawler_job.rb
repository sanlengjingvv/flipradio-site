require "open-uri"
require "rest-client"

class CrawlerJob < ApplicationJob
  queue_as :default

  def perform(*args)
    crawler_newsletter
  end

  def crawler_newsletter
    Rails.logger.info "CrawlerJob Started crawler_newsletter"
    host = "https://fearnation.club"
    flip_item = FlipItem.where("link LIKE ?", "https://fearnation.club/%").order(created_at: :desc).limit(1).first
    last_post = flip_item&.link
    last_post ||= "#{host}/shi-jie-ku-cha-5yue-11ri-xin-wen-32tiao/" # first post
    post = Nokogiri::HTML(URI.open(last_post))

    while post.css('[aria-label="Next post"]').attr("href") do
      next_post = post.at_css('[aria-label="Next post"]').attr("href")
      link = "#{host}#{next_post}"
      post = Nokogiri::HTML(URI.open(link))
      title = post.at_css("article h1.single-title").text.strip
      release_date = post.at_css("article time")["datetime"]
      content = post.xpath("//*[contains(@class, 'single-content')]//text()").map(&:text).join("\n").split("你希望我在透明茶室讨论什么新闻欢迎你告诉我").first.strip
      FlipItem.create(title: title, link: link, content: content, release_date: release_date)
      Rails.logger.info "Newsletter: #{title} saved"
    end
  end

  def crawler_article
    Rails.logger.info "CrawlerJob Started crawler_article"
    catalog = Nokogiri::HTML(URI.open("https://www.flipradio.club/-3"))
    catalog.css(".title-wrapper").each do |title_wrapper|
      title = title_wrapper.css("h3").text.strip
      link = title_wrapper.css("a").attr("href").value
      next if FlipItem.where(link: link).exists?
      Rails.logger.info "Article: #{title} #{link}"
      article = Nokogiri::HTML(URI.open(link))
      published_date = article.css(".published-date span:nth-child(2)").text
      content = article.xpath("//*[contains(@class, 'pub-body-component')]//text()").map(&:text).join("\n").strip
      Rails.logger.debug "Articl published_date and content: #{published_date} #{content}"
      FlipItem.create(title: title, link: link, content: content, release_date: published_date)
      Rails.logger.info "Article: #{title} saved"
    end
  end

  def crawler_anchor
    Rails.logger.info "CrawlerJob Started crawler_anchor"
    rss_url = "https://anchor.fm/s/141e652c/podcast/rss"
    rss = Nokogiri::XML(URI.open(rss_url))
    items = rss.xpath("//channel/item")
    puts items.size

    items.each do |item|
      title = item.xpath("title").text.strip
      next if [ "1/2", "2/2", "1/3", "2/3", "3/3", "1/4", "2/4", "3/4", "4/4", "1/5", "2/5", "3/5", "4/5", "5/5", "YT直播", "透明茶室" ].any? { |substring| title.include?(substring) }
      link = item.xpath("enclosure").attr("url").value
      release_date = item.xpath("pubDate").text.to_date.strftime("%Y-%m-%d")
      flip_item = FlipItem.find_by title: title
      if flip_item
        Rails.logger.debug "flip_item.link: #{flip_item.link}, link: #{link}, #{flip_item.link != link}"
        flip_item.update!(link: link) if flip_item.link != link
      else
        flip_item = FlipItem.create!(title: title, link: link, release_date: release_date)
      end
      Rails.logger.info "Anchor title: #{title} link: #{link} release_date: #{release_date} saved"
    end
  end
end
