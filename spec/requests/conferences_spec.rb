require 'rails_helper'

RSpec.describe "Conferences", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/conferences"
      expect(response).to have_http_status(:success)
    end
  end

end
