import Foundation

enum PitchGrader {

    // MARK: - Grading

    static func grade(measured: Double, target: Double) -> PitchResult {
        guard measured > 0, target > 0 else { return .undetected }
        let cents = 1200.0 * log2(measured / target)
        if abs(cents) <= 25.0 {
            return .onPitch
        } else if cents > 0 {
            return .sharp(cents: cents)
        } else {
            return .flat(cents: abs(cents))
        }
    }

    // MARK: - Aggregation

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
