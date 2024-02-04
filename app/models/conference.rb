class Conference < ApplicationRecord
  has_many :publications, foreign_key: "conference_id"

  def self.queryConference(confId)

  end

  def self.getConferenceInformation(confId)
    starting = 0;
    numberElements = 1000
    completed = false
    results = Hash.new()
    elemNumber = 0
    until completed
      publicationInfoDblp = HTTParty.get('https://dblp.org/search/publ/api?q=stream:streams/conf/' + confId + ':&h=' + numberElements.to_s + '&f=' + starting.to_s + '&format=json').parsed_response
      if publicationInfoDblp['result']['hits']['@sent'].to_i == 0
        return results
      end
      #extraction of publication and population of the hash to return
      for elem in publicationInfoDblp['result']['hits']['hit'] do
        authors = Hash.new()
        #population of the array of authors that wrote the paper
        if elem['info']['authors'].nil?
          #if the authors are not present we do nothing
        elsif elem['info']['authors']['author'].is_a?(Array)
          for author in elem['info']['authors']['author'] do
            authors[author['@pid']] = author['text']
          end
        else
          # it is an hash so we can directly extract the information and insert them into the author array
          authors[elem['info']['authors']['author']['@pid']]=elem['info']['authors']['author']['text']
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
        starting += numberElements
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
    authorsList = Array.new()
    years = Array.new()

    # check of existence in the database, if it doesn't insert the information in the database
    if !(Conference.where(:conference_id => conferenceId).exists?)
      #if not existing process information and add the conference papers and authors
      information = Conference.getConferenceInformation(conferenceId)
      conferenceVenue = HTTParty.get("https://dblp.org/db/conf/"+ conferenceId +"/index.xml").parsed_response['bht']['h1']
      conference = Conference.create(conference_id: conferenceId, name: conferenceVenue)
      information.each do |entry|
        #if the publication doesn't exist in the database we insert it and use it for the paper information
        if !(Publication.where(:publication_id => entry[1]['key']).exists?)
          publication = conference.publications.create(publication_id: entry[1]['key'], title: entry[1]['title'], articleType: entry[1]['type'] , url: entry[1]['url'], year: entry[1]['year'], conference_id: conference.conference_id)
        else
          publication = Publication.find_by(:publication_id => entry[1]['key'])
          if !(publication.present?)
            publication = Publication.update(:conference_id => conference.conference_id)
          end
        end
        if !(entry[1]['authors'].empty?)
          entry[1]['authors'].each do |author|
            #search for the author if it already exists if it doesn't we create it
            testAuthor = Author.find_by(author_id: author[0])
              if !(testAuthor.present?)
              testAuthor = Author.create(author_id: author[0], name: author[1], completed: false )
            end
            testAuthor.publications << publication
          end
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
