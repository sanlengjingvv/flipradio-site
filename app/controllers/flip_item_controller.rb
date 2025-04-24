class FlipItemController < ApplicationController
  def index
    @pagy, @flip_items = pagy(params[:query].present? ? FlipItem.recent.search(params[:query]) : FlipItem.recent.all)
  end

  def show
    @flip_item = FlipItem.find(params[:id])
  end
end
