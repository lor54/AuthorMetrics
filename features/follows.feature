Feature: Follow and unfollow an author

    Background:
        Given there is a user signed in
        And there is an author

    Scenario: User follows and unfollows an author
        When the user visits the author's page
        And does not follow the author

        Then the page should have a "Follow" button
        And the user clicks the "Follow" button

        Then the page should have a "Unfollow" button
        When the user clicks the "Unfollow" button

        Then the page should have a "Follow" button
