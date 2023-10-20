require 'httparty'
require 'kaminari'


class EditionsController < ApplicationController
  def show
    @confId = params[:conference_id]
    @editionId = params[:id]
    @urls = params[:urls]
    @authors = Hash.new
    @papers = Hash.new
    @urls.each do |url|
      results = getEditionInformation(url.delete_suffix(".html")+".bht")
      if results.present?
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
    #create the array for pagination for both the papers and the authors
    @papers = Kaminari.paginate_array(@papers.to_a).page(params[:paperspage])
    @authors = Kaminari.paginate_array(@authors.to_a).page(params[:authorspage])
  end

  def getEditionInformation(urlVenue)
    informationDblp = HTTParty.get("https://dblp.org/search/publ/api?q=toc:"+urlVenue+":&h=1000&format=json").parsed_response
    informationDblp['result']['hits']['hit']
  end

end
