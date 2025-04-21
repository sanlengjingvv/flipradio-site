class FlipItemController < ApplicationController
  def index
    @flip_items = FlipItem.all
  end
end
