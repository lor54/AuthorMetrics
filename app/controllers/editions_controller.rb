class EditionsController < ApplicationController
  def show
    @confId = params[:id]
    @editionId = params[:edition]
  end
end
