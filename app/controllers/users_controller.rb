class UsersController < ApplicationController
  before_action :authenticate_user!
  
  def show
  end

  def author_followed
    render turbo_stream:
      turbo_stream.replace("followed_authors_frame", partial: "users/followed_authors")
  end
end
