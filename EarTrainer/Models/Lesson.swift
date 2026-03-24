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
