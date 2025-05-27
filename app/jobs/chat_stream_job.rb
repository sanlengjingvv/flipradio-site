class ChatStreamJob < ApplicationJob
  queue_as :default

  def perform(chat_id, user_content)
    chat = Chat.find(chat_id)
    chat.ask(user_content) do |chunk|
      # Get the assistant message record (created before streaming starts)
      assistant_message = chat.messages.last
      if chunk.content && assistant_message
        Rails.logger.debug "assistant_message recieved"
      end
    end
    # Final assistant message is now fully persisted
  end
end
