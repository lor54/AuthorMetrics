require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:user) { FactoryBot.create(:user) }

  describe "GET /show" do
    it "returns http success" do

      sign_in user

      get user_path(user.id)
      expect(response).to have_http_status(:success)
    end
  end

end
