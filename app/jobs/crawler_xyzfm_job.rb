require "rest-client"

class CrawlerXyzfmJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.info "CrawlerXyzfmJob started"
    rss_url = "https://feed.xyzfm.space/36pjtvfwngyn"
    rss = Nokogiri::XML(RestClient.get(rss_url))
    items = rss.xpath("//channel/item")
    Rails.logger.info "CrawlerXyzfmJob items.size #{items.size}"
    items.each do |item|
      title = item.xpath("title").text
      enclosure_url = item.xpath("enclosure").attr("url").value
      pub_date = item.xpath("pubDate").text.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
      link = item.xpath("link").text
      xyzfm_item = XyzfmItem.find_by title: title
      XyzfmItem.create!(title: title, enclosure_url: enclosure_url, pub_date: pub_date, link: link) if xyzfm_item.nil?
      Rails.logger.info "XyzfmItem title: #{title} link: #{link} pub_date: #{pub_date} saved"
    end
  end

  def transfer_to_flip
    Rails.logger.info "CrawlerXyzfmJob transfer_to_flip started"
    XyzfmItem.all.each do |xyzfm_item|
      title = xyzfm_item.title
      next if [ "1/2", "2/2", "1/3", "2/3", "3/3", "1/4", "2/4", "3/4", "4/4", "1/5", "2/5", "3/5", "4/5", "5/5", "YT直播", "透明茶室", "世界苦茶" ].any? { |substring| title.include?(substring) }
      pub_date = xyzfm_item.pub_date
      link = xyzfm_item.link
      next if FlipItem.find_by title: title

      FlipItem.create!(title: title, link: link, release_date: pub_date)
      Rails.logger.info "FlipItem title: #{title} link: #{link} pub_date: #{pub_date} saved"
    end
  end
end
