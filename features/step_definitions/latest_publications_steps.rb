# Given('the author has at least one publication') do
#     @publication = FactoryBot.create(:publication)
#     @work = FactoryBot.create(:work, publication: @publication, author: @author)
# end

When('the user follows the author') do
    visit author_path(@author.author_id)
    expect(page).to have_button('Follow')
    click_button('Follow')
    sleep(0.2)
end

And('the user visits the home page') do
    visit root_path
end

Then('the user should see the author latest publications') do
    expect(page).to have_link(@author.publications.first.title)
end

And('the user clicks on the publication link') do
    click_link(@author.publications.first.title)
end

# Then('the user should be redirected to the publication page') do
#     sleep(1)
#     expected_publication_path = "/publications/#{@publication.publication_id}"
#     actual_publication_path = URI.decode_www_form_component(current_path)
#     expect(actual_publication_path).to eq(expected_publication_path)
# end

# And('the user clicks the {string} button') do |button|
#     click_button button
# end

# And('the user should be redirected to the document') do
#     expect(current_url).to eq(@publication.url)
# end