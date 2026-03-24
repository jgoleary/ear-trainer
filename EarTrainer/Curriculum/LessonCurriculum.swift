import Foundation

// Convenience note constructor
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

    // MARK: - Lesson 7: Do Through Sol

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
