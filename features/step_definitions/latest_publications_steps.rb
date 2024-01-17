Given('the author has at least one publication') do
    @publication = FactoryBot.create(:publication)
    @work = FactoryBot.create(:work, publication: @publication, author: @author)
end

When('the user visits the home page') do
    visit root_path
end

Then('the user should see the author latest publications') do
    expect(page).to have_link(@publication.title)
end

And('the user clicks on the publication link') do
    click_link(@publication.title)
end

Then('the user should be redirected to the publication page') do
    sleep(1)
    expect(current_url).to eq(@publication.url)
end