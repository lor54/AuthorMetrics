require 'httparty'

class AuthorsController < ApplicationController
  def index
    @authors = []
    @pages = 0
    @beginPages = 1
    @endPages = 1
    @maxResultPages = 5
    @page = 1

    if params[:name] && params[:name] != ""
      perPage = 30
      @page = params[:page].to_i > 0 ? params[:page].to_i : 1

      authorsresponse = Author.searchAuthor(params[:name], perPage, (@page - 1)*perPage)

      if authorsresponse['result']['status']['@code'] == '200'
        results = authorsresponse['result']['hits']['@sent'].to_i
        @pages = results > 0 ? authorsresponse['result']['hits']['@total'].to_i / results : 0
        if @pages <= 0
          @endPages = @page
        end

        if params[:page].to_i <= @pages
          @page = params[:page].to_i
        else
          redirect_to authors_path(name: params[:name], page: 1)
        end

        @beginPages = @page - @maxResultPages + 1 >= 1 ? @page - @maxResultPages + 1 : 1
        @endPages = @beginPages == 1 ? 5 : @page

        @authors = authorsresponse['result']['hits']['hit']
      end
    end
  end

  def show
    @types = [ "all", "article", "inproceedings", "proceedings", "book", "incollection" ]
    @pid = params[:id] || 0
    @tab = params[:tab] || ''
    title = params[:title] || ''
    @type = params[:type] || 'all'
    if !@types.include? (@type)
      @type = 'all'
    end

    if(@tab != '' && @tab != 'publications' && @tab != 'collaborations')
      redirect_to helpers.authorPath(@pid, '')
    end

    if(@tab == '')
      @tab = 'publications'
    end

    @author = {}
    @author['bibliography'] = {}

    author = Author.getAuthor(@pid)

    if @tab == 'collaborations'
      loadColaborations(author)
    end

    @author['name'] = author.name
    @author['orcid'] = author.orcid
    @author['orcidStatus'] = author.orcidStatus
    @author['h_index'] = author.h_index
    @author['citationNumber'] = author.citationNumber
    @author['last_known_institution'] = author.last_known_institution
    @author['last_known_institution_type'] = author.last_known_institution_type
    @author['last_known_institution_countrycode'] = author.last_known_institution_countrycode
    @author['works_by_year'] = author.getWorksCountByYear()
    @author['works_count'] = author.getWorksCount()
    @author['citations_counts_by_year'] = author.getCitationsCountByYear()
    @author['bibliography_types'] = author.getBibliographyTypes()
    @author['works_source'] = author.getWorksSource()
    @author['bibliography_types_peryear'] = author.getBibliographyTypesPerYear()
    
    if author.orcid.nil? || author.orcid == ''
      @author['citationNumber'] = 'unavailable'
      @author['works_count'] = 'unavailable'
      @author['h_index'] = 'unavailable'
      @author['last_known_institution'] = 'unavailable'
      @author['last_known_institution_type'] = 'unavailable'
      @author['last_known_institution_countrycode'] = 'unavailable'
      @author['counts_by_year'] = {}
      @author['works_by_year'] = {}
      @author['citations_counts_by_year'] = {}
    end

    works = author.getWorks()
    works.each do |work|
      if !work.publication.nil?
        pub = work.publication
        otherAuthors = Work
        .joins(:author)
        .where(publication_id: pub.id)
        .where.not(author_id: author.id)
        .distinct
        .pluck('authors.author_id', 'authors.name')
        .map { |author_id, name| { 'pid' => author_id, '__content__' => name } }
        atrr = pub.attributes
        atrr['author'] = otherAuthors

        if @type == 'all' || @type == pub.articleType # Research by type
          if title == '' || pub.title.downcase.include?(title.downcase) # Research by title
            if !@author['bibliography'].has_key? (pub.year)
              @author['bibliography'][pub.year] = []
            end
            
            @author['bibliography'][pub.year].push(atrr)
          end
        end
      end
    end
  end

  def loadColaborations(author)
    @collaborations = author.getCollaborations()
  end
end
