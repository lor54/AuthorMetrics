class FollowsController < ApplicationController

    def create
        id = params[:author_id]
        author = Author.where(author_id: params[:author_id]).first
        puts author.author_id
        if author.nil?
            flash[:notice] = "Author not found"
            redirect_to author_path(params[:author_id])
        end
        follow = Follow.create(user: current_user, author: author)
        if !follow.nil?
            flash[:notice] = "Successfully followed the author"
        else
            flash[:alert] = "Error following the author"
        end
        redirect_to author_path(params[:author_id])
    end

    def destroy
        follow = current_user.follows.find(params[:id])
        author = follow.author
        follow.destroy
        id = author.author_id
        redirect_to author_path(id)
    end

end
