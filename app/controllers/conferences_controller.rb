require 'httparty'

class ConferencesController < ApplicationController
  def index
    @conferences = Array.new()
    @pages = 0
    @beginPages = 1
    @endPages = 1
    @maxResultPages = 5
    @page = 1
    if params[:name] && params[:name] != ""
      perPage = 30
      @page = params[:page].to_i > 0 ? params[:page].to_i : 1

      conferencesResponse = Conference.searchConference(params[:name], perPage, (@page-1)*perPage)

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
        #remove all the result that are not conferences or workshops
        venueResult = conferencesResponse['result']['hits']['hit']
        if venueResult.present?
          venueResult.each do |element|
            if element['info']['type'] == 'Conference or Workshop'
              #populate the information hash to insert in the conferences search result array
              information = {'venue'=> element['info']['venue'], 'acronym' => element['info']['acronym'], 'accessId' => element['info']['url'].delete_prefix('https://dblp.org/db/conf/').delete_suffix('/')}
              @conferences.push(information)
            end
          end
        end
      end
    end
  end

  def show
    conferenceId = params[:id]
    # check of existence in the database, if it doesn't insert the information in the database
    if !(Conference.where(:conference_id => conferenceId).exists?)
      #if not existing process information and add the conference papers and authors
      information = Conference.getConferenceInformation(conferenceId)
      conferenceVenue = HTTParty.get("https://dblp.org/db/conf/"+ conferenceId +"/index.xml").parsed_response['bht']['h1']
      conference = Conference.create(conference_id: conferenceId, name: conferenceVenue)
      information.each do |entry|
        #if th publication doesn't exist in the database we insert it and use it for the paper information
        if !(Publication.where(:publication_id => entry[1]['key']).exists?)
          publication = conference.publications.create(publication_id: entry[1]['key'], title: entry[1]['title'], articleType: entry[1]['type'] , url: entry[1]['url'], releaseDate: entry[1]['year'], conference_id: conference.conference_id)
        else
          publication = Publication.where(:publication_id => entry[1]['key'])
          if(publication.conference_id.is_nil?)
            publication = Publication.update(:conference_id => conference.conference_id)
          end
        end
        #if !(entry[1]['authors'].empty?)
        #  entry[1]['authors'].each do |author|
        #    #dovrebbe salvare gli autori nel database da vedere se lo fa
        #    Author.getAuthorData(author)
        #  end
        #end
      end
    #check if the conference information has been in the last week, if so skip the update and query the database for the information
    elsif !(Conference.select(:updated_at).where(:conference_id=> conferenceId).first.updated_at <= DateTime.now.utc.end_of_day() - 7)
      information = Conference.getConferenceInformation(conferenceId)
      #implement update of the conference informations
    end
    #we extract the information from the database
    @information = Conference.getConferenceDatabase(conferenceId)
  end

end
