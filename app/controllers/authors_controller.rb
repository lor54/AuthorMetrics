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
    pid = params[:id] || 0
    authorresponse = getAuthorBibliography(pid)

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
    @author['pid'] = pid
    bibliography = authorresponse['dblpperson']['r']

    @author['bibliography'] = {}
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
                element['author'] = [{'__content__' => author[1]}]
              end
            end
          }

          if @author['orcid'].empty?
            if element['author'].is_a?(Array)
              element['author'].each do |pubAuthor|
                if pubAuthor.is_a?(Hash)
                  if pubAuthor['pid'].present? && pid == pubAuthor['pid'] && pubAuthor['orcid'].present? && pubAuthor['orcid'].is_a?(String)
                    @author['orcid'] = pubAuthor['orcid']
                    @author['orcidStatus'] = 'unverified' 
                  end
                end
              end
            end
            #@author['orcid'] = element['author']['orcid']
          end
        end
        @author['bibliography'][element['year']].push(element)
      end
    end unless bibliography.nil?

    if @author['orcid'].include? "https://orcid.org/"
      @author['orcid'].slice! "https://orcid.org/"
    end
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
