class CrawlerSpotifyJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.info "CrawlerSpotifyJob started"
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
        Rails.logger.debug "Spotify episode name is #{episode["name"]}, external_urls is #{episode["external_urls"]["spotify"]}"
        return if flip_item && flip_item.link == episode["external_urls"]["spotify"]
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
        SpotifyItem.create!(name: episode["name"], link: episode["external_urls"]["spotify"], episode_id: episode["id"], release_date: episode["release_date"], transcript: transcript_text)
      end
    end
  end

  def transfer_to_flip
    Rails.logger.info "CrawlerSpotifyJob transfer_to_flip started"
    SpotifyItem.all.each do |spotify_item|
      title = spotify_item.name
      next if [ "1/2", "2/2", "1/3", "2/3", "3/3", "1/4", "2/4", "3/4", "4/4", "1/5", "2/5", "3/5", "4/5", "5/5", "YT直播", "透明茶室", "世界苦茶" ].any? { |substring| title.include?(substring) }
      next if FlipItem.find_by title: title
      FlipItem.create!(title: title, link: spotify_item.link, content: spotify_item.transcript, release_date: spotify_item.release_date)
    end
  end
end
