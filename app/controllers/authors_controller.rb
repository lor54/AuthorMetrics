require 'httparty'

class AuthorsController < ApplicationController
  def index
    @authors = Author.all
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
      @author['bibliography'][element['year']].push(element)
    end
  end

  def getAuthorBibliography(pid)
    authordblp = HTTParty.get('https://dblp.org/pid/' + pid + '.xml')
    authordblp.parsed_response
  end
end
