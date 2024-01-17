FactoryBot.define do
    factory :work do
        association :publication
        association :author
    end
end  