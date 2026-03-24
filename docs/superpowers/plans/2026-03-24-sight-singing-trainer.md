# Sight Singing Trainer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an iOS sight-singing trainer that displays solfege phrases on a staff, records the user's singing via microphone, and grades pitch accuracy in real time.

**Architecture:** SwiftUI app with five layers — Lesson Model (embedded curriculum), Lesson Browser (home screen), Exercise View (three-phase practice screen), Audio Engine (AudioKit wrapper for pitch detection and playback), and Pitch Grader (pure logic). Staff is rendered with a custom SwiftUI `Canvas` view.

**Tech Stack:** Swift 5.9+, SwiftUI, iOS 16+, AudioKit 5 (via SPM), XCTest, XcodeGen (project scaffolding)

---

## File Map

```
EarTrainer/
├── project.yml                          # XcodeGen project definition
├── EarTrainer/
│   ├── App/
│   │   └── EarTrainerApp.swift          # App entry point, root navigation
│   ├── Models/
│   │   ├── Note.swift                   # Note struct (solfege, MIDI pitch, duration)
│   │   ├── Phrase.swift                 # Phrase struct (notes, tempo)
│   │   ├── Lesson.swift                 # Lesson struct + Difficulty enum
│   │   ├── PitchResult.swift            # PitchResult enum: .onPitch / .sharp(cents) / .flat(cents)
│   │   └── LessonProgress.swift         # LessonProgress struct (lessonID, bestStars)
│   ├── Curriculum/
│   │   └── LessonCurriculum.swift       # All 14 lessons as static array
│   ├── Audio/
│   │   ├── PitchGrader.swift            # Pure logic: frequency → PitchResult + note/phrase/star scoring
│   │   └── AudioEngine.swift            # AudioKit wrapper (ObservableObject)
│   ├── Storage/
│   │   └── ProgressStore.swift          # UserDefaults-backed progress persistence
│   └── Views/
│       ├── LessonBrowserView.swift      # Home screen: lesson list with stars + lock state
│       ├── LessonCardView.swift         # Individual lesson card subview
│       ├── ExerciseView.swift           # Phase state machine (Preview/Recording/Results)
│       ├── StaffView.swift              # SwiftUI Canvas staff renderer
│       ├── PitchIndicatorView.swift     # Real-time color + ♭/♯ indicator
│       ├── NoteResultIndicator.swift    # Per-note ✓/♭/♯ indicator shown after grading
│       └── LessonResultView.swift       # End-of-lesson star rating + unlock screen
├── EarTrainerTests/
│   ├── PitchGraderTests.swift           # Unit tests: cents calculation, grading, scoring
│   └── LessonModelTests.swift           # Unit tests: curriculum loads, note counts, MIDI values
└── EarTrainerUITests/
    └── ExerciseFlowTests.swift          # XCUITest: phase transitions, navigation
```

---

## Musical Reference

All lessons use C major, treble clef. MIDI pitches and staff positions:

| Solfege | Note | MIDI | Freq (Hz) | Staff Position |
|---------|------|------|-----------|----------------|
| Do | C4 | 60 | 261.63 | Ledger line below staff |
| Re | D4 | 62 | 293.66 | Space below first line |
| Mi | E4 | 64 | 329.63 | First line |
| Fa | F4 | 65 | 349.23 | First space |
| Sol | G4 | 67 | 392.00 | Second line |
| La | A4 | 69 | 440.00 | Second space |
| Ti | B4 | 71 | 493.88 | Third line (middle) |
| Do' | C5 | 72 | 523.25 | Third space |

Staff position offset (half-steps from bottom line E4, counting lines and spaces from 0):
`E4=0, F4=1, G4=2, A4=3, B4=4, C5=5` — C4 is -2 (one ledger line below).

Cents formula: `cents = 1200 × log2(measuredHz / targetHz)`

---

## Task 1: Project Scaffolding

**Files:**
- Create: `project.yml`
- Create: `EarTrainer/App/EarTrainerApp.swift`

### Prerequisites

Install XcodeGen if not present:
```bash
brew install xcodegen
```

- [ ] **Step 1: Create project.yml**

```yaml
name: EarTrainer
options:
  bundleIdPrefix: com.eartrainer
  deploymentTarget:
    iOS: "16.0"
  xcodeVersion: "15"
packages:
  AudioKit:
    url: https://github.com/AudioKit/AudioKit
    from: 5.6.0
  AudioKitEX:
    url: https://github.com/AudioKit/AudioKitEX
    from: 5.6.0
targets:
  EarTrainer:
    type: application
    platform: iOS
    sources: EarTrainer
    info:
      path: EarTrainer/Info.plist
      properties:
        NSMicrophoneUsageDescription: "EarTrainer needs microphone access to grade your singing."
        UILaunchScreen: {}
    dependencies:
      - package: AudioKit
      - package: AudioKitEX
  EarTrainerTests:
    type: bundle.unit-test
    platform: iOS
    sources: EarTrainerTests
    dependencies:
      - target: EarTrainer
  EarTrainerUITests:
    type: bundle.ui-testing
    platform: iOS
    sources: EarTrainerUITests
    dependencies:
      - target: EarTrainer
```

- [ ] **Step 2: Create app entry point**

Create `EarTrainer/App/EarTrainerApp.swift`:
```swift
import SwiftUI

@main
struct EarTrainerApp: App {
    var body: some Scene {
        WindowGroup {
            LessonBrowserView()
        }
    }
}
```

- [ ] **Step 3: Generate Xcode project**

```bash
cd /Users/jgoleary/ear_trainer
xcodegen generate
```

Expected: `EarTrainer.xcodeproj` created. Open in Xcode and verify it builds (will have missing file errors until later tasks — that's fine).

- [ ] **Step 4: Commit**

```bash
git add project.yml EarTrainer/App/EarTrainerApp.swift EarTrainer.xcodeproj
git commit -m "feat: scaffold Xcode project with AudioKit dependency"
```

---

## Task 2: Data Models

**Files:**
- Create: `EarTrainer/Models/Note.swift`
- Create: `EarTrainer/Models/Phrase.swift`
- Create: `EarTrainer/Models/Lesson.swift`
- Create: `EarTrainer/Models/PitchResult.swift`
- Create: `EarTrainer/Models/LessonProgress.swift`

- [ ] **Step 1: Create Note.swift**

```swift
struct Note: Identifiable, Equatable {
    let id = UUID()
    let solfege: String     // "Do", "Re", "Mi", "Fa", "Sol", "La", "Ti"
    let midiPitch: Int      // 60 = C4, 62 = D4, etc.
    let durationBeats: Double

    var frequency: Double {
        // Equal temperament: A4 = 440 Hz, MIDI 69
        return 440.0 * pow(2.0, Double(midiPitch - 69) / 12.0)
    }
}
```

- [ ] **Step 2: Create Phrase.swift**

```swift
struct Phrase: Identifiable {
    let id = UUID()
    let notes: [Note]
    let tempoBPM: Int

    var secondsPerBeat: Double { 60.0 / Double(tempoBPM) }
    func windowSeconds(for note: Note) -> Double { note.durationBeats * secondsPerBeat }
}
```

- [ ] **Step 3: Create Lesson.swift**

```swift
enum Difficulty: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}

struct Lesson: Identifiable {
    let id: String          // e.g. "lesson-01"
    let title: String
    let difficulty: Difficulty
    let description: String
    let phrases: [Phrase]   // always 10

    var phraseCount: Int { phrases.count }
}
```

- [ ] **Step 4: Create PitchResult.swift**

```swift
enum PitchResult: Equatable {
    case onPitch                // within ±25 cents — the sole in-tune case
    case sharp(cents: Double)   // above target by >25 cents
    case flat(cents: Double)    // below target by >25 cents
    case undetected             // no pitch / silence

    var score: Double {
        switch self {
        case .onPitch:              return 1.0
        case .sharp(let c), .flat(let c):
            switch abs(c) {
            case 26.0...50.0:       return 0.6
            case 51.0...100.0:      return 0.3
            default:                return 0.0
            }
        case .undetected:           return 0.0
        }
    }

    var isOnPitch: Bool {
        if case .onPitch = self { return true }
        return false
    }
}
```

- [ ] **Step 5: Create LessonProgress.swift**

```swift
struct LessonProgress: Codable {
    let lessonID: String
    var bestStars: Int      // 0–3
}
```

- [ ] **Step 6: Commit**

```bash
git add EarTrainer/Models/
git commit -m "feat: add core data models"
```

---

## Task 3: PitchGrader (TDD)

**Files:**
- Create: `EarTrainer/Audio/PitchGrader.swift`
- Create: `EarTrainerTests/PitchGraderTests.swift`

The `PitchGrader` is pure logic — no AudioKit dependency. It converts a measured frequency to a `PitchResult` against a target, and computes phrase/lesson scores.

- [ ] **Step 1: Write failing tests**

Create `EarTrainerTests/PitchGraderTests.swift`:
```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

In Xcode: Product → Test (⌘U), or via CLI:
```bash
xcodebuild test -scheme EarTrainer -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:EarTrainerTests/PitchGraderTests 2>&1 | tail -20
```
Expected: Build fails — `PitchGrader` not defined yet.

- [ ] **Step 3: Implement PitchGrader**

Create `EarTrainer/Audio/PitchGrader.swift`:
```swift
import Foundation

enum PitchGrader {

    static func grade(measured: Double, target: Double) -> PitchResult {
        let cents = 1200.0 * log2(measured / target)
        if abs(cents) <= 25.0 {
            return .onPitch
        } else if cents > 0 {
            return .sharp(cents: cents)
        } else {
            return .flat(cents: abs(cents))
        }
    }

    static func gradeUndetected() -> PitchResult {
        return .undetected
    }

    static func phraseScore(_ results: [PitchResult]) -> Double {
        guard !results.isEmpty else { return 0.0 }
        return results.map(\.score).reduce(0, +) / Double(results.count)
    }

    static func lessonScore(phraseScores: [Double]) -> Double {
        guard !phraseScores.isEmpty else { return 0.0 }
        return phraseScores.reduce(0, +) / Double(phraseScores.count)
    }

    static func stars(forAverageScore score: Double) -> Int {
        switch score {
        case 0.90...:   return 3
        case 0.75...:   return 2
        case 0.50...:   return 1
        default:        return 0
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -scheme EarTrainer -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:EarTrainerTests/PitchGraderTests 2>&1 | tail -20
```
Expected: All 11 tests pass.

- [ ] **Step 5: Commit**

```bash
git add EarTrainer/Audio/PitchGrader.swift EarTrainerTests/PitchGraderTests.swift
git commit -m "feat: add PitchGrader with full unit test coverage"
```

---

## Task 4: Lesson Curriculum (TDD)

**Files:**
- Create: `EarTrainer/Curriculum/LessonCurriculum.swift`
- Create: `EarTrainerTests/LessonModelTests.swift`

- [ ] **Step 1: Write failing tests**

Create `EarTrainerTests/LessonModelTests.swift`:
```swift
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

    func test_lesson1_isUnlocked_byDefault() {
        // Lesson 1 should have id "lesson-01"
        XCTAssertEqual(LessonCurriculum.all[0].id, "lesson-01")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -scheme EarTrainer -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:EarTrainerTests/LessonModelTests 2>&1 | tail -20
```
Expected: Build fails — `LessonCurriculum` not defined.

- [ ] **Step 3: Implement LessonCurriculum**

Create `EarTrainer/Curriculum/LessonCurriculum.swift`:

```swift
import Foundation

// Convenience note constructors
private func note(_ solfege: String, midi: Int, beats: Double = 1.0) -> Note {
    Note(solfege: solfege, midiPitch: midi, durationBeats: beats)
}

// MIDI constants
private let Do  = 60  // C4
private let Re  = 62  // D4
private let Mi  = 64  // E4
private let Fa  = 65  // F4
private let Sol = 67  // G4
private let La  = 69  // A4
private let Ti  = 71  // B4
private let Do2 = 72  // C5

enum LessonCurriculum {

    static let all: [Lesson] = [
        lesson01, lesson02, lesson03, lesson04, lesson05, lesson06, lesson07,
        lesson08, lesson09, lesson10, lesson11, lesson12, lesson13, lesson14
    ]

    // MARK: - Lesson 1: Tonic & Dominant (Do, Sol)

    private static let lesson01 = Lesson(
        id: "lesson-01",
        title: "Tonic & Dominant",
        difficulty: .beginner,
        description: "The perfect 5th anchor: Do and Sol.",
        phrases: [
            Phrase(notes: [note("Do", midi: Do), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("Sol", midi: Sol), note("Do", midi: Do)], tempoBPM: 60),
            Phrase(notes: [note("Do", midi: Do), note("Sol", midi: Sol), note("Do", midi: Do)], tempoBPM: 60),
            Phrase(notes: [note("Sol", midi: Sol), note("Do", midi: Do), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("Do", midi: Do), note("Do", midi: Do), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("Sol", midi: Sol), note("Sol", midi: Sol), note("Do", midi: Do)], tempoBPM: 60),
            Phrase(notes: [note("Do", midi: Do), note("Sol", midi: Sol), note("Sol", midi: Sol), note("Do", midi: Do)], tempoBPM: 60),
            Phrase(notes: [note("Sol", midi: Sol), note("Do", midi: Do), note("Do", midi: Do), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("Do", midi: Do), note("Sol", midi: Sol), note("Do", midi: Do), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("Sol", midi: Sol), note("Do", midi: Do), note("Sol", midi: Sol), note("Do", midi: Do)], tempoBPM: 60),
        ]
    )

    // MARK: - Lesson 2: First Step Up (Do, Re)

    private static let lesson02 = Lesson(
        id: "lesson-02",
        title: "First Step Up",
        difficulty: .beginner,
        description: "Stepwise ascent from the tonic: Do and Re.",
        phrases: [
            Phrase(notes: [note("Do", midi: Do), note("Re", midi: Re)], tempoBPM: 60),
            Phrase(notes: [note("Re", midi: Re), note("Do", midi: Do)], tempoBPM: 60),
            Phrase(notes: [note("Do", midi: Do), note("Re", midi: Re), note("Do", midi: Do)], tempoBPM: 60),
            Phrase(notes: [note("Re", midi: Re), note("Do", midi: Do), note("Re", midi: Re)], tempoBPM: 60),
            Phrase(notes: [note("Do", midi: Do), note("Do", midi: Do), note("Re", midi: Re)], tempoBPM: 60),
            Phrase(notes: [note("Re", midi: Re), note("Re", midi: Re), note("Do", midi: Do)], tempoBPM: 60),
            Phrase(notes: [note("Do", midi: Do), note("Re", midi: Re), note("Re", midi: Re), note("Do", midi: Do)], tempoBPM: 60),
            Phrase(notes: [note("Re", midi: Re), note("Do", midi: Do), note("Do", midi: Do), note("Re", midi: Re)], tempoBPM: 60),
            Phrase(notes: [note("Do", midi: Do), note("Re", midi: Re), note("Do", midi: Do), note("Re", midi: Re)], tempoBPM: 60),
            Phrase(notes: [note("Re", midi: Re), note("Do", midi: Do), note("Re", midi: Re), note("Do", midi: Do)], tempoBPM: 60),
        ]
    )

    // MARK: - Lesson 3: Do Through Mi

    private static let lesson03 = Lesson(
        id: "lesson-03",
        title: "Do Through Mi",
        difficulty: .beginner,
        description: "Complete the lower tonic area: Do, Re, Mi.",
        phrases: [
            Phrase(notes: [note("Do", midi: Do), note("Re", midi: Re), note("Mi", midi: Mi)], tempoBPM: 60),
            Phrase(notes: [note("Mi", midi: Mi), note("Re", midi: Re), note("Do", midi: Do)], tempoBPM: 60),
            Phrase(notes: [note("Do", midi: Do), note("Mi", midi: Mi), note("Re", midi: Re)], tempoBPM: 60),
            Phrase(notes: [note("Re", midi: Re), note("Mi", midi: Mi), note("Do", midi: Do)], tempoBPM: 60),
            Phrase(notes: [note("Mi", midi: Mi), note("Do", midi: Do), note("Re", midi: Re)], tempoBPM: 60),
            Phrase(notes: [note("Do", midi: Do), note("Re", midi: Re), note("Mi", midi: Mi), note("Re", midi: Re)], tempoBPM: 60),
            Phrase(notes: [note("Mi", midi: Mi), note("Re", midi: Re), note("Do", midi: Do), note("Re", midi: Re)], tempoBPM: 60),
            Phrase(notes: [note("Do", midi: Do), note("Mi", midi: Mi), note("Re", midi: Re), note("Do", midi: Do)], tempoBPM: 60),
            Phrase(notes: [note("Re", midi: Re), note("Do", midi: Do), note("Mi", midi: Mi), note("Re", midi: Re)], tempoBPM: 60),
            Phrase(notes: [note("Do", midi: Do), note("Re", midi: Re), note("Mi", midi: Mi), note("Do", midi: Do)], tempoBPM: 60),
        ]
    )

    // MARK: - Lesson 4: Tonic Triad Leaps (Do, Mi, Sol)

    private static let lesson04 = Lesson(
        id: "lesson-04",
        title: "Tonic Triad Leaps",
        difficulty: .beginner,
        description: "Leap between Do, Mi, and Sol — the tonic triad.",
        phrases: [
            Phrase(notes: [note("Do", midi: Do), note("Mi", midi: Mi), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("Sol", midi: Sol), note("Mi", midi: Mi), note("Do", midi: Do)], tempoBPM: 60),
            Phrase(notes: [note("Do", midi: Do), note("Sol", midi: Sol), note("Mi", midi: Mi)], tempoBPM: 60),
            Phrase(notes: [note("Mi", midi: Mi), note("Do", midi: Do), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("Sol", midi: Sol), note("Do", midi: Do), note("Mi", midi: Mi)], tempoBPM: 60),
            Phrase(notes: [note("Do", midi: Do), note("Mi", midi: Mi), note("Sol", midi: Sol), note("Mi", midi: Mi)], tempoBPM: 60),
            Phrase(notes: [note("Sol", midi: Sol), note("Mi", midi: Mi), note("Do", midi: Do), note("Mi", midi: Mi)], tempoBPM: 60),
            Phrase(notes: [note("Mi", midi: Mi), note("Sol", midi: Sol), note("Do", midi: Do), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("Do", midi: Do), note("Sol", midi: Sol), note("Mi", midi: Mi), note("Do", midi: Do)], tempoBPM: 60),
            Phrase(notes: [note("Sol", midi: Sol), note("Do", midi: Do), note("Mi", midi: Mi), note("Sol", midi: Sol)], tempoBPM: 60),
        ]
    )

    // MARK: - Lesson 5: The Half-Step Pull (Mi, Fa)

    private static let lesson05 = Lesson(
        id: "lesson-05",
        title: "The Half-Step Pull",
        difficulty: .beginner,
        description: "The strongest tonal pull: Mi to Fa and back.",
        phrases: [
            Phrase(notes: [note("Mi", midi: Mi), note("Fa", midi: Fa)], tempoBPM: 60),
            Phrase(notes: [note("Fa", midi: Fa), note("Mi", midi: Mi)], tempoBPM: 60),
            Phrase(notes: [note("Mi", midi: Mi), note("Fa", midi: Fa), note("Mi", midi: Mi)], tempoBPM: 60),
            Phrase(notes: [note("Fa", midi: Fa), note("Mi", midi: Mi), note("Fa", midi: Fa)], tempoBPM: 60),
            Phrase(notes: [note("Mi", midi: Mi), note("Mi", midi: Mi), note("Fa", midi: Fa)], tempoBPM: 60),
            Phrase(notes: [note("Fa", midi: Fa), note("Fa", midi: Fa), note("Mi", midi: Mi)], tempoBPM: 60),
            Phrase(notes: [note("Mi", midi: Mi), note("Fa", midi: Fa), note("Fa", midi: Fa), note("Mi", midi: Mi)], tempoBPM: 60),
            Phrase(notes: [note("Fa", midi: Fa), note("Mi", midi: Mi), note("Mi", midi: Mi), note("Fa", midi: Fa)], tempoBPM: 60),
            Phrase(notes: [note("Mi", midi: Mi), note("Fa", midi: Fa), note("Mi", midi: Mi), note("Fa", midi: Fa)], tempoBPM: 60),
            Phrase(notes: [note("Fa", midi: Fa), note("Mi", midi: Mi), note("Fa", midi: Fa), note("Mi", midi: Mi)], tempoBPM: 60),
        ]
    )

    // MARK: - Lesson 6: Fa & Sol

    private static let lesson06 = Lesson(
        id: "lesson-06",
        title: "Fa & Sol",
        difficulty: .beginner,
        description: "Subdominant to dominant: Fa and Sol.",
        phrases: [
            Phrase(notes: [note("Fa", midi: Fa), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("Sol", midi: Sol), note("Fa", midi: Fa)], tempoBPM: 60),
            Phrase(notes: [note("Fa", midi: Fa), note("Sol", midi: Sol), note("Fa", midi: Fa)], tempoBPM: 60),
            Phrase(notes: [note("Sol", midi: Sol), note("Fa", midi: Fa), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("Fa", midi: Fa), note("Fa", midi: Fa), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("Sol", midi: Sol), note("Sol", midi: Sol), note("Fa", midi: Fa)], tempoBPM: 60),
            Phrase(notes: [note("Fa", midi: Fa), note("Sol", midi: Sol), note("Sol", midi: Sol), note("Fa", midi: Fa)], tempoBPM: 60),
            Phrase(notes: [note("Sol", midi: Sol), note("Fa", midi: Fa), note("Fa", midi: Fa), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("Fa", midi: Fa), note("Sol", midi: Sol), note("Fa", midi: Fa), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("Sol", midi: Sol), note("Fa", midi: Fa), note("Sol", midi: Sol), note("Fa", midi: Fa)], tempoBPM: 60),
        ]
    )

    // MARK: - Lesson 7: Do Through Sol (hexachord consolidation)

    private static let lesson07 = Lesson(
        id: "lesson-07",
        title: "Do Through Sol",
        difficulty: .intermediate,
        description: "Consolidate the lower hexachord: Do, Re, Mi, Fa, Sol.",
        phrases: [
            Phrase(notes: [note("Do", midi: Do), note("Re", midi: Re), note("Mi", midi: Mi), note("Fa", midi: Fa), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("Sol", midi: Sol), note("Fa", midi: Fa), note("Mi", midi: Mi), note("Re", midi: Re), note("Do", midi: Do)], tempoBPM: 60),
            Phrase(notes: [note("Do", midi: Do), note("Mi", midi: Mi), note("Sol", midi: Sol), note("Fa", midi: Fa), note("Mi", midi: Mi)], tempoBPM: 60),
            Phrase(notes: [note("Sol", midi: Sol), note("Mi", midi: Mi), note("Do", midi: Do), note("Re", midi: Re), note("Mi", midi: Mi)], tempoBPM: 60),
            Phrase(notes: [note("Mi", midi: Mi), note("Re", midi: Re), note("Do", midi: Do), note("Fa", midi: Fa), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("Do", midi: Do), note("Sol", midi: Sol), note("Fa", midi: Fa), note("Mi", midi: Mi), note("Do", midi: Do)], tempoBPM: 60),
            Phrase(notes: [note("Fa", midi: Fa), note("Mi", midi: Mi), note("Re", midi: Re), note("Do", midi: Do), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("Sol", midi: Sol), note("Do", midi: Do), note("Re", midi: Re), note("Mi", midi: Mi), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("Do", midi: Do), note("Fa", midi: Fa), note("Mi", midi: Mi), note("Sol", midi: Sol), note("Do", midi: Do)], tempoBPM: 55),
            Phrase(notes: [note("Sol", midi: Sol), note("Fa", midi: Fa), note("Do", midi: Do), note("Re", midi: Re), note("Sol", midi: Sol)], tempoBPM: 55),
        ]
    )

    // MARK: - Lesson 8: Sol & La

    private static let lesson08 = Lesson(
        id: "lesson-08",
        title: "Sol & La",
        difficulty: .intermediate,
        description: "Introduce La with one familiar companion: Sol.",
        phrases: [
            Phrase(notes: [note("Sol", midi: Sol), note("La", midi: La)], tempoBPM: 60),
            Phrase(notes: [note("La", midi: La), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("Sol", midi: Sol), note("La", midi: La), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("La", midi: La), note("Sol", midi: Sol), note("La", midi: La)], tempoBPM: 60),
            Phrase(notes: [note("Sol", midi: Sol), note("Sol", midi: Sol), note("La", midi: La)], tempoBPM: 60),
            Phrase(notes: [note("La", midi: La), note("La", midi: La), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("Sol", midi: Sol), note("La", midi: La), note("La", midi: La), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("La", midi: La), note("Sol", midi: Sol), note("Sol", midi: Sol), note("La", midi: La)], tempoBPM: 60),
            Phrase(notes: [note("Sol", midi: Sol), note("La", midi: La), note("Sol", midi: Sol), note("La", midi: La)], tempoBPM: 60),
            Phrase(notes: [note("La", midi: La), note("Sol", midi: Sol), note("La", midi: La), note("Sol", midi: Sol)], tempoBPM: 60),
        ]
    )

    // MARK: - Lesson 9: Do Through La

    private static let lesson09 = Lesson(
        id: "lesson-09",
        title: "Do Through La",
        difficulty: .intermediate,
        description: "Integrate La into the full lower scale.",
        phrases: [
            Phrase(notes: [note("Do", midi: Do), note("Re", midi: Re), note("Mi", midi: Mi), note("Fa", midi: Fa), note("Sol", midi: Sol), note("La", midi: La)], tempoBPM: 60),
            Phrase(notes: [note("La", midi: La), note("Sol", midi: Sol), note("Fa", midi: Fa), note("Mi", midi: Mi), note("Re", midi: Re), note("Do", midi: Do)], tempoBPM: 60),
            Phrase(notes: [note("Do", midi: Do), note("Mi", midi: Mi), note("Sol", midi: Sol), note("La", midi: La), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("La", midi: La), note("Sol", midi: Sol), note("Mi", midi: Mi), note("Do", midi: Do), note("Re", midi: Re)], tempoBPM: 60),
            Phrase(notes: [note("Mi", midi: Mi), note("Fa", midi: Fa), note("Sol", midi: Sol), note("La", midi: La), note("Sol", midi: Sol)], tempoBPM: 60),
            Phrase(notes: [note("Do", midi: Do), note("La", midi: La), note("Sol", midi: Sol), note("Fa", midi: Fa), note("Mi", midi: Mi)], tempoBPM: 55),
            Phrase(notes: [note("La", midi: La), note("Fa", midi: Fa), note("Mi", midi: Mi), note("Re", midi: Re), note("Do", midi: Do)], tempoBPM: 55),
            Phrase(notes: [note("Sol", midi: Sol), note("La", midi: La), note("Fa", midi: Fa), note("Mi", midi: Mi), note("Sol", midi: Sol)], tempoBPM: 55),
            Phrase(notes: [note("Do", midi: Do), note("Sol", midi: Sol), note("La", midi: La), note("Mi", midi: Mi), note("Do", midi: Do)], tempoBPM: 55),
            Phrase(notes: [note("La", midi: La), note("Mi", midi: Mi), note("Fa", midi: Fa), note("Sol", midi: Sol), note("Do", midi: Do)], tempoBPM: 55),
        ]
    )

    // MARK: - Lesson 10: La & Ti

    private static let lesson10 = Lesson(
        id: "lesson-10",
        title: "La & Ti",
        difficulty: .intermediate,
        description: "Introduce Ti with one familiar companion: La.",
        phrases: [
            Phrase(notes: [note("La", midi: La), note("Ti", midi: Ti)], tempoBPM: 60),
            Phrase(notes: [note("Ti", midi: Ti), note("La", midi: La)], tempoBPM: 60),
            Phrase(notes: [note("La", midi: La), note("Ti", midi: Ti), note("La", midi: La)], tempoBPM: 60),
            Phrase(notes: [note("Ti", midi: Ti), note("La", midi: La), note("Ti", midi: Ti)], tempoBPM: 60),
            Phrase(notes: [note("La", midi: La), note("La", midi: La), note("Ti", midi: Ti)], tempoBPM: 60),
            Phrase(notes: [note("Ti", midi: Ti), note("Ti", midi: Ti), note("La", midi: La)], tempoBPM: 60),
            Phrase(notes: [note("La", midi: La), note("Ti", midi: Ti), note("Ti", midi: Ti), note("La", midi: La)], tempoBPM: 60),
            Phrase(notes: [note("Ti", midi: Ti), note("La", midi: La), note("La", midi: La), note("Ti", midi: Ti)], tempoBPM: 60),
            Phrase(notes: [note("La", midi: La), note("Ti", midi: Ti), note("La", midi: La), note("Ti", midi: Ti)], tempoBPM: 60),
            Phrase(notes: [note("Ti", midi: Ti), note("La", midi: La), note("Ti", midi: Ti), note("La", midi: La)], tempoBPM: 60),
        ]
    )

    // MARK: - Lesson 11: Ti Resolves (Ti, Do')

    private static let lesson11 = Lesson(
        id: "lesson-11",
        title: "Ti Resolves",
        difficulty: .intermediate,
        description: "The leading tone resolving up to the tonic: Ti and Do'.",
        phrases: [
            Phrase(notes: [note("Ti", midi: Ti), note("Do'", midi: Do2)], tempoBPM: 60),
            Phrase(notes: [note("Do'", midi: Do2), note("Ti", midi: Ti)], tempoBPM: 60),
            Phrase(notes: [note("Ti", midi: Ti), note("Do'", midi: Do2), note("Ti", midi: Ti)], tempoBPM: 60),
            Phrase(notes: [note("Do'", midi: Do2), note("Ti", midi: Ti), note("Do'", midi: Do2)], tempoBPM: 60),
            Phrase(notes: [note("Ti", midi: Ti), note("Ti", midi: Ti), note("Do'", midi: Do2)], tempoBPM: 60),
            Phrase(notes: [note("Do'", midi: Do2), note("Do'", midi: Do2), note("Ti", midi: Ti)], tempoBPM: 60),
            Phrase(notes: [note("La", midi: La), note("Ti", midi: Ti), note("Do'", midi: Do2), note("Ti", midi: Ti)], tempoBPM: 60),
            Phrase(notes: [note("Do'", midi: Do2), note("Ti", midi: Ti), note("La", midi: La), note("Ti", midi: Ti)], tempoBPM: 60),
            Phrase(notes: [note("Ti", midi: Ti), note("Do'", midi: Do2), note("La", midi: La), note("Ti", midi: Ti)], tempoBPM: 60),
            Phrase(notes: [note("La", midi: La), note("Ti", midi: Ti), note("Do'", midi: Do2), note("Do'", midi: Do2)], tempoBPM: 60),
        ]
    )

    // MARK: - Lesson 12: Full Scale

    private static let lesson12 = Lesson(
        id: "lesson-12",
        title: "Full Scale",
        difficulty: .advanced,
        description: "Complete octave stepwise: Do through Do'.",
        phrases: [
            Phrase(notes: [note("Do", midi: Do), note("Re", midi: Re), note("Mi", midi: Mi), note("Fa", midi: Fa), note("Sol", midi: Sol), note("La", midi: La), note("Ti", midi: Ti), note("Do'", midi: Do2)], tempoBPM: 55),
            Phrase(notes: [note("Do'", midi: Do2), note("Ti", midi: Ti), note("La", midi: La), note("Sol", midi: Sol), note("Fa", midi: Fa), note("Mi", midi: Mi), note("Re", midi: Re), note("Do", midi: Do)], tempoBPM: 55),
            Phrase(notes: [note("Do", midi: Do), note("Mi", midi: Mi), note("Sol", midi: Sol), note("Ti", midi: Ti), note("Do'", midi: Do2)], tempoBPM: 55),
            Phrase(notes: [note("Do'", midi: Do2), note("La", midi: La), note("Fa", midi: Fa), note("Re", midi: Re), note("Do", midi: Do)], tempoBPM: 55),
            Phrase(notes: [note("Do", midi: Do), note("Re", midi: Re), note("Mi", midi: Mi), note("Fa", midi: Fa), note("Mi", midi: Mi), note("Re", midi: Re), note("Do", midi: Do)], tempoBPM: 55),
            Phrase(notes: [note("Sol", midi: Sol), note("La", midi: La), note("Ti", midi: Ti), note("Do'", midi: Do2), note("Ti", midi: Ti), note("La", midi: La), note("Sol", midi: Sol)], tempoBPM: 55),
            Phrase(notes: [note("Do", midi: Do), note("Fa", midi: Fa), note("Mi", midi: Mi), note("La", midi: La), note("Sol", midi: Sol), note("Do'", midi: Do2)], tempoBPM: 55),
            Phrase(notes: [note("Do'", midi: Do2), note("Sol", midi: Sol), note("La", midi: La), note("Mi", midi: Mi), note("Fa", midi: Fa), note("Do", midi: Do)], tempoBPM: 55),
            Phrase(notes: [note("Mi", midi: Mi), note("Re", midi: Re), note("Do", midi: Do), note("Ti", midi: Ti), note("La", midi: La), note("Sol", midi: Sol)], tempoBPM: 55),
            Phrase(notes: [note("Sol", midi: Sol), note("La", midi: La), note("Ti", midi: Ti), note("Do'", midi: Do2), note("La", midi: La), note("Fa", midi: Fa), note("Do", midi: Do)], tempoBPM: 55),
        ]
    )

    // MARK: - Lesson 13: Wider Leaps

    private static let lesson13 = Lesson(
        id: "lesson-13",
        title: "Wider Leaps",
        difficulty: .advanced,
        description: "Larger intervals and mixed motion across the full range.",
        phrases: [
            Phrase(notes: [note("Do", midi: Do), note("La", midi: La), note("Mi", midi: Mi), note("Sol", midi: Sol)], tempoBPM: 55),
            Phrase(notes: [note("Sol", midi: Sol), note("Ti", midi: Ti), note("Do", midi: Do), note("La", midi: La)], tempoBPM: 55),
            Phrase(notes: [note("Do", midi: Do), note("Do'", midi: Do2), note("Sol", midi: Sol), note("Mi", midi: Mi)], tempoBPM: 55),
            Phrase(notes: [note("La", midi: La), note("Do", midi: Do), note("Fa", midi: Fa), note("Do'", midi: Do2)], tempoBPM: 55),
            Phrase(notes: [note("Mi", midi: Mi), note("Do'", midi: Do2), note("Sol", midi: Sol), note("Ti", midi: Ti)], tempoBPM: 55),
            Phrase(notes: [note("Do", midi: Do), note("Ti", midi: Ti), note("Re", midi: Re), note("La", midi: La), note("Mi", midi: Mi)], tempoBPM: 50),
            Phrase(notes: [note("Sol", midi: Sol), note("Re", midi: Re), note("Do'", midi: Do2), note("Mi", midi: Mi), note("La", midi: La)], tempoBPM: 50),
            Phrase(notes: [note("Do'", midi: Do2), note("Fa", midi: Fa), note("Ti", midi: Ti), note("Do", midi: Do), note("La", midi: La)], tempoBPM: 50),
            Phrase(notes: [note("Re", midi: Re), note("Sol", midi: Sol), note("Do", midi: Do), note("Ti", midi: Ti), note("Mi", midi: Mi)], tempoBPM: 50),
            Phrase(notes: [note("Do", midi: Do), note("La", midi: La), note("Re", midi: Re), note("Ti", midi: Ti), note("Do'", midi: Do2)], tempoBPM: 50),
        ]
    )

    // MARK: - Lesson 14: Full Melodies

    private static let lesson14 = Lesson(
        id: "lesson-14",
        title: "Full Melodies",
        difficulty: .advanced,
        description: "Flowing melodic phrases combining all solfege syllables.",
        phrases: [
            Phrase(notes: [note("Do", midi: Do), note("Re", midi: Re), note("Mi", midi: Mi), note("Sol", midi: Sol), note("Fa", midi: Fa), note("Mi", midi: Mi), note("Re", midi: Re), note("Do", midi: Do)], tempoBPM: 55),
            Phrase(notes: [note("Mi", midi: Mi), note("Sol", midi: Sol), note("La", midi: La), note("Ti", midi: Ti), note("Do'", midi: Do2), note("Ti", midi: Ti), note("La", midi: La), note("Sol", midi: Sol)], tempoBPM: 55),
            Phrase(notes: [note("Do", midi: Do), note("Mi", midi: Mi), note("Sol", midi: Sol), note("Fa", midi: Fa), note("Mi", midi: Mi), note("Re", midi: Re), note("Do", midi: Do)], tempoBPM: 55),
            Phrase(notes: [note("Sol", midi: Sol), note("La", midi: La), note("Sol", midi: Sol), note("Fa", midi: Fa), note("Mi", midi: Mi), note("Do", midi: Do)], tempoBPM: 55),
            Phrase(notes: [note("Do", midi: Do), note("Re", midi: Re), note("Mi", midi: Mi), note("La", midi: La), note("Sol", midi: Sol), note("Fa", midi: Fa), note("Mi", midi: Mi)], tempoBPM: 55),
            Phrase(notes: [note("Mi", midi: Mi), note("Re", midi: Re), note("Do", midi: Do), note("Fa", midi: Fa), note("Mi", midi: Mi), note("La", midi: La), note("Sol", midi: Sol)], tempoBPM: 50),
            Phrase(notes: [note("Do", midi: Do), note("Sol", midi: Sol), note("La", midi: La), note("Ti", midi: Ti), note("Do'", midi: Do2), note("La", midi: La), note("Sol", midi: Sol), note("Mi", midi: Mi)], tempoBPM: 50),
            Phrase(notes: [note("La", midi: La), note("Sol", midi: Sol), note("Mi", midi: Mi), note("Fa", midi: Fa), note("Re", midi: Re), note("Mi", midi: Mi), note("Do", midi: Do)], tempoBPM: 50),
            Phrase(notes: [note("Do", midi: Do), note("Mi", midi: Mi), note("La", midi: La), note("Sol", midi: Sol), note("Ti", midi: Ti), note("Do'", midi: Do2), note("Ti", midi: Ti), note("Sol", midi: Sol)], tempoBPM: 50),
            Phrase(notes: [note("Sol", midi: Sol), note("Fa", midi: Fa), note("Mi", midi: Mi), note("Re", midi: Re), note("Mi", midi: Mi), note("La", midi: La), note("Sol", midi: Sol), note("Do", midi: Do)], tempoBPM: 50),
        ]
    )
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -scheme EarTrainer -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:EarTrainerTests/LessonModelTests 2>&1 | tail -20
```
Expected: All 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add EarTrainer/Curriculum/LessonCurriculum.swift EarTrainerTests/LessonModelTests.swift
git commit -m "feat: add 14-lesson curriculum with TDD coverage"
```

---

## Task 5: Progress Store

**Files:**
- Create: `EarTrainer/Storage/ProgressStore.swift`

- [ ] **Step 1: Implement ProgressStore**

```swift
import Foundation

final class ProgressStore: ObservableObject {

    private let key = "lessonProgress"
    @Published private(set) var progressByID: [String: LessonProgress] = [:]

    init() {
        load()
        // Lesson 1 is always unlocked — seed it if absent
        if progressByID["lesson-01"] == nil {
            progressByID["lesson-01"] = LessonProgress(lessonID: "lesson-01", bestStars: 0)
            save()
        }
    }

    func bestStars(for lessonID: String) -> Int {
        progressByID[lessonID]?.bestStars ?? 0
    }

    func isUnlocked(_ lesson: Lesson, in curriculum: [Lesson]) -> Bool {
        if lesson.id == "lesson-01" { return true }
        guard let idx = curriculum.firstIndex(where: { $0.id == lesson.id }), idx > 0 else { return false }
        let previous = curriculum[idx - 1]
        return bestStars(for: previous.id) >= 3
    }

    func record(lessonID: String, stars: Int) {
        let current = progressByID[lessonID]?.bestStars ?? 0
        if stars > current {
            progressByID[lessonID] = LessonProgress(lessonID: lessonID, bestStars: stars)
            save()
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: LessonProgress].self, from: data)
        else { return }
        progressByID = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(progressByID) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add EarTrainer/Storage/ProgressStore.swift
git commit -m "feat: add UserDefaults-backed progress store"
```

---

## Task 6: Audio Engine

**Files:**
- Create: `EarTrainer/Audio/AudioEngine.swift`

The `AudioEngine` wraps AudioKit. It owns: the microphone input, `PitchTap` (YIN pitch detection), a sine wave `Oscillator` for the reference tone, and a metronome for count-in. It publishes the current pitch reading so the UI can react.

**Note:** The Audio Engine cannot be unit tested with XCTest (no microphone in simulator). Test manually using a real device or simulator with system audio.

- [ ] **Step 1: Implement AudioEngine**

```swift
import AudioKit
import AudioKitEX
import AVFoundation
import Combine

@MainActor
final class AudioEngine: ObservableObject {

    // MARK: - Published state
    @Published var currentFrequency: Double = 0      // 0 = no pitch detected
    @Published var currentAmplitude: Double = 0
    @Published var isRecording: Bool = false

    // MARK: - AudioKit nodes
    private let engine = AudioKit.AudioEngine()
    private var mic: AudioEngine.InputNode!
    private var pitchTap: PitchTap!
    private var oscillator: DynamicOscillator!
    private var mixer: Mixer!

    // MARK: - Metronome / count-in
    private var metronome: AppleSequencer?
    private var countInTimer: Timer?

    // MARK: - Configuration
    private let amplitudeThreshold: Double = 0.1

    // MARK: - Setup

    func setup() throws {
        guard let inputNode = engine.input else {
            throw AudioEngineError.microphoneUnavailable
        }
        mic = inputNode

        oscillator = DynamicOscillator()
        oscillator.amplitude = 0

        mixer = Mixer(mic, oscillator)
        engine.output = mixer

        pitchTap = PitchTap(mic) { [weak self] freq, amp in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if amp[0] > Float(self.amplitudeThreshold) {
                    self.currentFrequency = Double(freq[0])
                    self.currentAmplitude = Double(amp[0])
                } else {
                    self.currentFrequency = 0
                    self.currentAmplitude = 0
                }
            }
        }

        try engine.start()
    }

    // MARK: - Reference pitch playback

    /// Plays the given MIDI pitch for `duration` seconds, then stops.
    func playReferencePitch(midiPitch: Int, duration: Double = 1.0) {
        let freq = 440.0 * pow(2.0, Double(midiPitch - 69) / 12.0)
        oscillator.frequency = AUValue(freq)
        oscillator.amplitude = 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.oscillator.amplitude = 0
        }
    }

    // MARK: - Count-in + recording

    /// Plays a single click sound using AVAudioEngine's system sound as a metronome tick.
    private func playClick() {
        // Use AudioKit's oscillator for a short tick: 1000 Hz for 50ms
        oscillator.frequency = 1000
        oscillator.amplitude = 0.4
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.oscillator.amplitude = 0
        }
    }

    /// Calls `onBeat` for each of 4 count-in beats (with audible click), then `onStart` when recording begins.
    func countInThenRecord(tempoBPM: Int, onBeat: @escaping (Int) -> Void, onStart: @escaping () -> Void) {
        let beatDuration = 60.0 / Double(tempoBPM)
        var beat = 1
        countInTimer = Timer.scheduledTimer(withTimeInterval: beatDuration, repeats: true) { [weak self] timer in
            self?.playClick()
            onBeat(beat)
            beat += 1
            if beat > 4 {
                timer.invalidate()
                self?.startRecording()
                Task { @MainActor in onStart() }
            }
        }
    }

    func startRecording() {
        pitchTap.start()
        isRecording = true
    }

    func stopRecording() {
        pitchTap.stop()
        isRecording = false
        currentFrequency = 0
        currentAmplitude = 0
    }

    // MARK: - Teardown

    func stop() {
        stopRecording()
        countInTimer?.invalidate()
        engine.stop()
    }
}

enum AudioEngineError: Error {
    case microphoneUnavailable
}
```

- [ ] **Step 2: Commit**

```bash
git add EarTrainer/Audio/AudioEngine.swift
git commit -m "feat: add AudioKit-backed audio engine with pitch detection and count-in"
```

---

## Task 7: Staff View

**Files:**
- Create: `EarTrainer/Views/StaffView.swift`

Renders a treble clef staff using SwiftUI `Canvas`, with noteheads positioned by pitch, solfege labels below, highlight for current note, and result indicators above.

Staff line spacing: 10 pt. Five lines. Total staff height = 4 × lineSpacing = 40 pt. Canvas is tall enough to accommodate the ledger line for C4 below the staff and result indicators above.

Staff position mapping (slots from bottom line, 0-indexed, each slot = lineSpacing/2):
- E4 (Mi) = slot 0 (bottom line)
- F4 (Fa) = slot 1
- G4 (Sol) = slot 2
- A4 (La) = slot 3
- B4 (Ti) = slot 4
- C5 (Do') = slot 5
- D4 (Re) = slot -1
- C4 (Do) = slot -2 (ledger line)

- [ ] **Step 1: Implement StaffView**

```swift
import SwiftUI

struct StaffView: View {

    let notes: [Note]
    let showSolfege: Bool
    var highlightedIndex: Int? = nil
    var results: [PitchResult?] = []   // same count as notes, nil = not yet graded

    private let lineSpacing: CGFloat = 10
    private let noteRadius: CGFloat = 7
    private let staffLeftPad: CGFloat = 50   // space for treble clef
    private let noteSpacing: CGFloat = 60

    var body: some View {
        Canvas { ctx, size in
            drawStaff(ctx: ctx, size: size)
            drawTrebleClef(ctx: ctx, size: size)
            for (i, note) in notes.enumerated() {
                drawNote(ctx: ctx, size: size, note: note, index: i)
            }
        }
        .frame(height: canvasHeight)
    }

    private var canvasHeight: CGFloat {
        // above staff: result indicators (30) + space (10)
        // staff: 4 × lineSpacing = 40
        // below staff: ledger line zone (30) + solfege (20)
        return 40 + 4 * lineSpacing + 60
    }

    private var staffTopY: CGFloat { 40 }   // room for result indicators above

    // Y position of a staff slot (0 = bottom line of staff)
    private func yForSlot(_ slot: Int) -> CGFloat {
        let bottomLineY = staffTopY + 4 * lineSpacing
        return bottomLineY - CGFloat(slot) * (lineSpacing / 2)
    }

    private func slotForMIDI(_ midi: Int) -> Int {
        // E4 = MIDI 64 = slot 0; each semitone maps to chromatic slot
        let slotMap: [Int: Int] = [60: -2, 62: -1, 64: 0, 65: 1, 67: 2, 69: 3, 71: 4, 72: 5]
        return slotMap[midi] ?? 0
    }

    private func xForNote(at index: Int) -> CGFloat {
        staffLeftPad + CGFloat(index) * noteSpacing + noteSpacing / 2
    }

    private func drawStaff(ctx: GraphicsContext, size: CGSize) {
        for line in 0..<5 {
            let y = staffTopY + CGFloat(line) * lineSpacing
            var path = Path()
            path.move(to: CGPoint(x: 10, y: y))
            path.addLine(to: CGPoint(x: size.width - 10, y: y))
            ctx.stroke(path, with: .color(.primary), lineWidth: 1)
        }
    }

    private func drawTrebleClef(ctx: GraphicsContext, size: CGSize) {
        // Simplified: draw "𝄞" as a text symbol positioned on the staff
        ctx.draw(
            Text("𝄞").font(.system(size: 60)).foregroundColor(.primary),
            at: CGPoint(x: 20, y: staffTopY + lineSpacing * 2),
            anchor: .leading
        )
    }

    private func drawNote(ctx: GraphicsContext, size: CGSize, note: Note, index: Int) {
        let slot = slotForMIDI(note.midiPitch)
        let x = xForNote(at: index)
        let y = yForSlot(slot)
        let isHighlighted = highlightedIndex == index

        // Ledger line for C4 (slot -2)
        if slot == -2 {
            var ledger = Path()
            ledger.move(to: CGPoint(x: x - noteRadius - 4, y: y))
            ledger.addLine(to: CGPoint(x: x + noteRadius + 4, y: y))
            ctx.stroke(ledger, with: .color(.primary), lineWidth: 1)
        }

        // Notehead
        let rect = CGRect(x: x - noteRadius, y: y - noteRadius * 0.75,
                          width: noteRadius * 2, height: noteRadius * 1.5)
        let ellipse = Path(ellipseIn: rect)
        let fillColor: Color = isHighlighted ? .yellow : .primary
        ctx.fill(ellipse, with: .color(fillColor))

        // Stem (upward for notes below middle line, downward above)
        let stemUp = slot < 2
        let stemX = stemUp ? x + noteRadius - 1 : x - noteRadius + 1
        let stemEndY = stemUp ? y - lineSpacing * 3 : y + lineSpacing * 3
        var stem = Path()
        stem.move(to: CGPoint(x: stemX, y: y))
        stem.addLine(to: CGPoint(x: stemX, y: stemEndY))
        ctx.stroke(stem, with: .color(fillColor), lineWidth: 1.5)

        // Solfege label below
        if showSolfege {
            let labelY = yForSlot(-3) + 10
            ctx.draw(
                Text(note.solfege).font(.caption2).foregroundColor(.secondary),
                at: CGPoint(x: x, y: labelY),
                anchor: .center
            )
        }

        // Result indicator above
        if index < results.count, let result = results[index] {
            let indicatorY = staffTopY - 20
            let indicatorView = NoteResultIndicator(result: result)
            // Render SwiftUI view snapshot into canvas
            let resolved = ctx.resolve(Text(indicatorSymbol(result))
                .font(.caption.bold())
                .foregroundColor(indicatorColor(result)))
            ctx.draw(resolved, at: CGPoint(x: x, y: indicatorY), anchor: .center)
        }
    }

    private func indicatorSymbol(_ result: PitchResult) -> String {
        switch result {
        case .onPitch:       return "✓"
        case .sharp:         return "♯"
        case .flat:          return "♭"
        case .undetected:    return "–"
        }
    }

    private func indicatorColor(_ result: PitchResult) -> Color {
        switch result {
        case .onPitch:       return .green
        case .sharp(let c), .flat(let c):
            switch abs(c) {
            case 0...50:    return .yellow
            case 51...100:  return .orange
            default:        return .red
            }
        case .undetected:    return .gray
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add EarTrainer/Views/StaffView.swift
git commit -m "feat: add Canvas-based staff view with note rendering"
```

---

## Task 8: Pitch Indicator View

**Files:**
- Create: `EarTrainer/Views/PitchIndicatorView.swift`
- Create: `EarTrainer/Views/NoteResultIndicator.swift`

- [ ] **Step 1: Implement PitchIndicatorView**

Real-time indicator shown during recording. Takes the current measured frequency and target frequency.

```swift
import SwiftUI

struct PitchIndicatorView: View {

    let measuredFrequency: Double   // 0 = no pitch
    let targetFrequency: Double

    private var result: PitchResult {
        guard measuredFrequency > 0 else { return .undetected }
        return PitchGrader.grade(measured: measuredFrequency, target: targetFrequency)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .frame(width: 80, height: 80)

            VStack(spacing: 2) {
                Text(symbol)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                if case .sharp(let c) = result {
                    Text("\(Int(c))¢")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                } else if case .flat(let c) = result {
                    Text("\(Int(c))¢")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }

    private var symbol: String {
        switch result {
        case .onPitch:    return "✓"
        case .sharp:      return "♯"
        case .flat:       return "♭"
        case .undetected: return "–"
        }
    }

    private var backgroundColor: Color {
        switch result {
        case .onPitch:    return .green
        case .sharp(let c), .flat(let c):
            switch abs(c) {
            case 0...50:  return .yellow
            case 51...100: return .orange
            default:      return .red
            }
        case .undetected: return Color(.systemGray4)
        }
    }
}
```

- [ ] **Step 2: Implement NoteResultIndicator**

Small post-phrase indicator shown above each note on the staff (used by StaffView).

```swift
import SwiftUI

struct NoteResultIndicator: View {
    let result: PitchResult

    var body: some View {
        Text(symbol)
            .font(.caption.bold())
            .foregroundColor(color)
    }

    private var symbol: String {
        switch result {
        case .onPitch:    return "✓"
        case .sharp:      return "♯"
        case .flat:       return "♭"
        case .undetected: return "–"
        }
    }

    private var color: Color {
        switch result {
        case .onPitch:    return .green
        case .sharp(let c), .flat(let c):
            switch abs(c) {
            case 0...50:  return .yellow
            case 51...100: return .orange
            default:      return .red
            }
        case .undetected: return .gray
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add EarTrainer/Views/PitchIndicatorView.swift EarTrainer/Views/NoteResultIndicator.swift
git commit -m "feat: add real-time pitch indicator and per-note result views"
```

---

## Task 9: Lesson Browser View

**Files:**
- Create: `EarTrainer/Views/LessonBrowserView.swift`
- Create: `EarTrainer/Views/LessonCardView.swift`

- [ ] **Step 1: Implement LessonCardView**

```swift
import SwiftUI

struct LessonCardView: View {

    let lesson: Lesson
    let stars: Int           // 0–3 earned
    let isUnlocked: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title)
                    .font(.headline)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                Text(lesson.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            if isUnlocked {
                HStack(spacing: 2) {
                    ForEach(1...3, id: \.self) { i in
                        Image(systemName: i <= stars ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .opacity(isUnlocked ? 1.0 : 0.5)
    }
}
```

- [ ] **Step 2: Implement LessonBrowserView**

```swift
import SwiftUI

struct LessonBrowserView: View {

    @StateObject private var store = ProgressStore()
    private let curriculum = LessonCurriculum.all

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(curriculum) { lesson in
                        let unlocked = store.isUnlocked(lesson, in: curriculum)
                        let stars = store.bestStars(for: lesson.id)
                        Group {
                            if unlocked {
                                NavigationLink(destination: ExerciseView(lesson: lesson, store: store)) {
                                    LessonCardView(lesson: lesson, stars: stars, isUnlocked: true)
                                }
                                .buttonStyle(.plain)
                            } else {
                                LessonCardView(lesson: lesson, stars: stars, isUnlocked: false)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Ear Trainer")
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add EarTrainer/Views/LessonBrowserView.swift EarTrainer/Views/LessonCardView.swift
git commit -m "feat: add lesson browser with star ratings and lock state"
```

---

## Task 10: Exercise View

**Files:**
- Create: `EarTrainer/Views/ExerciseView.swift`

The `ExerciseView` manages the three-phase state machine: Preview → Recording → Results, cycling through all 10 phrases and collecting scores.

- [ ] **Step 1: Implement ExerciseView**

```swift
import SwiftUI

struct ExerciseView: View {

    let lesson: Lesson
    let store: ProgressStore

    @StateObject private var audioEngine = AudioEngine()
    @State private var phase: Phase = .preview
    @State private var currentPhraseIndex = 0
    @State private var currentNoteIndex: Int? = nil
    @State private var noteResults: [PitchResult?] = []
    @State private var phraseScores: [Double] = []
    @State private var showSolfege = true
    @State private var beatCount = 0
    @State private var pitchSamples: [Double] = []
    @State private var noteTimer: Timer? = nil
    @State private var micPermissionDenied = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    enum Phase { case preview, countIn, recording, results, lessonComplete }

    private var currentPhrase: Phrase { lesson.phrases[currentPhraseIndex] }

    var body: some View {
        VStack(spacing: 20) {
            // Solfege toggle
            HStack {
                Spacer()
                Toggle("Solfege", isOn: $showSolfege)
                    .toggleStyle(.button)
                    .font(.caption)
            }
            .padding(.horizontal)

            // Staff
            ScrollView(.horizontal, showsIndicators: false) {
                StaffView(
                    notes: currentPhrase.notes,
                    showSolfege: showSolfege,
                    highlightedIndex: currentNoteIndex,
                    results: phase == .results ? noteResults.map { $0 } : Array(repeating: nil, count: currentPhrase.notes.count)
                )
                .padding(.horizontal)
            }

            // Phase-specific UI
            switch phase {
            case .preview:
                previewUI
            case .countIn:
                countInUI
            case .recording:
                recordingUI
            case .results:
                resultsUI
            case .lessonComplete:
                EmptyView()
            }

            Spacer()
        }
        .navigationTitle("Exercise \(currentPhraseIndex + 1) of \(lesson.phrases.count)")
        .navigationBarTitleDisplayMode(.inline)
        .task { await setupAudio() }
        .onDisappear { audioEngine.stop() }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background, phase == .recording || phase == .countIn {
                audioEngine.stopRecording()
                noteTimer?.invalidate()
                resetToPreview()
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { phase == .lessonComplete },
            set: { _ in }
        )) {
            LessonResultView(
                lesson: lesson,
                phraseScores: phraseScores,
                store: store
            )
        }
        .alert("Microphone Access Required",
               isPresented: $micPermissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { dismiss() }
        } message: {
            Text("EarTrainer needs microphone access to grade your singing. Enable it in Settings.")
        }
    }

    // MARK: - Sub-views

    private var previewUI: some View {
        Button("Sing") {
            startCountIn()
        }
        .buttonStyle(.borderedProminent)
        .font(.title2)
    }

    private var countInUI: some View {
        VStack {
            Text("Get ready...")
                .font(.headline)
            HStack(spacing: 12) {
                ForEach(1...4, id: \.self) { i in
                    Circle()
                        .fill(i <= beatCount ? Color.accentColor : Color(.systemGray4))
                        .frame(width: 20, height: 20)
                }
            }
        }
    }

    private var recordingUI: some View {
        VStack(spacing: 16) {
            PitchIndicatorView(
                measuredFrequency: audioEngine.currentFrequency,
                targetFrequency: currentNoteIndex.map { currentPhrase.notes[$0].frequency } ?? 0
            )
            Text("Sing!")
                .font(.title2.bold())
                .foregroundColor(.accentColor)
        }
    }

    private var resultsUI: some View {
        VStack(spacing: 12) {
            let score = PitchGrader.phraseScore(noteResults.map { $0 ?? .undetected })
            Text("Score: \(Int(score * 100))%")
                .font(.title2.bold())

            HStack(spacing: 16) {
                Button("Try Again") {
                    resetPhrase()
                }
                .buttonStyle(.bordered)

                Button(currentPhraseIndex + 1 < lesson.phrases.count ? "Next Exercise" : "Finish") {
                    advanceOrFinish()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Logic

    private func setupAudio() async {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            try? audioEngine.setup()
            audioEngine.playReferencePitch(midiPitch: 60) // Play Do on load
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            if granted { try? audioEngine.setup(); audioEngine.playReferencePitch(midiPitch: 60) }
            else { micPermissionDenied = true }
        default:
            micPermissionDenied = true
        }
    }

    private func startCountIn() {
        phase = .countIn
        beatCount = 0
        audioEngine.countInThenRecord(tempoBPM: currentPhrase.tempoBPM) { beat in
            Task { @MainActor in self.beatCount = beat }
        } onStart: {
            self.beginRecording()
        }
    }

    private func beginRecording() {
        phase = .recording
        currentNoteIndex = 0
        noteResults = Array(repeating: nil, count: currentPhrase.notes.count)
        pitchSamples = []
        scheduleNoteAdvance(noteIndex: 0)
    }

    private func scheduleNoteAdvance(noteIndex: Int) {
        guard noteIndex < currentPhrase.notes.count else {
            finishRecording()
            return
        }
        let note = currentPhrase.notes[noteIndex]
        let windowSeconds = currentPhrase.windowSeconds(for: note)
        let attackSkip = 0.05
        let releaseSkip = 0.03
        let sampleWindow = windowSeconds - attackSkip - releaseSkip

        // Skip attack, then collect samples, then advance
        DispatchQueue.main.asyncAfter(deadline: .now() + attackSkip) {
            self.pitchSamples = []
            let sampleInterval = 0.02  // 50 Hz sample rate
            let sampleCount = Int(sampleWindow / sampleInterval)
            var sampled = 0

            self.noteTimer = Timer.scheduledTimer(withTimeInterval: sampleInterval, repeats: true) { timer in
                let freq = self.audioEngine.currentFrequency
                if freq > 0 { self.pitchSamples.append(freq) }
                sampled += 1
                if sampled >= sampleCount {
                    timer.invalidate()
                    self.gradeCurrentNote(noteIndex: noteIndex, targetNote: note)
                    self.currentNoteIndex = noteIndex + 1
                    self.scheduleNoteAdvance(noteIndex: noteIndex + 1)
                }
            }
        }
    }

    private func gradeCurrentNote(noteIndex: Int, targetNote: Note) {
        let validSamples = pitchSamples.filter { $0 > 0 }
        let result: PitchResult
        if validSamples.isEmpty {
            result = .undetected
        } else {
            let avg = validSamples.reduce(0, +) / Double(validSamples.count)
            result = PitchGrader.grade(measured: avg, target: targetNote.frequency)
        }
        noteResults[noteIndex] = result
    }

    private func finishRecording() {
        audioEngine.stopRecording()
        noteTimer?.invalidate()
        let score = PitchGrader.phraseScore(noteResults.map { $0 ?? .undetected })
        phraseScores.append(score)
        phase = .results
    }

    private func resetPhrase() {
        noteResults = []
        pitchSamples = []
        currentNoteIndex = nil
        phraseScores.removeLast()
        audioEngine.playReferencePitch(midiPitch: 60)
        phase = .preview
    }

    /// Called when app is backgrounded during recording — discards attempt, no score saved.
    private func resetToPreview() {
        noteTimer?.invalidate()
        noteResults = []
        pitchSamples = []
        currentNoteIndex = nil
        beatCount = 0
        phase = .preview
    }

    private func advanceOrFinish() {
        if currentPhraseIndex + 1 < lesson.phrases.count {
            currentPhraseIndex += 1
            noteResults = []
            pitchSamples = []
            currentNoteIndex = nil
            audioEngine.playReferencePitch(midiPitch: 60)
            phase = .preview
        } else {
            phase = .lessonComplete
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add EarTrainer/Views/ExerciseView.swift
git commit -m "feat: add exercise view with three-phase state machine"
```

---

## Task 11: Lesson Result View

**Files:**
- Create: `EarTrainer/Views/LessonResultView.swift`

Shown after all 10 exercises. Computes star rating, saves to store, and unlocks next lesson immediately.

- [ ] **Step 1: Implement LessonResultView**

```swift
import SwiftUI

struct LessonResultView: View {

    let lesson: Lesson
    let phraseScores: [Double]
    let store: ProgressStore

    @Environment(\.dismiss) private var dismiss

    private var averageScore: Double {
        PitchGrader.lessonScore(phraseScores: phraseScores)
    }

    private var stars: Int {
        PitchGrader.stars(forAverageScore: averageScore)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(lesson.title)
                .font(.title.bold())

            // Star display
            HStack(spacing: 12) {
                ForEach(1...3, id: \.self) { i in
                    Image(systemName: i <= stars ? "star.fill" : "star")
                        .font(.system(size: 44))
                        .foregroundColor(.yellow)
                }
            }

            Text("\(Int(averageScore * 100))% average")
                .font(.title2)
                .foregroundColor(.secondary)

            if stars < 3 {
                Text("3 stars required to unlock the next lesson.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            HStack(spacing: 16) {
                Button("Try Again") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                if stars == 3 {
                    Button("Next Lesson") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .onAppear {
            store.record(lessonID: lesson.id, stars: stars)
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add EarTrainer/Views/LessonResultView.swift
git commit -m "feat: add lesson result view with star rating and unlock logic"
```

---

## Task 12: UI Flow Tests

**Files:**
- Create: `EarTrainerUITests/ExerciseFlowTests.swift`

- [ ] **Step 1: Write UI tests**

```swift
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
```

- [ ] **Step 2: Run UI tests**

```bash
xcodebuild test -scheme EarTrainer -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:EarTrainerUITests/ExerciseFlowTests 2>&1 | tail -30
```
Expected: All 5 tests pass.

- [ ] **Step 3: Commit**

```bash
git add EarTrainerUITests/ExerciseFlowTests.swift
git commit -m "test: add UI flow tests for lesson browser and exercise navigation"
```

---

## Task 13: Manual Integration Testing Checklist

Run on a **real device** (microphone does not work meaningfully in simulator).

- [ ] **Microphone permission prompt appears on first launch**
- [ ] **Lesson 1 is unlocked; Lesson 2 is locked**
- [ ] **Tapping Lesson 1 opens Exercise 1 of 10**
- [ ] **Reference pitch (Do) plays automatically on exercise load**
- [ ] **Tapping Sing triggers 4 metronome count-in beats**
- [ ] **Beat indicator pulses with the count-in**
- [ ] **Pitch indicator turns green when singing near C4 (Do)**
- [ ] **Pitch indicator shows ♭ and turns red when singing flat**
- [ ] **Pitch indicator shows ♯ and turns red when singing sharp**
- [ ] **Current note on staff is highlighted during recording**
- [ ] **Per-note result indicators appear above staff after phrase ends**
- [ ] **Phrase score displayed as percentage after recording**
- [ ] **"Try Again" resets phrase (no score saved), replays reference pitch**
- [ ] **After 10 exercises, Lesson Result View appears**
- [ ] **Star rating matches expected score range**
- [ ] **3-star score unlocks Lesson 2 immediately on result screen**
- [ ] **Returning to browser shows updated star count for Lesson 1**
- [ ] **Stars persist across app restarts**
- [ ] **Backgrounding app during recording discards attempt and returns to Phase 1**
- [ ] **Solfege toggle hides/shows syllables on staff**

- [ ] **Commit final state**

```bash
git add -A
git commit -m "feat: complete sight singing trainer v1"
```

---

## Dependency Summary

Add via Xcode's Swift Package Manager (File → Add Packages):
- AudioKit: `https://github.com/AudioKit/AudioKit` — from 5.6.0
- AudioKitEX: `https://github.com/AudioKit/AudioKitEX` — from 5.6.0

(Handled automatically by `project.yml` / XcodeGen in Task 1.)
