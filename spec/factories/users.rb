FactoryBot.define do
    factory :user do
        id { 1 }
        email { 'test@example.com' }
        password { 'password123' }
        name { 'example_name' }
        surname { 'example_surname' }
        username { 'example_username' }
    end
end