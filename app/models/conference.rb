class Conference < ApplicationRecord
  has_many :publications, foreign_key: "conference_id"

  def self.queryConference(confId)

  end

  def self.getConferenceInformation(confId)
    starting = 0;
    # we ask for 10k elements as first request (most conferences will give all of their information within this first request)
    numberElements = 10000
    completed = false
    results = Hash.new()
    elemNumber = 0
    until completed
      publicationInfoDblp = HTTParty.get('https://dblp.org/search/publ/api?q=stream:streams/conf/' + confId + ':&h=' + numberElements.to_s + '&f=' + starting.to_s + '&format=json').parsed_response
      #########################################################################
      # this doesn't work, because if they send 0 they put status code 200 OK #
      #if publicationInfoDblp['result']['status']['@code'].to_i != 200        #
      #  return 'There has been an error'                                     #
      #end                                                                    #
      #########################################################################
      #check for correct answer from the API call, if the sent are 0 we return the results
      if publicationInfoDblp['result']['hits']['@sent'].to_i == 0
        return results
      end
      #extraction of publication and population of the hash to return
      for elem in publicationInfoDblp['result']['hits']['hit'] do
        authors = Array.new()
        #population of the array of authors that wrote the paper
        if elem['info']['authors'].nil?
          #if the authors are not present we do nothing
        elsif elem['info']['authors']['author'].is_a?(Array)
          for author in elem['info']['authors']['author'] do
            authors.push(author['@pid'])
          end
        else
          # it is an hash so we can directly extract the information and insert them into the author array
          authors.push(elem['info']['authors']['author']['@pid'])
        end
        information = {'key' => elem['info']['key'], 'title' => elem['info']['title'], 'type' => elem['info']['type'], 'authors' => authors, 'url' => elem['info']['ee'], 'year' => elem['info']['year'] }
        results[elemNumber] = information
        elemNumber = elemNumber + 1
      end
      #check to see if another API call is necessarry because there are more publications to extract
      if publicationInfoDblp['result']['hits']['@total'].to_i == publicationInfoDblp['result']['hits']['@sent'].to_i + publicationInfoDblp['result']['hits']['@first'].to_i
        completed = true
      else
        #get the next thousand records
        starting += numberElement
        numberElement = 1000
      end
    end
    return results
  end

  def self.searchConference(name, maxPerPage, startValue)
    conferenceDblp = HTTParty.get('https://dblp.org/search/venue/api?q='+ name +'&h='+ maxPerPage.to_s + '&f='+ startValue.to_s + '&format=json')
    conferenceDblp.parsed_response
  end

  def self.getConferenceDatabase(conferenceId)
    information = Hash.new()
    conference = Conference.where(:conference_id => conferenceId)[0]
    information['publications'] = conference.publications
    information['name'] = conference.name
    return information
  end
end
