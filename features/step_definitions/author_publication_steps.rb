Then('the user searches the author') do
    visit authors_path
    fill_in 'name', with: @author.name
    click_button('Search')
end

And('the user accesses the page of the author') do
    sleep(0.5)
    expect(page).to have_link(@author.name)
    click_link(@author.name)
end

Then('the user should see a link to a publication of the author') do
    sleep(1)
    expect(page).to have_link(@author.publications.first.title)
end

And('the user selects the publication link') do
    click_link(@author.publications.first.title)
end

Then('the user should be redirected to the publication page') do
    sleep(2)
    expected_publication_path = "/publications/#{@author.publications.first.publication_id}"
    actual_publication_path = URI.decode_www_form_component(current_path)
    expect(actual_publication_path).to eq(expected_publication_path)
end

# And('the page should have a {string} button') do |button|
#     expect(page).to have_button(button)
# end

# Then('the user clicks the document button') do
#     click_button 'Go to document'
# end

And('the user should be redirected to the document') do
    expected_url = @author.publications.first.url
    got_url = current_url

    expected_path = URI.parse(expected_url).path
    uri = URI.parse(got_url)
    path_components = uri.path.split('/')
    path_components.delete("chapter")

    modified_path = path_components.join('/')

    expect(modified_path).to eq(expected_path)
end