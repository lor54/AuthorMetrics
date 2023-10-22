class FollowsController < ApplicationController

    def create
        code = params[:author_id]
        id = code.delete('/').to_i
        author = Author.find_by(authorid: id)
        if author.nil?
            author = Author.create(authorid: id, name: params[:name])
        end
        @follow = Follow.new(user: current_user, author: author)
        if !@follow.save
            flash[:notice] = @follow.errors.full_message.to_sentence
        end
        redirect_to author_path(params[:author_id])
    end

    def destroy
        @follow = current_user.follows.find(params[:id])
        author = @follow.author
        @follow.destroy
        id = author.authorid.to_s.insert(-5, '/')
        redirect_to author_path(id)
    end

end
