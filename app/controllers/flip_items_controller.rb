class FlipItemsController < ApplicationController
  def index
    @pagy, @flip_items = pagy(params[:query].present? ? FlipItem.recent.search(params[:query]) : FlipItem.recent.all)
  end

  def show
    @flip_item = FlipItem.find(params[:id])
  end

  def edit
    @flip_item = FlipItem.find(params[:id])
  end

  def update
    @flip_item = FlipItem.find(params[:id])
    if @flip_item.update(flip_item_params)
      redirect_to @flip_item
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    # Only allow a list of trusted parameters through.
    def flip_item_params
      params.expect(flip_item: [ :title, :content ])
    end
end
