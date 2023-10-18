require 'rails_helper'

RSpec.describe "Editions", type: :request do
  describe "GET /show" do
    it "returns http success" do
      get "/editions/show"
      expect(response).to have_http_status(:success)
    end
  end

end
