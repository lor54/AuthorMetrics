Feature: Access publication of an author

    Background: 
        Given there is an author
        # And the author has at least one publication

    Scenario:
        When the user visits the home page
        Then the user searches the author
        And the user accesses the page of the author
        Then the user should see a link to a publication of the author
        And the user selects the publication link
        Then the user should be redirected to the publication page
        And the page should have a "Go to document" button
        Then the user clicks the "Go to document" button
        And the user should be redirected to the document