Given('the user follows the author') do
    @follow = FactoryBot.create(:follow, user: @user, author: @author)
end

When('the user visits the user page') do
    visit user_path(@user.id)
end

Then('the user shold see a {string} link') do |link|
    expect(page).to have_link(link)
end

And('the user clicks on the {string} link') do |link|
    click_link(link)
end

Then('the user should see a link to the author page') do
    #puts page.html.lines.last(20).join
    expect(page).to have_link(@author.name)
end

And('the user clicks on the author link') do
    #puts page.html.lines.last(20).join
    click_link(@author.name)
end

Then('the user should be redirected to the author page') do
    sleep(2)
    expected_author_path = "/authors/#{@author.author_id}"
    actual_author_path = URI.decode_www_form_component(current_path)
    expect(actual_author_path).to eq(expected_author_path)
end