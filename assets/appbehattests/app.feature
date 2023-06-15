@javascript @app @moodledocker
Feature: The app starts in behat
  In order to test that the app it working properly
  As moodle-docker
  I need a way to verify this

  Scenario: Start the app
    Given the following "users" exist:
      | username | firstname | lastname | email                |
      | student1 | Student   | 1        | student1@example.com |
    And the following "courses" exist:
      | fullname | shortname | category |
      | Course 1 | C1        | 0        |
    And the following "course enrolments" exist:
      | user     | course | role    |
      | student1 | C1     | student |
    And the following "activities" exist:
      | activity | course | idnumber | name    | intro           |
      | label    | C1     | label1   | Label 1 | It worked great |
    When I entered the course "Course 1" as "student1" in the app
    Then I should find "It worked great" in the app
