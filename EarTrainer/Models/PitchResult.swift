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
