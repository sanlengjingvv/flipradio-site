class FlipItemController < ApplicationController
  def index
    @flip_items = FlipItem.recent.all
    @pagy, @flip_items = pagy(@flip_items)
  end

  def show
    @flip_item = FlipItem.find(params[:id])
  end
end
