class FaqController < ApplicationController
  def index
    @faq_files = Dir.glob("#{Rails.root}/public/faq_files/*.html.erb").map { |file| File.basename(file, ".html.erb") }
  end

  def show
    file_path = File.join(Rails.root, 'public', 'faq_files', params[:file_name] + '.html.erb')
    @content = File.read(file_path)

    respond_to do |format|
      format.html
    end
  end
end
