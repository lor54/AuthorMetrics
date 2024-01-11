# features/step_definitions/follows_steps.rb

    Given('there is a user signed in') do
        @user = FactoryBot.create(:user)
        visit new_user_session_path
        fill_in 'Email', with: @user.email
        fill_in 'Password', with: @user.password
        click_button 'Log in'
    end
    
    Given('there is an author') do
        @author = FactoryBot.create(:author)
    end
    
    When('the user visits the author\'s page') do
        visit author_path(@author.author_id)
    end

    And('does not follow the author') do
        @follow = @user.follows.find_by(author_id: @author.author_id)
        expect(@follow).to be(nil)
    end

    Then('the page should have a {string} button') do |button|
        expect(page).to have_button(button)
    end
    
    When('the user clicks the {string} button') do |button|
        click_button button
    end