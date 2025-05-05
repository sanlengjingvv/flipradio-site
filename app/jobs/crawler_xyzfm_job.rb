require "rest-client"

class CrawlerXyzfmJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.info "CrawlerXyzfmJob Started"
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
end
