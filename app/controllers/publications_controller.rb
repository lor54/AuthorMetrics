require 'httparty'

class PublicationsController < ApplicationController
    def index
        key = params[:key] || 0
        @publication = Publication.getPublicationInformation(key)
        
        @referencesYears = []
        @referenceYear = 0
        if !@publication['references'].nil?
            @referencesYears = @publication['references'].keys
            @referenceYear = @referencesYears[0]

            @publication['references'].each do |year, references|
                @publication['references'][year] = @publication['references'][year].paginate(:page => params[:referencesPage], :per_page => 5)
            end
        end

        @citationsYears = []
        @citationYear = 0
        if !@publication['citations'].nil?
            @citationsYears = @publication['citations'].keys
            @citationYear = @citationsYears[0]

            @publication['citations'].each do |year, citations|
                @publication['citations'][year] = @publication['citations'][year].paginate(:page => params[:citationsPage], :per_page => 5)
            end
        end

        if !params[:citationYear].nil?
            @citationYear = params[:citationYear].to_i
        end

        if !params[:referenceYear].nil?
            @referenceYear = params[:referenceYear].to_i
        end
    end

    def getPublicationCitRef(doi)
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
