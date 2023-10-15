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

      authorsresponse = searchAuthor(params[:name], perPage, (@page - 1)*perPage)

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
    @pid = params[:id] || 0
    @tab = params[:tab] || ''

    if(@tab != '' && @tab != 'publications' && @tab != 'collaborations')
      redirect_to helpers.authorPath(@pid, '')
    end

    if(@tab == '')
      @tab = 'publications'
    end

    authorresponse = getAuthorBibliography(@pid)

    @author = {}
    @author['orcid'] = ''
    @author['orcidStatus'] = 'none'
    urls = authorresponse['dblpperson']['person']['url']
    if urls.present?
      if urls.is_a?(Array)
        authorresponse['dblpperson']['person']['url'].each do |url|
          if url.include? 'orcid'
            @author['orcid'] = url
            @author['orcidStatus'] = 'verified'
            break
          end
        end
      elsif urls.is_a?(String)
        @author['orcid'] = urls
        @author['orcidStatus'] = 'verified'
      end
    end

    @author['name'] = authorresponse['dblpperson']['name']
    @author['pid'] = @pid
    bibliography = authorresponse['dblpperson']['r']

    @author['bibliography'] = {}
    if bibliography.is_a?(Hash)
      bibliography = [bibliography]
    end

    bibliography.each do |element|
      if element.is_a?(Hash)
        elementType = element.keys[0]
        element = element[element.keys[0]]
        element['type'] = elementType

        if !@author['bibliography'].key?(element['year'])
          @author['bibliography'][element['year']] = []
        end

        if element['author']
          element['author'].collect{ |author|
            if author.is_a?(Array)
              if author[0] == '__content__'
                auth = [{'__content__' => author[1]}]

                if author[2] == 'pid'
                  auth[0]['pid'] = author[3]
                end

                element['author'] = auth
              end
            end
          }
        elsif element['editor']
          element['editor'].collect{ |author|
            if author.is_a?(Array)
              if author[0] == '__content__'
                auth = [{'__content__' => author[1]}]

                if author[2] == 'pid'
                  auth[0]['pid'] = author[3]
                end

                element['author'] = auth
              end
            else
              element['author'] = element['editor']
            end
          }
        end

        if @author['orcid'].empty?
          if element['author'].is_a?(Array)
            element['author'].each do |pubAuthor|
              if pubAuthor.is_a?(Hash)
                if pubAuthor['pid'].present? && @pid == pubAuthor['pid'] && pubAuthor['orcid'].present? && pubAuthor['orcid'].is_a?(String)
                  @author['orcid'] = pubAuthor['orcid']
                  @author['orcidStatus'] = 'unverified'
                end
              end
            end
          end
        end
        @author['bibliography'][element['year']].push(element)
      end
    end unless bibliography.nil?

    if @tab == 'collaborations'
      loadColaborations()
    end

    if @author['orcid'].include? "https://orcid.org/"
      @author['orcid'].slice! "https://orcid.org/"
    end

    if @author['orcid'] != ''
      getExtraInformation()
    else
      @author['citationNumber'] = 'unavailable'
      @author['works_count'] = 'unavailable'
      @author['h_index'] = 'unavailable'
      @author['last_known_institution'] = 'unavailable'
      @author['last_known_institution_type'] = 'unavailable'
      @author['last_known_institution_countrycode'] = 'unavailable'
      @author['counts_by_year'] = {}
    end
  end

  def loadColaborations()
    @collaborations = {}
    @collaborations['number'] = {}
    @collaborations['data'] = {}
    @author['bibliography'].each do |year, authors|
      @collaborations['data'][year] = {}
      authors.each do |element|
        if element['author']
          element['author'].collect{ |author|
            if author.is_a?(Array)
              if author[0] == '__content__'
                auth = [{'__content__' => author[1]}]

                if author[2] == 'pid'
                  auth[0]['pid'] = author[3]
                end

                element['author'] = auth
              end
            end

            content_key = author["__content__"]
            pid_key = author["pid"]

            next if content_key == @author['name'] && (pid_key == @author['pid'] || pid_key.nil?)

            @collaborations['data'][year][content_key] ||= {}
            @collaborations['data'][year][content_key][pid_key] ||= {}
            @collaborations['data'][year][content_key][pid_key]['pid'] ||= pid_key

            if @collaborations['data'][year][content_key][pid_key].key?('count')
              @collaborations['data'][year][content_key][pid_key]['count'] += 1
            else
              @collaborations['data'][year][content_key][pid_key]['count'] = 1
            end
          }
        end
      end
    end

    total_sum = {}
    #@collaborations['data'].each do |year, year_data|
    #  year_data.each do |name, name_data|
    #    name_data.each do |pid, count|
    #      total_sum[name] ||= {}
    #      total_sum[name][pid] ||= 0
    #      total_sum[name][pid] += count
    #    end
    #  end
    #end
    @collaborations['data'].each do |year, year_data|
      year_data.each do |name, name_data|
        name_data.each do |pid, data|
          count = data['count']
          if total_sum.key?(year)
            total_sum[year] += count
          else
            total_sum[year] = count
          end
        end
      end
    end

    @collaborations["number"] = total_sum
  end

  def getExtraInformation()
    extraInformation = HTTParty.get('https://api.openalex.org/authors/https://orcid.org/' + @author['orcid'])
      extraInformation = extraInformation.parsed_response

      @author['citationNumber'] = extraInformation['cited_by_count']
      @author['h_index'] = extraInformation['summary_stats']['h_index']
      @author['last_known_institution'] = extraInformation['last_known_institution']['display_name']
      @author['last_known_institution_type'] = extraInformation['last_known_institution']['type']
      @author['last_known_institution_countrycode'] = extraInformation['last_known_institution']['country_code']
      citations_counts_by_year = {}

      extraInformation['counts_by_year'].each do |yearData|
        year = yearData['year'].to_s
        if !citations_counts_by_year.has_key? (year)
          citations_counts_by_year[year] = 0
        end

        citations_counts_by_year[year] += yearData['cited_by_count']
      end
      @author['citations_counts_by_year'] = citations_counts_by_year

      @author['works_count'] = 0
      works_counts_by_year = {}      
      @author['bibliography'].each do |year, array|
        if !works_counts_by_year.has_key? (year)
          works_counts_by_year[year] = 0
        end

        works_counts_by_year[year] += array.length
        @author['works_count'] += works_counts_by_year[year]
      end
      @author['works_by_year'] = works_counts_by_year 
  end

  def getAuthorInformations(orcid)
    authoralex = HTTParty.get('https://api.openalex.org/authors/https://orcid.org/' + orcid)
  end

  def getAuthorBibliography(pid)
    authordblp = HTTParty.get('https://dblp.org/pid/' + pid + '.xml')
    authordblp.parsed_response
  end

  def searchAuthor(name, maxPerPage, startValue)
    authordblp = HTTParty.get('https://dblp.org/search/author/api?q=' + name + '&h=' + maxPerPage.to_s + '&f=' + startValue.to_s + '&format=json')
    authordblp.parsed_response
  end
end
