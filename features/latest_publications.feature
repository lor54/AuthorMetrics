Feature: User can see followed author's latest publication from home page

    Background:
        Given there is a user signed in
        And there is an author
        # And the author has at least one publication

    Scenario:
        When the user follows the author
        And the user visits the home page
        Then the user should see the author latest publications
        And the user clicks on the publication link
        Then the user should be redirected to the publication page
        And the page should have a "Go to document" button
        Then the user clicks the "Go to document" button
        And the user should be redirected to the document