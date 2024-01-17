FactoryBot.define do
    factory :follow do
        association :user
        association :author
    end
end