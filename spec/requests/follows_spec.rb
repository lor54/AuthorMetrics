require 'rails_helper'

RSpec.describe FollowsController, type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:author) { FactoryBot.create(:author) }

  describe 'POST /follows' do
    it 'creates a follow relationship' do
      sign_in user

      post  author_follows_path(author)
      expect(response).to redirect_to(author_path(author))
      follow = Follow.last
      expect(follow.user).to eq(user)
      expect(follow.author).to eq(author)
      expect(flash[:notice]).to eq("Successfully followed " + author.name)
    end

    it 'requires authentication to create a follow relationship' do
      post author_follows_path(author)
      expect(response).to redirect_to(new_user_session_path) 
    end

    it 'handles the case where the author does not exist when creating a follow relationship' do
      sign_in user
      post author_follows_path('non_existent_author_id')
      expect(response).to redirect_to(authors_path)
      expect(flash[:notice]).to eq('Author not found')
    end

    it 'does not allow a user to follow the same author multiple times' do
      sign_in user
      create(:follow, user: user, author: author)
    
      post author_follows_path(author)
      expect(response).to redirect_to(author_path(author))
      expect(flash[:alert]).to eq('You are already following ' + author.name)
    end
    
  end

  describe 'DELETE /follows/:id' do
    it 'destroys a follow relationship' do
      follow = create(:follow, user: user, author: author)

      sign_in user

      delete follow_path(follow)
      expect(response).to redirect_to(author_path(author))
      expect(Follow.find_by(id: follow.id)).to be_nil
    end

    it 'requires authentication to destroy a follow relationship' do
      delete follow_path(create(:follow, user: user, author: author))
      expect(response).to redirect_to(new_user_session_path)
    end

  end
end
