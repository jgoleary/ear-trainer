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
            case ..<51:   return .yellow
            case ..<101:  return .orange
            default:      return .red
            }
        case .undetected: return .gray
        }
    }
}
