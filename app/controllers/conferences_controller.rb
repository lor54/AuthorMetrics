require 'httparty'

class ConferencesController < ApplicationController
  def index
    @conferences = []
    @pages = 0
    @beginPages = 1
    @endPages = 1
    @maxResultPages = 5
    @page = 1
    if params[:name] && params[:name] != ""
      perPage = 30
      @page = params[:page].to_i > 0 ? params[:page].to_i : 1

      conferencesResponse = searchConference(params[:name], perPage, (@page-1)*perPage)

      if conferencesResponse['result']['status']['@code'] == '200'
        results = conferencesResponse['result']['hits']['@sent'].to_i
        @pages = results > 0 ? conferencesResponse['result']['hits']['@total'].to_i / results : 0
        if @pages <= 0
          @endPages = @page
        end

        if params[:page].to_i <= @pages
          @page = params[:page].to_i
        else
          redirect_to conferences_path(name: params[:name], page: 1)
        end
        @beginPages = @page - @maxResultPages + 1 >= 1 ? @page - @maxResultPages + 1 : 1
        @endPages = @beginPages == 1 ? 5 : @page
        #remove all the result that are not conferences and workshops
        venueResult = conferencesResponse['result']['hits']['hit']
        if venueResult.present?
          venueResult.each do |element|
            if element['info']['type'] == 'Conference or Workshop'
              @conferences.push(element)
            end
          end
        end
      end
    end
  end

  def show
    @confId = params[:id] || 0
    if Conference.exists?(confId: @confId)
      p "esiste"
    else
      conferencesResponse = getConferenceInformation(@confId)
      @conference = {}
      @conference['name'] = conferencesResponse['bht']['h1']
      @conference['editions'] = Hash.new
      @conference['urlInfo'] = nil
      #Extrapolate all the editions of the conferences in an array
      conferenceEditions = conferencesResponse['bht']['h2']
      editionsInformation = conferencesResponse['bht']['dblpcites']
      if conferenceEditions.present?
        if conferenceEditions.is_a?(Array)
          length = conferenceEditions.length()
          for elem in 0..length-1 do
            edition_name = conferenceEditions[elem].split(':')[0]
            url_papers = []
            if editionsInformation[elem] != nil
              editionsInformation[elem]['r'].each do |r|
                if r.is_a?(Hash)
                  url_papers.push(r['proceedings']['url'])
                elsif r.is_a?(Array)
                  if r[0] == "proceedings"
                    url_papers.push(r[1]['url'])
                  end
                end
                if url_papers.length != 0
                  @conference['editions'][edition_name] = url_papers
                end
              end
            end
          end
          @conference['editions'][edition_name]
        elsif conferenceEditions.is_a?(String)
          edition_name = conferenceEditions.split(':')[0]
          @conference['editions'][edition_name] = 0
        end
      end
      #Conference.create(confId: @confId, name: conference[Name])
    end
  end

  def getConferenceInformation(confId)
    conferenceDblp = HTTParty.get('https://dblp.org/db/conf/' + confId + '/index.xml')
    conferenceDblp.parsed_response
  end

  def getEditionInformation(editionId,confId)
    editionDblp = HTTParty.get('https://dblp.org/db/conf/conf/' + confId + '/' + editionId + '/index.xml')
    editionDblp.parsed_response
  end

  def searchConference(name, maxPerPage, startValue)
    conferenceDblp = HTTParty.get('https://dblp.org/search/venue/api?q='+ name +'&h='+ maxPerPage.to_s + '&f='+ startValue.to_s + '&format=json')
    conferenceDblp.parsed_response
  end
end
