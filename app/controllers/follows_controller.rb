class FollowsController < ApplicationController

    def create
        @follow = current_user.follows.new(follow_params)
        if !@follow.save
            flash[:notice] = @follow.errors.full_message.to_sentence
        end
        redirect_to authors_path(name: params[:name])
    end

    def destroy
        @follow = current_user.follows.find(params[:id])
        author = @follow.author
        @like.destroy
        redirect_to author
    end

    private

    def follow_params
        params.require(:follow).permit(:author_id)
    end

end
