class FollowsController < ApplicationController
    before_action :authenticate_user!

    def create
        id = params[:author_id]
        author = Author.where(author_id: params[:author_id]).first
        if author.nil?
            flash[:alert] = "Author not found"
            redirect_to authors_path
        else
            follow = Follow.where(user: current_user, author: author).first
            if !follow.nil?
                flash[:alert] = "You are already following " + author.name
            else
                follow = Follow.create(user: current_user, author: author)
                flash[:notice] = "Successfully followed " + author.name
            end
            redirect_to author_path(params[:author_id])
        end
    end

    def destroy
        follow = current_user.follows.find(params[:id])
        author = follow.author
        follow.destroy
        id = author.author_id
        flash[:notice] = "Successfully unfollowed " + author.name
        redirect_to author_path(id)
    end

end
