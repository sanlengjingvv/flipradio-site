class FlipItemsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :update ]
  skip_before_action :require_authentication, except: [ :update ]

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
    respond_to do |format|
      if @flip_item.update(flip_item_params)
        format.html { redirect_to @flip_item, notice: "flip_item was successfully updated." }
        format.json { render :show, status: :ok, location: @flip_item }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @flip_item.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Only allow a list of trusted parameters through.
    def flip_item_params
      params.expect(flip_item: [ :title, :content ])
    end
end
