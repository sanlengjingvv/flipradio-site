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

  def crawler_spotify
    Rails.logger.info "Spotify CrawlerJob Started"
    api_uri = "https://api.spotify.com/v1"
    token_uri = "https://accounts.spotify.com/api/token"
    client_id = ENV["CLIENT_ID"]
    client_secret = ENV["CLIENT_SECRET"]
    authorization = Base64.strict_encode64("#{client_id}:#{client_secret}")
    auth_header = { "Authorization" => "Basic #{authorization}" }
    request_body = { grant_type: "client_credentials" }
    response = RestClient.post(token_uri, request_body, auth_header)
    client_token = JSON.parse(response)["access_token"]

    show_id = "6O2YwvuGpP2y17SpC8MM5s"
    episodes = { "next" => "#{api_uri}/shows/#{show_id}/episodes?limit=50&offset=0" }
    while episodes["next"] != nil
      Rails.logger.info "Next page of Spotify episodes is #{episodes["next"]}"
      episodes_response = RestClient.send "get", episodes["next"], { Authorization: "Bearer #{client_token}" }
      episodes = JSON.parse(episodes_response.body)

      flip_item = FlipItem.where("link LIKE ?", "https://open.spotify.com/episode/%").order(release_date: :desc, created_at: :desc).limit(1).first
      episodes["items"].each do |episode|
        return if flip_item && flip_item.link == episode["external_urls"]["spotify"]
        next if [ "1/2", "2/2", "1/3", "2/3", "3/3", "1/4", "2/4", "3/4", "4/4", "1/5", "2/5", "3/5", "4/5", "5/5", "YT直播", "透明茶室" ].any? { |substring| episode["name"].include?(substring) }
        Rails.logger.info "Spotify episode name is #{episode["name"]}, external_urls is #{episode["external_urls"]["spotify"]}"
        transcript_text = ""
        begin
          transcript_response = RestClient.send("get", "https://spclient.wg.spotify.com/transcript-read-along/v2/episode/#{episode["id"]}?format=json", { "Authorization" => "Bearer #{ENV['SPOTIFY_WEB_TOKEN']}" })
          transcript = JSON.parse(transcript_response.body)
          transcript["section"].each do |section|
            if section["text"] != nil
              sentence = section["text"]["sentence"]["text"].strip
              transcript_text << sentence
              transcript_text << "\n" if sentence[-1].match?(/\p{P}/)
            end
          end
          transcript_text.gsub!(" ", "")
          Rails.logger.debug transcript_text
        rescue Exception => e
          Rails.logger.error "Spotify transcript crawl failed: #{e.message}"
        end
        FlipItem.create(title: episode["name"], link: episode["external_urls"]["spotify"], content: transcript_text, release_date: episode["release_date"])
      end
    end
  end

  def crawler_youtube
    Rails.logger.info "Youtube CrawlerJob Started"
    last_youtube = FlipItem.where("link LIKE ?", "https://www.youtube.com/%").order(release_date: :desc, created_at: :desc).limit(1).first
    dateafter = last_youtube ? last_youtube.release_date.to_s.gsub("-", "") : "20231110"
    yt_dlp_path = Rails.root.join("exec", "yt-dlp").to_s
    cookies_path = Rails.root.join("exec", "cookies.txt").to_s
    cookies = File.exist?(cookies_path) ? "--cookies #{cookies_path}": ""
    command = "#{yt_dlp_path} #{cookies} --dateafter #{dateafter} --dump-json https://www.youtube.com/@flipradio_fearnation/videos"
    IO.popen(command) do |io|
      while line = io.gets
        info = JSON.parse(line.chomp)
        webpage_url = info["webpage_url"]
        title = info["title"]
        Rails.logger.info "Youtube-dl: #{title} #{webpage_url}"
        next if [ "PLxfcznuBUN2Dr6EqSxDSlrt7DjpznRbZk", "PLxfcznuBUN2AaOeUu1q03ccPf6XSJx8Ee", "PLxfcznuBUN2AC9eTTB3dbhEjMIih-UcAQ" ].include?(info["playlist_id"])
        next if FlipItem.find_by title: title
        upload_date = info["upload_date"]
        subtitle = ""
        if info["subtitles"] && info["subtitles"]["zh"]
          info["subtitles"]["zh"].each do |subtitle_zh|
            if subtitle_zh["ext"] == "vtt"
              subtitle_response = RestClient.send("get", subtitle_zh["url"])
              subtitle = subtitle_response.body
              subtitle.gsub!(/WEBVTT\nKind: captions\nLanguage: zh/, "")
              subtitle.gsub!(/^\d{2}:\d{2}:\d{2}\.\d{3} --> \d{2}:\d{2}:\d{2}\.\d{3}/, "")
              subtitle = subtitle.split("\n").reject(&:empty?).join("\n")
            end
          end
        end
        FlipItem.upsert({ title: title, link: webpage_url, content: subtitle, release_date: upload_date }, unique_by: :link)
        Rails.logger.info "Youtube: #{title} #{webpage_url} saved"
      end
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
