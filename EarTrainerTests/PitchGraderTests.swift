import XCTest
@testable import EarTrainer

final class PitchGraderTests: XCTestCase {

    // MARK: - Cents calculation

    func test_onPitch_exactMatch() {
        let result = PitchGrader.grade(measured: 440.0, target: 440.0)
        XCTAssertTrue(result.isOnPitch)
    }

    func test_onPitch_within25Cents() {
        // 25 cents sharp of A4 (440 Hz)
        let sharpBy25 = 440.0 * pow(2.0, 25.0 / 1200.0)
        let result = PitchGrader.grade(measured: sharpBy25, target: 440.0)
        XCTAssertTrue(result.isOnPitch)
    }

    func test_sharp_26to50Cents() {
        let sharpBy35 = 440.0 * pow(2.0, 35.0 / 1200.0)
        let result = PitchGrader.grade(measured: sharpBy35, target: 440.0)
        if case .sharp(let c) = result {
            XCTAssertEqual(c, 35.0, accuracy: 0.5)
            XCTAssertEqual(result.score, 0.6, accuracy: 0.01)
        } else {
            XCTFail("Expected .sharp, got \(result)")
        }
    }

    func test_flat_51to100Cents() {
        let flatBy70 = 440.0 * pow(2.0, -70.0 / 1200.0)
        let result = PitchGrader.grade(measured: flatBy70, target: 440.0)
        if case .flat(let c) = result {
            XCTAssertEqual(c, 70.0, accuracy: 0.5)
            XCTAssertEqual(result.score, 0.3, accuracy: 0.01)
        } else {
            XCTFail("Expected .flat, got \(result)")
        }
    }

    func test_sharp_over100Cents_scoresZero() {
        let sharpBy150 = 440.0 * pow(2.0, 150.0 / 1200.0)
        let result = PitchGrader.grade(measured: sharpBy150, target: 440.0)
        XCTAssertEqual(result.score, 0.0)
    }

    func test_undetected_scoresZero() {
        let result = PitchGrader.gradeUndetected()
        XCTAssertEqual(result.score, 0.0)
    }

    // MARK: - Phrase scoring

    func test_phraseScore_allOnPitch() {
        let results: [PitchResult] = [.onPitch, .onPitch, .onPitch]
        XCTAssertEqual(PitchGrader.phraseScore(results), 1.0, accuracy: 0.01)
    }

    func test_phraseScore_mixed() {
        // 1.0 + 0.6 + 0.0 = 1.6 / 3 = 0.533
        let results: [PitchResult] = [.onPitch, .sharp(cents: 35), .undetected]
        XCTAssertEqual(PitchGrader.phraseScore(results), 0.533, accuracy: 0.01)
    }

    // MARK: - Star rating

    func test_stars_threeStars() {
        XCTAssertEqual(PitchGrader.stars(forAverageScore: 0.95), 3)
    }

    func test_stars_twoStars() {
        XCTAssertEqual(PitchGrader.stars(forAverageScore: 0.80), 2)
    }

    func test_stars_oneStar() {
        XCTAssertEqual(PitchGrader.stars(forAverageScore: 0.60), 1)
    }

    func test_stars_zero() {
        XCTAssertEqual(PitchGrader.stars(forAverageScore: 0.40), 0)
    }

    func test_stars_boundaryAt90() {
        XCTAssertEqual(PitchGrader.stars(forAverageScore: 0.90), 3)
        XCTAssertEqual(PitchGrader.stars(forAverageScore: 0.8999), 2)
    }
}
