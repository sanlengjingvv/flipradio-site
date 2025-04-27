require "open-uri"
require "rest-client"

class CrawlerJob < ApplicationJob
  queue_as :default

  def perform(*args)
    crawler_newsletter
    crawler_spotify
  end

  def crawler_newsletter
    Rails.logger.debug "CrawlerJob Started crawler_newsletter"
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
    Rails.logger.debug "Spotify CrawlerJob Started"
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
      Rails.logger.debug "Next page of Spotify episodes is #{episodes["next"]}"
      episodes_response = RestClient.send "get", episodes["next"], { Authorization: "Bearer #{client_token}" }
      episodes = JSON.parse(episodes_response.body)

      flip_item = FlipItem.where("link LIKE ?", "https://open.spotify.com/episode/%").order(release_date: :desc, created_at: :desc).limit(1).first
      episodes["items"].each do |episode|
        return if flip_item && flip_item.link == episode["external_urls"]["spotify"]
        next if [ "1/2", "2/2", "1/3", "2/3", "3/3", "1/4", "2/4", "3/4", "4/4", "1/5", "2/5", "3/5", "4/5", "5/5", "YT直播", "透明茶室" ].any? { |substring| episode["name"].include?(substring) }
        Rails.logger.debug "Spotify episode name is #{episode["name"]}, external_urls is #{episode["external_urls"]["spotify"]}"
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
end
