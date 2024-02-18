class Author < ApplicationRecord
  self.primary_key = :author_id
  has_many :follows
  has_many :works, foreign_key: :author_id, primary_key: :author_id
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

  def self.createAutor(pid)
    authorresponse = Author.getBibliography(pid)
    author = {}

    urls = authorresponse['dblpperson']['person']['url']
    if !urls.nil? && urls.present?
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

    if !Author.exists?(author_id: pid)
      createdAuthor = Author.create(author_id: pid, name: author['name'], completed: false, updated_at: DateTime.now)
    end
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

      if authorresponse['dblpperson'].nil?
        return 'none'
      end

      urls = authorresponse['dblpperson']['person']['url']
      if !urls.nil? && urls.present?
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

          if !Author.exists?(author_id: pid)
            createdAuthor = Author.create(author_id: pid, name: author['name'], orcid: author['orcid'], orcidStatus: author['orcidStatus'], works_count: author['works_count'], completed: true, otherInformations: false, updated_at: DateTime.now)
          elsif Author.find_by(author_id: pid).completed == false || Author.find_by(author_id: pid).updated_at < 7.days.ago
              authorToUpdate = Author.find_by(author_id: pid)
              authorToUpdate.update(author_id: pid, name: author['name'], orcid: author['orcid'], orcidStatus: author['orcidStatus'], works_count: author['works_count'], completed: true, updated_at: DateTime.now)
            end
          end

          url = ''
          if element['ee'].is_a?(Hash) && element['ee']['__content__']
            url = element['ee']['__content__']
          elsif element['ee'].is_a?(String)
            url = element['ee']
          elsif element['ee'].is_a?(Array)
            url = element['ee'][0]
          end

          if(!Publication.exists?(publication_id: element['key']))
            pub = Publication.create(publication_id: element['key'], year: element['year'], title: element['title'], url: url, releaseDate: element['mdate'], articleType: element['type'], completed: false, updated_at: DateTime.now)
          elsif Author.find_by(author_id: pid).updated_at < 7.days.ago
            pub = Publication.find_by(publication_id: element['key'])
            pub.update(year: element['year'], title: element['title'], url: url, releaseDate: element['mdate'], articleType: element['type'], completed: false, updated_at: DateTime.now)
          end
          Work.create(publication: Publication.find_by(publication_id: element['key']), author: Author.find_by(author_id: pid))

          element['author'].each do |pubAuthor|
              if pubAuthor.is_a?(Hash)
                  if pubAuthor['pid'].present? && pubAuthor['pid'] != pid
                      if !Author.exists?(author_id: pubAuthor['pid'])
                          Author.create(author_id: pubAuthor['pid'], name: pubAuthor['__content__'], completed: false)
                          Work.create(publication: Publication.find_by(publication_id: element['key']), author: Author.find_by(author_id: pubAuthor['pid']))
                      end
                  end
              end
          end
        end
      unless bibliography.nil?

      if Author.find_by(author_id: pid).otherInformations == false || Author.find_by(author_id: pid).updated_at < 7.days.ago
        if author['orcid'] != '' && !author['orcid'].nil?
          extraInformation = {}
          extraInformation['last_known_institution'] = {}
          extraInformation['summary_stats'] = {}

          extraInformation = Author.getAuthorInformations(author['orcid'])
          if !extraInformation.nil?
            authorToUpdate = Author.find_by(author_id: pid)
            authorToUpdate.update(h_index: extraInformation['summary_stats']['h_index'])
            authorToUpdate.update(citationNumber: extraInformation['cited_by_count'])
            authorToUpdate.update(last_known_institution: extraInformation['last_known_institution']['display_name'])
            authorToUpdate.update(last_known_institution_type: extraInformation['last_known_institution']['type'])
            authorToUpdate.update(last_known_institution_countrycode: extraInformation['last_known_institution']['country_code'])
            authorToUpdate.update(completed: true, updated_at: DateTime.now)

            extraInformation['counts_by_year'].each do |yearData|
              cit = Citation.create(year: yearData['year'], citation_count: yearData['cited_by_count'], author: Author.find_by(author_id: pid), updated_at: DateTime.now)
            end
          end
        end
      end
    end
  end

  def self.getAuthor(pid)
    if !Author.exists?(author_id: pid) || Author.find_by(author_id: pid).completed == false || Author.find_by(author_id: pid).updated_at < 7.days.ago
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

      distinct_types = Publication.distinct.pluck(:articleType)
      distinct_years = Publication.distinct.pluck(:year)

      all_combinations = distinct_types.product(distinct_years)

      all_combinations.each do |combination|
        bibliography_types_peryear[combination] = 0
      end

      publications = Publication.joins(:works).where(works: {author_id: author_id})
      publications.each do |publication|
        year = publication.year
        article_type = publication.articleType

        key = [article_type, year]
        bibliography_types_peryear[key] += 1
      end
      bibliography_types_peryear
  end

  def getCollaborations()
      collaborations = {}
      collaborations['number'] = {}
      collaborations['data'] = {}
      collaborations['years'] = []

      Work.where(author_id: author_id).each do |work|
        year = work.publication.year
        if !collaborations['years'].include? (year)
          collaborations['years'].push(year)
        end
        collaborations['data'][year] ||= {}

        Work.where(publication_id: work.publication_id).each do |work2|
          content_key = work2.author.name
          pid_key = work2.author.author_id

          next if content_key == name && (pid_key == author_id || pid_key.nil?)

          collaborations['data'][year][content_key] ||= {}
          collaborations['data'][year][content_key][pid_key] ||= { 'pid' => pid_key, 'count' => 0 }

          collaborations['data'][year][content_key][pid_key]['count'] += 1
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
