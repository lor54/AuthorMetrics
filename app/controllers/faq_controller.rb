class FaqController < ApplicationController
  def index
    @faq_files = Dir.glob("#{Rails.root}/public/faq_files/**/*.html.erb").map { |file| File.basename(file, ".html.erb") }
  
    @file_paths = {}
  
    Dir.glob("#{Rails.root}/public/faq_files/**/*.html.erb").each do |file|
      file_name = File.basename(file, ".html.erb")
      @file_paths[file_name] = file
    end
  end
  

  def show
    file_name = params[:file_name]
    file_path = File.join(Rails.root, 'public', 'faq_files', "#{params[:subfolder]}/#{file_name}.html.erb")
    @content = File.read(file_path)
  
    respond_to do |format|
      format.html
    end
  end

end
