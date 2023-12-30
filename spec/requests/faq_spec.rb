require 'rails_helper'

RSpec.describe "Faq", type: :request do
  describe "GET /faq" do
    it "returns http success" do
      get "/faq"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /faq/:subfolder/:file_name" do
    it "returns http success" do
      file_name = "What_is_AuthorMetrics"
      subfolder = "about"
      path = "/faq/#{subfolder}/#{file_name}"
      get path
      expect(response).to have_http_status(:success)
    end

    it "renders the 'show' template" do
      file_name = "What_is_AuthorMetrics"
      subfolder = "about"
      path = "/faq/#{subfolder}/#{file_name}"
      get path
      expect(response).to render_template(:show)
    end
    
  end
end
