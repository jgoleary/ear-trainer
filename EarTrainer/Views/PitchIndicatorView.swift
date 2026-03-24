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
            case ..<51:   return .yellow
            case ..<101:  return .orange
            default:      return .red
            }
        case .undetected: return Color(.systemGray4)
        }
    }
}
