require 'httparty'

class AuthorsController < ApplicationController
  def index
    @authors = []
    @pages = 0
    @maxPages = 0
    @beginPages = 1

    if params[:search_by_name] && params[:search_by_name] != ""
      page = params[:page] || 1
      perPage = 30

      authorsresponse = searchAuthor(params[:search_by_name], perPage)
      if authorsresponse['result']['status']['@code'] == '200'
        @pages = authorsresponse['result']['hits']['@total'].to_i / authorsresponse['result']['hits']['@sent'].to_i
        @maxPages = @pages
        #@maxPages = @pages > 5 ? 5 : @pages
        @authors = authorsresponse['result']['hits']['hit'] 
      end
    end
  end
  
  def show
    authorresponse = getAuthorBibliography(params[:id])

    @author = {}
    @author['name'] = authorresponse['dblpperson']['name']  
    bibliography = authorresponse['dblpperson']['r']

    @author['bibliography'] = {}
    bibliography.each do |element|
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
            puts element['author']
          end
        }
      end
      
      @author['bibliography'][element['year']].push(element)
    end
  end

  def getAuthorBibliography(pid)
    authordblp = HTTParty.get('https://dblp.org/pid/' + pid + '.xml')
    authordblp.parsed_response
  end

  def searchAuthor(name, maxPerPage)
    authordblp = HTTParty.get('https://dblp.org/search/author/api?q=' + name + '&h=' + maxPerPage.to_s + '&format=json')
    authordblp.parsed_response
  end
end
