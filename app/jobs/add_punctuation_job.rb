class AddPunctuationJob < ApplicationJob
  queue_as :default

  def perform(*args)
    flip_items = FlipItem.where("content not LIKE ?", "%。%")
    flip_items.each do |item|
      next if item.content.blank?
      chat = RubyLLM.chat(model: "gemini-2.0-flash")
      prompt = <<-prompt
        Please add appropriate punctuation marks and paragraph breaks to the following Chinese text that was transcribed from audio. Requirements:

        1. Add punctuation marks (periods, commas, question marks, etc.) based on semantic meaning and tone
        2. Create logical paragraph breaks based on content flow and topic changes
        3. Preserve the original meaning completely
        4. Ensure the text flows naturally and is easy to read
        5. Do not add any content that wasn't in the original text
        6. Format as clean, readable Chinese text

        Text to process:
        #{item.content}

        Formatted result:
      prompt
      Rails.logger.debug "Prompt for item ID #{item.id}: #{prompt}"
      response = chat.ask prompt
      punctuated_content = response.content
      Rails.logger.debug "Punctuated content: #{punctuated_content}"

      item.update(content: punctuated_content) if punctuated_content.present?
    end
  end
end
