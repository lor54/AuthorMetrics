require 'httparty'

class PublicationsController < ApplicationController
    def index
        key = params[:key] || 0
        publicationData = getPublicationInformation(key)
        publicationData = publicationData['dblp']


        @publication = {}
        @publication['doi'] = ""
        @publication['references'] = []
        @publication['citations'] = []

        if publicationData.is_a?(Hash)
            @publication['type'] = publicationData.keys[0]
            @publication['data'] = publicationData[@publication['type']]

            if @publication['data']['ee'].is_a? (Hash)
                if @publication['data']['ee']['__content__'].include? "https://doi.org/"
                    doi = @publication['data']['ee']['__content__']
                    doi.slice! "https://doi.org/"
                    @publication['doi'] = doi

                    @publication['references'] = getPublicationCitRef(doi)['references']
                    @publication['citations'] = getPublicationCitRef(doi)['citations']
                end
            elsif @publication['data']['ee'].is_a? (String)
                doi = @publication['data']['ee']
                doi.slice! "https://doi.org/"
                @publication['doi'] = doi

                @publication['references'] = getPublicationCitRef(doi)['references']
                @publication['citations'] = getPublicationCitRef(doi)['citations']
            end
        end
    end

    def getPublicationInformation(key)
        publicationdblp = HTTParty.get('https://dblp.org/rec/' + key + '.xml')
        publicationdblp.parsed_response
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
