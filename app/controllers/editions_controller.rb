require 'httparty'
require 'kaminari'


class EditionsController < ApplicationController
  def show
    @confId = params[:conference_id]
    @editionId = params[:id]
    @urls = params[:urls]
    @authors
    @papers
    if (@authors.nil? && @papers.nil?)
      #populate the authors and papers hashes with the information
      p "entro nella richiesta"
      @urls.each do |url|
        results = getEditionInformation(url.delete_suffix(".html")+".bht")
        if results.present?
          @papers = Hash.new
          @authors = Hash.new
          results.each do |hit|
            @papers[hit['info']['ee']] = hit['info']['title']
            if hit['info']['authors'] == nil
              next
            end
            authorsInfo = hit['info']['authors']['author']
            if authorsInfo.is_a?(Array)
              authorsInfo.each do |author|
                if !(@authors.has_key?(author['@pid']))
                  @authors[author['@pid']] = author['text']
                end
              end
            elsif authorsInfo.is_a?(Hash)
              if (@authors.has_key?(authorsInfo['@pid']))
                @authors[authorsInfo['@pid']] = authorsInfo['text']
              end
            end
          end
        end
      end
      #create the array for pagination for both the papers and the authors and returns the first page for the pagination
      @papers = Kaminari.paginate_array(@papers.to_a).page(1)
      @authors = Kaminari.paginate_array(@authors.to_a).page(1)
    else
      #returns the requested page for pagination
      @papers = Kaminari.paginate_array(@papers.to_a).page(params[:paperspage])
      @authors = Kaminari.paginate_array(@authors.to_a).page(params[:authorspage])
    end
  end

  def getEditionInformation(urlVenue)
    informationDblp = HTTParty.get("https://dblp.org/search/publ/api?q=toc:"+urlVenue+":&h=1000&format=json").parsed_response
    informationDblp['result']['hits']['hit']
  end

end
