Feature: Visualize followed authors from user page

    Background:
        Given there is a user signed in
        And there is an author
        # And the user follows the author
    
    Scenario: User can visit the author page from the user page
        When the user follows the author
        And the user visits the user page
        Then the user shold see a "Autori Seguiti:" link
        And the user clicks on the "Autori Seguiti:" link
        Then the user should see a link to the author page
        And the user clicks on the author link
        Then the user should be redirected to the author page