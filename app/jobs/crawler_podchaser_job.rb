require "rest-client"

class CrawlerPodchaserJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.info "CrawlerPodchaserJob started"
    last_episode = PodchaserItem.order(air_date: :desc, created_at: :desc).limit(1).first
    podchaser_api = "https://api.podchaser.com/graphql"
    headers = { "Content-Type" => "application/json", "Authorization" => "Bearer #{ENV["PODCHASER_TOKEN_PROD"]}" }
    page = 0
    hasMorePages = true
    while hasMorePages
      query = <<~QUERY
      query Podcast {
          podcast(identifier: { id: "22728", type: PODCHASER }) {
              title
              episodes(page: #{page}, sort: { sortBy: AIR_DATE, direction: DESCENDING }, first: 100) {
                  data {
                      title
                      airDate
                      audioUrl
                      url
                      id
                      imageUrl
                  }
                  paginatorInfo {
                      total
                      hasMorePages
                  }
              }
          }
      }
      QUERY
      request_body = {
        "query": query,
        "operationName": "Podcast",
        "variables": {}
      }
      Rails.logger.debug "Job crawler_podchaser request_body #{request_body}"
      response = RestClient.post(podchaser_api, request_body.to_json, headers)
      Rails.logger.debug "Job crawler_podchaser #{response}"
      episodes = JSON.parse(response)["data"]["podcast"]["episodes"]
      episodes["data"].each do |episode|
        title = episode["title"]
        air_date = episode["airDate"]
        break if last_episode && last_episode.air_date > air_date
        audio_url = episode["audioUrl"]
        url = episode["url"]
        id = episode["id"]
        image_url = episode["imageUrl"]
        podchaser_item = PodchaserItem.find_by id: id
        PodchaserItem.create!(title: title, air_date: air_date, audio_url: audio_url, url: url, episode_id: id, image_url: image_url) if podchaser_item.nil?
      end
      hasMorePages = episodes["paginatorInfo"]["hasMorePages"]
      page += 1
    end
  end
end
