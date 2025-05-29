class Message < ApplicationRecord
  acts_as_message
  broadcasts_to ->(message) { [ message.chat, "messages" ] }

  # Helper to broadcast chunks during streaming
  def broadcast_append_chunk(chunk_content)
    broadcast_append_to [ chat, "messages" ], # Target the stream
      target: ActionView::RecordIdentifier.dom_id(self, "content"), # Target the content div inside the message frame
      html: chunk_content # Append the raw chunk
  end
end
