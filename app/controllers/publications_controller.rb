require 'httparty'

class PublicationsController < ApplicationController
    def index
        key = params[:key] || 0
        publicationData = getPublicationInformation(key)
        publicationData = publicationData['dblp']

        puts publicationData

        @publication = {}
        @publication['doi'] = ""
        if publicationData.is_a?(Hash)
            @publication['type'] = publicationData.keys[0]
            @publication['data'] = publicationData[@publication['type']]
            
            if @publication['data']['ee']['__content__'].include? "https://doi.org/"
                doi = @publication['data']['ee']['__content__']
                doi.slice! "https://doi.org/"
                @publication['doi'] = doi

                @publication['references'] = getPublicationReferences(doi)
            end
        end
    end

    def getPublicationInformation(key)
        publicationdblp = HTTParty.get('https://dblp.org/rec/' + key + '.xml')
        publicationdblp.parsed_response
    end

    def getPublicationReferences(doi)
        publicationReferences = HTTParty.get('https://api.crossref.org/works/' + doi)
        res = publicationReferences.parsed_response

        references = []
        if res['status'] = 'okay' && res['message']['reference-count'] > 0
            references = res['message']['reference']
        end

        references
    end
end
