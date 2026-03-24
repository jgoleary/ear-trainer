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
        // below staff: ledger line zone (40) + solfege (20)
        return 40 + 4 * lineSpacing + 60
    }

    private var staffTopY: CGFloat { 40 }   // room for result indicators above

    // Y position of a staff slot (0 = bottom line of staff)
    private func yForSlot(_ slot: Int) -> CGFloat {
        let bottomLineY = staffTopY + 4 * lineSpacing
        return bottomLineY - CGFloat(slot) * (lineSpacing / 2)
    }

    private func slotForMIDI(_ midi: Int) -> Int {
        // E4 = MIDI 64 = slot 0; diatonic C-major pitches only (chromatic notes unsupported)
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
            case ..<51:    return .yellow
            case ..<101:   return .orange
            default:       return .red
            }
        case .undetected:    return .gray
        }
    }
}
