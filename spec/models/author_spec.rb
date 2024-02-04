require 'rails_helper'
require 'httparty'

RSpec.describe Author, type: :model do
    let(:author_name) {'Leonardo'}
    let(:start_author) { 1 }
    let(:response) { Author.searchAuthor(author_name, 10, start_author) }
    let(:pid) {response['result']['hits']['hit'].first()['info']['url'].split('pid/')[1]}
    

    describe 'searchAuthor' do

        it 'should make a successful HTTP request' do
            code = response['result']['status']['@code']

            expect(code).to eq('200')
        end

        it 'returns at least one result' do
            total = response['result']['hits']['@total'].to_i
            expect(total).to be > 0
        end

        it 'starts from the given position' do
            start = response['result']['hits']['@first'].to_i
            expect(start).to eq(start_author)
        end
    end

    describe 'getAuthorData' do
        it 'creates a new author entry in the database' do
            Author.getAuthorData(pid.to_s)

            expect(Author.exists?(author_id: pid)).to be_truthy
        end
    end

    describe 'getAuthorInformations' do
        let(:author) { Author.getAuthor(pid.to_s)}
        let(:info) { Author.getAuthorInformations(author.orcid) }

        it 'should make a successful HTTP request' do
            orcid = info['orcid']
            if orcid.include? "https://orcid.org/"
                orcid.slice! "https://orcid.org/"
            end
            expect(orcid).to eq(author.orcid)
        end

        it 'returns author h-index' do
            h_index = info['summary_stats']['h_index']
            expect(h_index).to be_instance_of(Integer)
        end

        it 'returns number of works and citations' do
            works = info['works_count']
            citations = info['cited_by_count']
            expect(works).to be_instance_of(Integer)
            expect(citations).to be_instance_of(Integer)
        end

        it 'returns the number of works of each year' do
            works_by_year = info['counts_by_year']
            expect(works_by_year).to be_instance_of(Array)
            expect(works_by_year.length).to be > 0
        end
    end

    describe 'getBibliography' do
        let(:bibliography) { Author.getBibliography(pid.to_s) }

        it 'should make a successful HTTP request' do
            expect(bibliography).to be_a(Hash)
        end

        it 'returns at least one publication' do
            expect(bibliography['dblpperson']['r'].length).to be > 0
        end
    end
end
