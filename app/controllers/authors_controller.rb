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
        @authors = @authors.paginate(:page => params[:page], :per_page => 5)
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
    if author.nil?
      redirect_to '/authors'
      return
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

    if @tab == 'collaborations'
      first = false
      @collaborations = author.getCollaborations()
  
      @author['collaborations'] = {}
      @collaborations['data'].each do |year, data|
        year = year.to_s
        if !first
          @year = year
          first = true
        end
        @author['collaborations'][year] ||= []
  
        data.each do |name, details|
          @author['collaborations'][year] << { "name" => name, "pid" => details.keys[0] }
        end
  
        @author['collaborations'][year] = @author['collaborations'][year].paginate(:page => params[:page], :per_page => 5)
      end

      if !params[:year].nil?
        year = params[:year]
        @year = year
      end
    else
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
        end
      end

      if @type == 'all'
        if title != ''
          @author['bibliography'] = Work.joins(:publication, :author)
          .where("publications.title LIKE ?", "%#{title}%")
          .where(authors: { author_id: author.author_id })
          .paginate(page: params[:page], per_page: 10)
        else
          @author['bibliography'] = Work.joins(:publication).where(author_id: author.author_id).select('publications.*').paginate(:page => params[:page], :per_page => 10)
        end
      else
        @author['bibliography'] = Work.joins(:publication, :author)
        .where("publications.title LIKE ?", "%#{title}%")
        .where(authors: { author_id: author.author_id })
        .where(publications: { articleType: @type })
        .paginate(page: params[:page], per_page: 10)
      end
    end
  end
end