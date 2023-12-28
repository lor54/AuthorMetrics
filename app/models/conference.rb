class Conference < ApplicationRecord
  has_many :presented_papers
  has_many :publications, :through => :presented_papers, foreign_key: "publication_id"
  has_many :conference_authors
  has_many :authors, :through => :conference_authors, foreign_key: "author_id"


  def self.queryConference(confId)
    
  end

  def self.getConferenceInformation(confId)
    starting = 0;
    completed = false
    results = Hash.new()
    elemNumber = 0
    until completed
      publicationInfoDblp = HTTParty.get('https://dblp.org/search/publ/api?q=stream:streams/conf/' + confId + ':&h=1000&f=' + starting.to_s + '&format=json').parsed_response
      #check for correct answer from the API call
      if publicationInfoDblp['result']['status']['@code'].to_i != 200
        return 'There has been an error'
      end
      #extraction of publication and population of the hash to return
      for elem in publicationInfoDblp['result']['hits']['hit'] do
        authors = Hash.new()
        #population of the array of authors that wrote the paper where the key is their PID and the value is their name
        if elem['info']['authors']['author'].is_a?(Array)
          for author in elem['info']['authors']['author'] do
            authors[author['@pid']] = author['text']
          end
        else
          # it is an hash so we can directly extract the information and insert them into the main hash
          authors[elem['info']['authors']['author']['@pid']] = elem['info']['authors']['author']['text']
        end
        # elem['info']['key'] is a temporary dummy value (could not be unique) we need to find something for it
        information = {elem['info']['key'].split('/').last => elem['info']['title'], 'authors' => authors, 'url' => elem['info']['ee'], 'year' => elem['info']['year'] }
        results[elemNumber] = information
        elemNumber = elemNumber + 1
      end
      #check to see if another API call is necessarry because there are more publications to extract
      if publicationInfoDblp['result']['hits']['@total'].to_i == publicationInfoDblp['result']['hits']['@sent'].to_i + starting
        completed = true
      else
        starting = publicationInfoDblp['result']['hits']['@sent'].to_i
      end
    end
    return results
  end

  def self.searchConference(name, maxPerPage, startValue)
    conferenceDblp = HTTParty.get('https://dblp.org/search/venue/api?q='+ name +'&h='+ maxPerPage.to_s + '&f='+ startValue.to_s + '&format=json')
    conferenceDblp.parsed_response
  end

end
