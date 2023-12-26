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

        if author['orcid'] != '' && !author['orcid'].nil?
            extraInformation = Author.getAuthorInformations(author['orcid'])

            citations_counts_by_year = {}
    
            extraInformation['counts_by_year'].each do |yearData|
            year = yearData['year'].to_s
            if !citations_counts_by_year.has_key? (year)
                citations_counts_by_year[year] = 0
            end
    
            citations_counts_by_year[year] += yearData['cited_by_count']
            end
    
            author['citations_counts_by_year'] = citations_counts_by_year
            author['citations_counts_by_year'] = author['citations_counts_by_year'].sort.to_h
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
  
            if !Author.exists?(author_id: pid)
              createdAuthor = Author.create(author_id: pid, name: author['name'], surname: '', orcid: author['orcid'], orcidStatus: author['orcidStatus'], h_index: extraInformation['summary_stats']['h_index'], citationNumber: extraInformation['cited_by_count'], works_count: author['works_count'], last_known_institution: extraInformation['last_known_institution']['display_name'], last_known_institution_type: extraInformation['last_known_institution']['type'], last_known_institution_countrycode: extraInformation['last_known_institution']['country_code'], updated_at: DateTime.now)
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
            p pub
            res = Work.create(publication: Publication.find_by(publication_id: element['key']), author: Author.find_by(author_id: pid))
            p res
            sleep(100000)
          end
        end unless bibliography.nil?
    end

    def self.getAuthor(pid)
        if !Author.exists?(author_id: pid) || Author.find_by(author_id: pid).updated_at > 1.day.ago
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

        works = Work.where(author_id: self.author_id)
        works.each do |work|
            if !work.publication.nil?
                publ = work.publication
                if !citations_counts_by_year.has_key? (publ.year)
                    citations_counts_by_year[publ.year] = 0
                end

                citations_counts_by_year[publ.year] += publ.citation.citation_count
            end
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
end
