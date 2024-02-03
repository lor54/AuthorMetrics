FactoryBot.define do
    factory :publication do
        publication_id { '1' }
        year { 2024 }
        title { 'example'} 
        url { 'https://www.example.com/' }
        articleType { 'article' }
        releaseDate { '2024-01-12' }
        completed { true }
    end
end