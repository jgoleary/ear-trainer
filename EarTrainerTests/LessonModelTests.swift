import XCTest
@testable import EarTrainer

final class LessonModelTests: XCTestCase {

    func test_curriculum_has14Lessons() {
        XCTAssertEqual(LessonCurriculum.all.count, 14)
    }

    func test_each_lesson_has10Phrases() {
        for lesson in LessonCurriculum.all {
            XCTAssertEqual(lesson.phrases.count, 10, "Lesson '\(lesson.title)' has \(lesson.phrases.count) phrases")
        }
    }

    func test_each_phrase_hasAtLeastOneNote() {
        for lesson in LessonCurriculum.all {
            for phrase in lesson.phrases {
                XCTAssertFalse(phrase.notes.isEmpty, "Lesson '\(lesson.title)' has empty phrase")
            }
        }
    }

    func test_lesson1_onlyUsesDoAndSol() {
        let lesson = LessonCurriculum.all[0]
        let allowedMIDI: Set<Int> = [60, 67] // C4, G4
        for phrase in lesson.phrases {
            for note in phrase.notes {
                XCTAssertTrue(allowedMIDI.contains(note.midiPitch),
                    "Lesson 1 has unexpected note: \(note.solfege) (MIDI \(note.midiPitch))")
            }
        }
    }

    func test_noteFrequencies_areCorrect() {
        // C4 = 261.63 Hz
        let c4 = Note(solfege: "Do", midiPitch: 60, durationBeats: 1)
        XCTAssertEqual(c4.frequency, 261.63, accuracy: 0.01)

        // A4 = 440.00 Hz
        let a4 = Note(solfege: "La", midiPitch: 69, durationBeats: 1)
        XCTAssertEqual(a4.frequency, 440.00, accuracy: 0.01)
    }

    func test_lessonIDs_areUnique() {
        let ids = LessonCurriculum.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func test_lesson1_hasID_lesson01() {
        XCTAssertEqual(LessonCurriculum.all[0].id, "lesson-01")
    }
}
