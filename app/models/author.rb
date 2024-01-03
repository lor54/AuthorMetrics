class Author < ApplicationRecord
    self.primary_key = :author_id
    has_many :follows
    has_many :works
    has_many :publications, through: :works

    def self.searchAuthor(name, maxPerPage, startValue)
        authordblp = HTTParty.get('https://dblp.org/search/author/api?q=' + name + '&h=' + maxPerPage.to_s + '&f=' + startValue.to_s + '&format=json')
        authordblp.parsed_response
    end
    
    def self.getBibliography(pid)
        authordblp = HTTParty.get('https://dblp.org/pid/' + pid + '.xml')
        authordblp.parsed_response
    end

    def self.getAuthorInformations(orcid)
        extraInformation = HTTParty.get('https://api.openalex.org/authors/https://orcid.org/' + orcid)
        extraInformation = extraInformation.parsed_response
    end

    def self.getAuthorData(pid)
        createdAuthor = {}
        extraInformation = {}
        authorresponse = Author.getBibliography(pid)
        
        author = {}
        author['counts_by_year'] = {}
        author['works_by_year'] = {}
        author['citations_counts_by_year'] = {}
        author['bibliography'] = {}
        author['bibliography_types'] = {}
        author['bibliography_types_peryear'] = []
        author['works_source'] = {}
        
        author['orcid'] = ''
        author['orcidStatus'] = 'none'
        author['bibliography_types'] = {}
        author['bibliography_types_peryear'] = []

        author['orcid'] = ''
        author['orcidStatus'] = 'none'
        author['bibliography_types'] = {}
        author['bibliography_types_peryear'] = []

        urls = authorresponse['dblpperson']['person']['url']
        if urls.present?
          if urls.is_a?(Array)
            authorresponse['dblpperson']['person']['url'].each do |url|
              if url.include? 'orcid'
                author['orcid'] = url
                author['orcidStatus'] = 'verified'
                break
              end
            end
          elsif urls.is_a?(String)
            author['orcid'] = urls
            author['orcidStatus'] = 'verified'
          end
        end
  
        author['name'] = authorresponse['dblpperson']['name']
        author['pid'] = pid
        bibliography = authorresponse['dblpperson']['r']
  
        author['bibliography'] = {}
        if bibliography.is_a?(Hash)
          bibliography = [bibliography]
        end

        bibliography.each do |element|
          if element.is_a?(Hash)
            elementType = element.keys[0]
            element = element[element.keys[0]]
            element['type'] = elementType
  
            if !author['bibliography'].key?(element['year'])
              author['bibliography'][element['year']] = []
            end
  
            if element['author']
              element['author'].collect{ |author|
                if author.is_a?(Array)
                  if author[0] == '__content__'
                    auth = [{'__content__' => author[1]}]
  
                    if author[2] == 'pid'
                      auth[0]['pid'] = author[3]
                    end
  
                    element['author'] = auth
                  end
                end
              }
            elsif element['editor']
              element['editor'].collect{ |author|
                if author.is_a?(Array)
                  if author[0] == '__content__'
                    auth = [{'__content__' => author[1]}]
  
                    if author[2] == 'pid'
                      auth[0]['pid'] = author[3]
                    end
  
                    element['author'] = auth
                  end
                else
                  element['author'] = element['editor']
                end
              }
            end
  
            if author['orcid'].empty?
              if element['author'].is_a?(Array)
                element['author'].each do |pubAuthor|
                  if pubAuthor.is_a?(Hash)
                    if pubAuthor['pid'].present? && pid == pubAuthor['pid'] && pubAuthor['orcid'].present? && pubAuthor['orcid'].is_a?(String)
                      author['orcid'] = pubAuthor['orcid']
                      author['orcidStatus'] = 'unverified'
                    end
                  end
                end
              end
            end

            if author['orcid'].include? "https://orcid.org/"
                author['orcid'].slice! "https://orcid.org/"
            end

            extraInformation = {}
            extraInformation['last_known_institution'] = {}
            extraInformation['summary_stats'] = {}
            if author['orcid'] != '' && !author['orcid'].nil?
                extraInformation = Author.getAuthorInformations(author['orcid'])
            end

            if !Author.exists?(author_id: pid)
                p 'provaaa'
                p author
              createdAuthor = Author.create(author_id: pid, name: author['name'], surname: '', orcid: author['orcid'], orcidStatus: author['orcidStatus'], h_index: extraInformation['summary_stats']['h_index'], citationNumber: extraInformation['cited_by_count'], works_count: author['works_count'], last_known_institution: extraInformation['last_known_institution']['display_name'], last_known_institution_type: extraInformation['last_known_institution']['type'], last_known_institution_countrycode: extraInformation['last_known_institution']['country_code'], completed: true, updated_at: DateTime.now)
            elsif Author.find_by(author_id: pid).completed == false
                Author.update(author_id: pid, name: author['name'], surname: '', orcid: author['orcid'], orcidStatus: author['orcidStatus'], h_index: extraInformation['summary_stats']['h_index'], citationNumber: extraInformation['cited_by_count'], works_count: author['works_count'], last_known_institution: extraInformation['last_known_institution']['display_name'], last_known_institution_type: extraInformation['last_known_institution']['type'], last_known_institution_countrycode: extraInformation['last_known_institution']['country_code'], completed: true, updated_at: DateTime.now)
            end
  
            url = ''
            if element['ee'].is_a?(Hash) && element['ee']['__content__']
              url = element['ee']['__content__']
            elsif element['ee'].is_a?(String)
              url = element['ee']
            elsif element['ee'].is_a?(Array)
              url = element['ee'][0]
            end
  
            pub = Publication.create(publication_id: element['key'], year: element['year'], title: element['title'], url: url, releasedate: element['mdate'], articleType: element['type'], updated_at: DateTime.now)
            res = Work.create(publication: Publication.find_by(publication_id: element['key']), author: Author.find_by(author_id: pid))

            element['author'].each do |pubAuthor|
                if pubAuthor.is_a?(Hash)
                    if pubAuthor['pid'].present? && pubAuthor['pid'] != pid
                        p pubAuthor
                        if !Author.exists?(author_id: pubAuthor['pid'])
                            Author.create(author_id: pubAuthor['pid'], name: pubAuthor['__content__'], completed: false)
                            Work.create(publication: Publication.find_by(publication_id: element['key']), author: Author.find_by(author_id: pubAuthor['pid']))
                        end
                    end
                end
            end

            end
        end unless bibliography.nil?

        if author['orcid'] != '' && !author['orcid'].nil?    
            extraInformation['counts_by_year'].each do |yearData|
                cit = Citation.create(year: yearData['year'], citation_count: yearData['cited_by_count'], author: Author.find_by(author_id: pid), updated_at: DateTime.now)
            end
        end
    end

    def self.getAuthor(pid)
        if !Author.exists?(author_id: pid) #|| Author.find_by(author_id: pid).updated_at > 1.day.ago
            Author.getAuthorData(pid)
        end

        Author.find_by(author_id: pid)
    end

    def getWorks()
        works = Work.where(author_id: self.author_id)
    end

    def getWorksCount()
        works = Work.where(author_id: self.author_id)
        works.count
    end

    def getWorksCountByYear()
        works_counts_by_year = {}

        works = Work.where(author_id: self.author_id)
        works.each do |work|
            if !work.publication.nil?
                publ = work.publication
                if !works_counts_by_year.has_key? (publ.year)
                    works_counts_by_year[publ.year] = 1
                else
                    works_counts_by_year[publ.year] += 1
                end
            end
        end

        works_counts_by_year
    end

    def getCitationsCountByYear()
        citations_counts_by_year = {}

        citations = Citation.where(author_id: self.author_id)
        citations.each do |citation|
            if !citations_counts_by_year.has_key? (citation.year)
                citations_counts_by_year[citation.year] = 0
            end

            citations_counts_by_year[citation.year] += citation.citation_count
        end

        citations_counts_by_year
    end

    def getBibliographyTypes()
        bibliography_types = {}

        publications = Publication.joins(:works).where(works: {author_id: self.author_id})
        publications.each do |publication|
            if !bibliography_types.has_key? (publication.articleType)
                bibliography_types[publication.articleType] = 1
            else
                bibliography_types[publication.articleType] += 1
            end
        end

        bibliography_types
    end

    def getWorksSource()
        work_source = {}
        count = getWorksCount()
        if count > 0
            work_source['dblp'] = count
        end

        work_source
    end

    def getBibliographyTypesPerYear()
        bibliography_types_peryear = {}

        publications = Publication.joins(:works).where(works: {author_id: self.author_id})
        publications.each do |publication|
            if !bibliography_types_peryear.has_key? (publication.year)
                bibliography_types_peryear[publication.year] = {}
            else
                if !bibliography_types_peryear[publication.year].has_key? (publication.articleType)
                    bibliography_types_peryear[publication.year][publication.articleType] = 1
                else
                    bibliography_types_peryear[publication.year][publication.articleType] += 1
                end
            end
        end

        bibliography_types_peryear
    end

    def getCollaborations()
        collaborations = {}
        collaborations['number'] = {}
        collaborations['data'] = {}

        Work.where(author_id: author_id).each do |work|
            Work.where(publication_id: work.publication_id).each do |work2|
                year = work2.publication.year
                collaborations['data'][year] = {}

                content_key = work2.author.name
                pid_key = work2.author.author_id

                next if content_key == name && (pid_key == author_id || pid_key.nil?)

                collaborations['data'][year][content_key] ||= {}
                collaborations['data'][year][content_key][pid_key] ||= {}
                collaborations['data'][year][content_key][pid_key]['pid'] ||= pid_key

                if collaborations['data'][year][content_key][pid_key].key?('count')
                    collaborations['data'][year][content_key][pid_key]['count'] += 1
                else
                    collaborations['data'][year][content_key][pid_key]['count'] = 1
                end
            end
        end

        total_sum = {}
        collaborations['data'].each do |year, year_data|
            year_data.each do |name, name_data|
                name_data.each do |pid, data|
                    count = data['count']
                    if total_sum.key?(year)
                        total_sum[year] += count
                    else
                        total_sum[year] = count
                    end
                end
            end
        end
        collaborations['number'] = total_sum
        collaborations['number'] = collaborations['number'].sort.to_h
        collaborations
    end
end
