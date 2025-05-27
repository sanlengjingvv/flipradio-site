class MessagesController < ApplicationController
  before_action :set_chat

  def create
    message_content = params[:content]

    # Queue the background job to handle the streaming response
    ChatStreamJob.perform_later(@chat.id, message_content)

    # Immediately return success to the user
    respond_to do |format|
      format.turbo_stream { head :ok }
      format.html { redirect_to @chat }
    end
  end

  private

  def set_chat
    @chat = Chat.find(params[:chat_id])
  end
end
