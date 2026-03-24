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
