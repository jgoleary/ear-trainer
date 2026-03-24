enum PitchResult {
    case onPitch                // within ±25 cents
    case sharp(cents: Double)   // above target by cents
    case flat(cents: Double)    // below target by cents
    case undetected             // no pitch / silence

    var score: Double {
        switch self {
        case .onPitch:              return 1.0
        case .sharp(let c), .flat(let c):
            switch abs(c) {
            case 0...25:            return 1.0
            case 26...50:           return 0.6
            case 51...100:          return 0.3
            default:                return 0.0
            }
        case .undetected:           return 0.0
        }
    }

    var isOnPitch: Bool {
        if case .onPitch = self { return true }
        if case .sharp(let c) = self, abs(c) <= 25 { return true }
        if case .flat(let c) = self, abs(c) <= 25 { return true }
        return false
    }
}
