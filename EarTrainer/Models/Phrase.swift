struct Phrase: Identifiable {
    let id = UUID()
    let notes: [Note]
    let tempoBPM: Int

    var secondsPerBeat: Double { 60.0 / Double(tempoBPM) }
    func windowSeconds(for note: Note) -> Double { note.durationBeats * secondsPerBeat }
}
