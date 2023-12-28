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
    conferenceVenue = params[:venue]
    conferenceAcronym = params[:acronym]
    # check of existence in the database, if it doesn't insert the information in the database
    if !(Conference.where(:conference_id => conferenceId).exists?)
      #if not existing process information and add the conference papers and authors
      information = Conference.getConferenceInformation(conferenceId)
      conference = Conference.create(conference_id: conferenceId, name: conferenceVenue, acronym: conferenceAcronym)
      information.each do |entry|
        p entry
        if !(Publication.where(:publication_id => entry[1].keys[0]).exists?)
          Publication.test
        end
        conference.presented_papers.create(publication: entry[1].keys[0], year: entry[1]['year'])
        entry[1]['authors'].each do |author|
          if !(conference.conference_authors.where(:author => author[0]).exists?)
            conference.conference_authors.create(author: author[0], publication_number: 1)
          else
            author_to_update = conference.conference_authors.select(:publication_number).where(:author => author.key)
            new_publication_numbers = author_to_update.first.publNumber + 1
            author_to_update.update(:publication_number => new_publication_numbers)
          end
        end
      end
    #check if the conference information has been in the last week, if so skip the update and query the database for the information
    elsif !(Conference.select(:updated_at).where(:conference_id=> conferenceId).first.updated_at <= DateTime.now.utc.end_of_day() - 7)
      information = Conference.getConferenceInformation(conferenceId)
      #implement update of the conference informations
    end
  end

end
