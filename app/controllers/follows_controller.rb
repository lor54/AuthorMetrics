class FollowsController < ApplicationController

    def create
        author = Author.find(params[:author_id])
        @follow = Follow.new(user_id: current_user.id,
                                author_id: author.authorid )
        @follow.save
        redirect_to author_path(@author)
    end

    def destroy
    end

end
