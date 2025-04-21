class FlipItemController < ApplicationController
  def index
    @flip_items = FlipItem.all
  end

  def show
    @flip_item = FlipItem.find(params[:id])
  end
end
