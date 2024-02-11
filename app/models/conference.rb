class Conference < ApplicationRecord
  has_many :publications, foreign_key: "conference_id"

  def self.getConferenceInformation(confId)

    starting = 0;
    numberElements = 1000
    completed = false

    results = Hash.new()
    authorsHash = Hash.new()
    publicationArray = Array.new()

    until completed
      publicationInfoDblp = HTTParty.get('https://dblp.org/search/publ/api?q=stream:streams/conf/' + confId + ':&h=' + numberElements.to_s + '&f=' + starting.to_s + '&format=json').parsed_response
      if publicationInfoDblp['result']['hits']['@sent'].to_i == 0
        return results
      end
      #extraction of publication and population of the hash to return
      for elem in publicationInfoDblp['result']['hits']['hit'] do
        authorsPublication = Hash.new()
        authorsArray = Array.new()
        #population of the array of authors that wrote the paper
        if elem['info']['authors'].nil?
        elsif elem['info']['authors']['author'].is_a?(Array)
          for author in elem['info']['authors']['author'] do
            authorInfo = {'author_id' => author['@pid'], 'name' => author['text']}
            authorsArray.push(authorInfo)
          end
        else
          authorInfo = {'author_id' => elem['info']['authors']['author']['@pid'], 'name' => elem['info']['authors']['author']['text']}
          authorsArray.push(authorInfo)
        end
        authorsHash[elem['info']['key']] = authorsArray
        publicationInfo = {'publication_id' => elem['info']['key'], 'title' => elem['info']['title'], 'articleType' => elem['info']['type'], 'url' => elem['info']['ee'], 'year' => elem['info']['year'] }
        publicationArray.push(publicationInfo)
      end
      #check to see if another API call is necessarry because there are more publications to extract
      if publicationInfoDblp['result']['hits']['@total'].to_i == publicationInfoDblp['result']['hits']['@sent'].to_i + publicationInfoDblp['result']['hits']['@first'].to_i
        completed = true
      else
        #get the next thousand records
        starting += numberElements
      end
    end
    return [publicationArray, authorsHash]
  end

  def self.searchConference(name, maxPerPage, startValue)
    conferenceDblp = HTTParty.get('https://dblp.org/search/venue/api?q='+ name +'&h='+ maxPerPage.to_s + '&f='+ startValue.to_s + '&format=json')
    conferenceDblp.parsed_response
  end

  def self.getConferenceDatabase(conferenceId)
    information = Hash.new()
    authorsList = Array.new()
    years = Array.new()

    # check of existence in the database, if it doesn't insert the information in the database
    if !(Conference.where(:conference_id => conferenceId).exists?)
      #if not existing process information and add the conference papers and authors
      information = Conference.getConferenceInformation(conferenceId)
      conferenceVenue = HTTParty.get("https://dblp.org/db/conf/"+ conferenceId +"/index.xml").parsed_response['bht']['h1']
      conference = Conference.create(conference_id: conferenceId, name: conferenceVenue)
      conference.publications.insert_all(information[0])
      allAuthorsArray = Array.new()
      information[1].values.each do |info|
        info.each do |author|
          allAuthorsArray.push(author)
        end
      end
      Author.create_with(completed: false).insert_all(allAuthorsArray)
      information[1].each do |authors|
        publicationAuthorsIds = Array.new()
        authors[1].each do |author|
          publicationAuthorsIds.push({'author_id' => author['author_id']})
        end
        #authorsList = Author.where('author_id' => publicationAuthorsIds)
        if !(publicationAuthorsIds.empty?)
          Work.create_with(publication_id: authors[0]).insert_all(publicationAuthorsIds)
        end
      end
    #check if the conference information has been updated in the last week, if so skip the update and query the database for the information
    elsif !(Conference.select(:updated_at).where(:conference_id=> conferenceId).first.updated_at <= DateTime.now.utc.end_of_day() - 7)
      information = Conference.getConferenceInformation(conferenceId)
      #implement update of the conference informations
    end
    conference = Conference.where(:conference_id => conferenceId)[0]
  end
end
