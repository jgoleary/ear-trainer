import XCTest

final class ExerciseFlowTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    func test_lessonBrowser_showsLesson1() {
        XCTAssertTrue(app.staticTexts["Tonic & Dominant"].exists)
    }

    func test_lessonBrowser_lesson1_isUnlocked() {
        // Lesson 1 card should be tappable (not grayed/locked)
        let card = app.staticTexts["Tonic & Dominant"]
        XCTAssertTrue(card.isHittable)
    }

    func test_tappingLesson1_navigatesToExercise() {
        app.staticTexts["Tonic & Dominant"].tap()
        XCTAssertTrue(app.staticTexts["Exercise 1 of 10"].exists)
    }

    func test_exerciseView_showsSingButton() {
        app.staticTexts["Tonic & Dominant"].tap()
        XCTAssertTrue(app.buttons["Sing"].exists)
    }

    func test_solfegeToggle_exists() {
        app.staticTexts["Tonic & Dominant"].tap()
        XCTAssertTrue(app.buttons["Solfege"].exists)
    }
}
