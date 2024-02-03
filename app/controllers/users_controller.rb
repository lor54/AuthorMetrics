class UsersController < ApplicationController
  before_action :authenticate_user!
  
  def show
    if current_user.id.to_i != params[:id].to_i
      redirect_to root_path
    end
  end

  def author_followed
    render turbo_stream:
      turbo_stream.replace("followed_authors_frame", partial: "users/followed_authors")
  end
end
