Feature: User updates account information

  In order to correct mistakes on my account info
  As a registered user
  I want to update my account information

  Background:
    Given The default project and jnlp resources exist using factories
    And the database has been seeded

  @javascript
  Scenario Outline: Users can not change their usernames
    When I log out
    And I am logged in with the username <username>
    And I am on the user preferences page for the user "<username>"
    Then I should see "User Preferences"
    And I should see "First name"
    But I should not see the xpath "//input[@id='user_login']"
    And I should not see "Username"

    Examples:
      | username | password |
      | student  | student  |
      | teacher  | teacher  |

  @javascript
  Scenario: Students can not change their email addresses
    When I am logged in with the username student
    And I am on the user preferences page for the user "student"
    Then I should see "User Preferences"
    And I should see "First name"
    But I should not see the xpath "//input[@id='user_email']"
    And I should not see "Username"
