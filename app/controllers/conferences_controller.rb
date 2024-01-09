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

    @types = [ 'all', 'article', 'inproceedings', 'proceedings', 'book', 'incollection' ]
    conferenceId = params[:id] || 0
    title = params[:title] || ''
    @type = params[:type] || 'all'
    if !@types.include? (@type)
      @type = 'all'
    end

    #we extract the information from the database
    conference = Conference.getConferenceDatabase(conferenceId)

    @conference = Hash.new()
    @conference['name'] = conference.name

    authorsList = Array.new()
    years = Array.new()

    conference.publications.each do |publication|
      publication.authors.each do |author|
        if !(authorsList.include?(author.name))
          authorsList.push(author.name)
        end
      end
      if !(years.include?(publication.year))
        years.push(publication.year)
      end
    end
    @conference['years'] = years
    @conference['authors'] = authorsList.paginate(page: params[:author_page], per_page: 20)

    if @type = 'all'
      if title != ''
        @conference['publications'] = conference.publications
        .where("publications.title Like ?", "%#{title}%")
        .paginate(page: params[:page], per_page: 10)
      else
        @conference['publications'] = conference.publications.paginate(page: params[:publ_page], per_page: 10)
      end
    else
      if title != ''
        @conference['publications'] = conference.publications
        .where("publications.title Like ?", "%#{title}%")
        .where(publications: {article_type: @type})
        .paginate(page: params[:page], per_page: 10)
      else
        @conference['publications'] = conference.publications
        .where(publications: {article_type: @type})
        .paginate(page: params[:page], per_page: 10)
      end
    end
    p @conference['publications']
  end
end
