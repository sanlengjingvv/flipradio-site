class ChatsController < ApplicationController
  def index
    @pagy, @chats = pagy(Chat.all)
  end

  def show
    @chat = Chat.find(params[:id])
  end
end
