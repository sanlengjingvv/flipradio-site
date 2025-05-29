class ChatStreamJob < ApplicationJob
  queue_as :default

  def perform(chat_id, user_content)
    Message.where(role: "assistant", content: "").destroy_all
    chat = Chat.find(chat_id)
    chat.ask(user_content) do |chunk|
      # Get the assistant message record (created before streaming starts)
      assistant_message = chat.messages.last
      if chunk.content && assistant_message
        Rails.logger.debug "assistant_message recieved"
        # Append the chunk content to the message's target div
        assistant_message.broadcast_append_chunk(chunk.content)
      end
    end
    # Final assistant message is now fully persisted
  end
end
