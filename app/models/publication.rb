class Publication < ApplicationRecord
    self.primary_key = :publication_id
    has_many :works, foreign_key: :publication_id, primary_key: :publication_id
    has_many :authors, through: :works
    belongs_to :conference, foreign_key: "conference_id", optional: true


    def self.getPublicationInformation(key)
        completed = true
        if Publication.exists?(key)
            if Publication.find_by(publication_id: key).completed == false
                completed = false
            end
        end

        if !Publication.exists?(key) || !completed
            publicationdblp = HTTParty.get('https://dblp.org/rec/' + key + '.xml')
            publicationData = publicationdblp.parsed_response
            if !publicationData['dblp'].nil?
                publicationData = publicationData['dblp']

                publication = {}
                publication['doi'] = ""

                if publicationData.is_a?(Hash)
                    publication['type'] = publicationData.keys[0]
                    publication['data'] = publicationData[publication['type']]

                    if publication['data']['ee'].is_a? (Hash)
                        if publication['data']['ee']['__content__'].include? "https://doi.org/"
                            doi = publication['data']['ee']['__content__']
                            doi.slice! "https://doi.org/"
                            publication['doi'] = doi
                        end
                    elsif publication['data']['ee'].is_a? (String)
                        doi = publication['data']['ee']
                        doi.slice! "https://doi.org/"
                        publication['doi'] = doi
                    end
                end

                if(completed)
                    Publication.create(publication_id: key, title: publication['data']['title'], year: publication['data']['year'], pubType: publication['type'], doi: publication['doi'])
                else
                    pub = Publication.find_by(publication_id: key)
                    pub.update(title: publication['data']['title'], year: publication['data']['year'], pubType: publication['type'], doi: publication['doi'], completed: true)
                end
            end
        end

        publication = Publication.find_by(publication_id: key).attributes
        publication['references'] = []
        publication['citations'] = []

        if(!publication['doi'].nil? && publication['doi'] != "")
            publication['references'] = getPublicationCitRef(publication['doi'])['references']
            publication['citations'] = getPublicationCitRef(publication['doi'])['citations']

            citationsNew = {}
            referencesNew = {}

            publication['citationsNum_peryear'] = {}
            publication['citations'].each do |year, citations|
                publication['citationsNum_peryear'][year] = citations.length
                citationsNew[year] ||= citations
            end

            publication['references'].each do |year, references|
                referencesNew[year] ||= references
            end

            publication['citations'] = citationsNew
            publication['references'] = referencesNew

            publication['citationsNum_peryear'] = publication['citationsNum_peryear'].sort.to_h
        end

        publication
    end

    def self.getPublicationCitRef(doi)
        publicationReferences = HTTParty.get('https://api.semanticscholar.org/v1/paper/' + doi + '?include_unknown_references=true')
        res = publicationReferences.parsed_response

        citations = res['citations']
        references = res['references']

        citationsResult = {}
        citations.each do |citation|
            if citation['year'].nil?
                citation['year'] = 0
            end

            ref = {}
            ref['title'] = citation['title']
            ref['doi'] = citation['doi']
            ref['url'] = citation['url']
            ref['authors'] = citation['authors']

            if !citationsResult.has_key? (citation['year'])
                citationsResult[citation['year']] = []
            end
            citationsResult[citation['year']].append(ref)
        end
        citationsResult.keys.sort

        referencesResult = {}
        references.each do |reference|
            if reference['year'].nil?
                reference['year'] = 0
            end

            ref = {}
            ref['title'] = reference['title']
            ref['doi'] = reference['doi']
            ref['url'] = reference['url']
            ref['authors'] = reference['authors']

            if !referencesResult.has_key? (reference['year'])
                referencesResult[reference['year']] = []
            end
            referencesResult[reference['year']].append(ref)
        end
        referencesResult.keys.sort

        result = {}
        result['citations'] = citationsResult
        result['references'] = referencesResult

        result
    end
end
