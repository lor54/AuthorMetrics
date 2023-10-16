class UsersController < ApplicationController
  def show
    @follow = current_user.authors.all
  end
end
