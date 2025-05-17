class CrawlerYoutubeJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.info "CrawlerYoutubeJob Started"
    last_youtube = YoutubeItem.order(upload_date: :desc, created_at: :desc).limit(1).first
    dateafter = last_youtube ? last_youtube.upload_date.to_s.gsub("-", "") : "20240124"
    yt_dlp_path = Rails.root.join("exec", "yt-dlp").to_s
    cookies_path = Rails.root.join("exec", "cookies.txt").to_s
    cookies = File.exist?(cookies_path) ? "--cookies #{cookies_path}": ""
    command = "#{yt_dlp_path} #{cookies} --dateafter #{dateafter} --dump-json https://www.youtube.com/@flipradio_fearnation/videos"
    IO.popen(command) do |io|
      while line = io.gets
        Rails.logger.debug line
        info = JSON.parse(line.chomp)
        webpage_url = info["webpage_url"]
        title = info["title"]
        Rails.logger.info "yt-dlp: #{title} #{webpage_url}"
        upload_date = info["upload_date"]
        next if YoutubeItem.find_by title: title
        next if upload_date.eql? "20240504"
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
        YoutubeItem.create!({ title: title, webpage_url: webpage_url, subtitle: subtitle, upload_date: upload_date })
        Rails.logger.info "Youtube: #{title} #{webpage_url} saved"
      end
    end
  end

  def transfer_to_flip
    Rails.logger.info "CrawlerYoutubeJob transfer_to_flip started"
    YoutubeItem.all.each do |youtube_item|
      title = youtube_item.title
      next if FlipItem.find_by title: title
      FlipItem.create!(title: title, link: youtube_item.webpage_url, content: youtube_item.subtitle, release_date: youtube_item.upload_date)
    end
  end
end
