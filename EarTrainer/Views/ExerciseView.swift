import SwiftUI
import AVFoundation

struct ExerciseView: View {

    let lesson: Lesson
    let store: ProgressStore

    @StateObject private var audioEngine = AudioEngine()
    @State private var phase: Phase = .preview
    @State private var currentPhraseIndex = 0
    @State private var currentNoteIndex: Int? = nil
    @State private var noteResults: [PitchResult?] = []
    @State private var phraseScores: [Double] = []
    @State private var showSolfege = true
    @State private var beatCount = 0
    @State private var pitchSamples: [Double] = []
    @State private var noteTimer: Timer? = nil
    @State private var micPermissionDenied = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    enum Phase { case preview, countIn, recording, results, lessonComplete }

    private var currentPhrase: Phrase { lesson.phrases[currentPhraseIndex] }

    var body: some View {
        VStack(spacing: 20) {
            // Solfege toggle
            HStack {
                Spacer()
                Toggle("Solfege", isOn: $showSolfege)
                    .toggleStyle(.button)
                    .font(.caption)
            }
            .padding(.horizontal)

            // Staff
            ScrollView(.horizontal, showsIndicators: false) {
                StaffView(
                    notes: currentPhrase.notes,
                    showSolfege: showSolfege,
                    highlightedIndex: currentNoteIndex,
                    results: phase == .results ? noteResults : Array(repeating: nil, count: currentPhrase.notes.count)
                )
                .padding(.horizontal)
            }

            // Phase-specific UI
            switch phase {
            case .preview:
                previewUI
            case .countIn:
                countInUI
            case .recording:
                recordingUI
            case .results:
                resultsUI
            case .lessonComplete:
                EmptyView()
            }

            Spacer()
        }
        .navigationTitle("Exercise \(currentPhraseIndex + 1) of \(lesson.phrases.count)")
        .navigationBarTitleDisplayMode(.inline)
        .task { await setupAudio() }
        .onDisappear { audioEngine.stop() }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background, phase == .recording || phase == .countIn {
                audioEngine.stopRecording()
                noteTimer?.invalidate()
                resetToPreview()
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { phase == .lessonComplete },
            set: { _ in }
        )) {
            LessonResultView(
                lesson: lesson,
                phraseScores: phraseScores,
                store: store
            )
        }
        .alert("Microphone Access Required",
               isPresented: $micPermissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { dismiss() }
        } message: {
            Text("EarTrainer needs microphone access to grade your singing. Enable it in Settings.")
        }
    }

    // MARK: - Sub-views

    private var previewUI: some View {
        Button("Sing") {
            startCountIn()
        }
        .buttonStyle(.borderedProminent)
        .font(.title2)
    }

    private var countInUI: some View {
        VStack {
            Text("Get ready...")
                .font(.headline)
            HStack(spacing: 12) {
                ForEach(1...4, id: \.self) { i in
                    Circle()
                        .fill(i <= beatCount ? Color.accentColor : Color(.systemGray4))
                        .frame(width: 20, height: 20)
                }
            }
        }
    }

    private var recordingUI: some View {
        VStack(spacing: 16) {
            PitchIndicatorView(
                measuredFrequency: audioEngine.currentFrequency,
                targetFrequency: currentNoteIndex.flatMap {
                    $0 < currentPhrase.notes.count ? currentPhrase.notes[$0].frequency : nil
                } ?? 0
            )
            Text("Sing!")
                .font(.title2.bold())
                .foregroundColor(.accentColor)
        }
    }

    private var resultsUI: some View {
        VStack(spacing: 12) {
            let score = PitchGrader.phraseScore(noteResults.map { $0 ?? .undetected })
            Text("Score: \(Int(score * 100))%")
                .font(.title2.bold())

            HStack(spacing: 16) {
                Button("Try Again") {
                    resetPhrase()
                }
                .buttonStyle(.bordered)

                Button(currentPhraseIndex + 1 < lesson.phrases.count ? "Next Exercise" : "Finish") {
                    advanceOrFinish()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Logic

    private func setupAudio() async {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            try? audioEngine.setup()
            audioEngine.playReferencePitch(midiPitch: 60)
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            if granted { try? audioEngine.setup(); audioEngine.playReferencePitch(midiPitch: 60) }
            else { micPermissionDenied = true }
        default:
            micPermissionDenied = true
        }
    }

    private func startCountIn() {
        phase = .countIn
        beatCount = 0
        audioEngine.countInThenRecord(tempoBPM: currentPhrase.tempoBPM) { beat in
            Task { @MainActor in self.beatCount = beat }
        } onStart: {
            Task { @MainActor in self.beginRecording() }
        }
    }

    private func beginRecording() {
        phase = .recording
        currentNoteIndex = 0
        noteResults = Array(repeating: nil, count: currentPhrase.notes.count)
        pitchSamples = []
        scheduleNoteAdvance(noteIndex: 0)
    }

    private func scheduleNoteAdvance(noteIndex: Int) {
        guard noteIndex < currentPhrase.notes.count else {
            finishRecording()
            return
        }
        let note = currentPhrase.notes[noteIndex]
        let windowSeconds = currentPhrase.windowSeconds(for: note)
        let attackSkip = 0.05
        let releaseSkip = 0.03
        let sampleWindow = windowSeconds - attackSkip - releaseSkip

        DispatchQueue.main.asyncAfter(deadline: .now() + attackSkip) { [weak self] in
            guard let self else { return }
            self.pitchSamples = []
            let sampleInterval = 0.02
            let sampleCount = Int(sampleWindow / sampleInterval)
            var sampled = 0

            self.noteTimer = Timer.scheduledTimer(withTimeInterval: sampleInterval, repeats: true) { [weak self] timer in
                Task { @MainActor [weak self] in
                    guard let self else { timer.invalidate(); return }
                    let freq = self.audioEngine.currentFrequency
                    if freq > 0 { self.pitchSamples.append(freq) }
                    sampled += 1
                    if sampled >= sampleCount {
                        timer.invalidate()
                        self.gradeCurrentNote(noteIndex: noteIndex, targetNote: note)
                        self.currentNoteIndex = noteIndex + 1
                        self.scheduleNoteAdvance(noteIndex: noteIndex + 1)
                    }
                }
            }
        }
    }

    private func gradeCurrentNote(noteIndex: Int, targetNote: Note) {
        let validSamples = pitchSamples.filter { $0 > 0 }
        let result: PitchResult
        if validSamples.isEmpty {
            result = .undetected
        } else {
            let avg = validSamples.reduce(0, +) / Double(validSamples.count)
            result = PitchGrader.grade(measured: avg, target: targetNote.frequency)
        }
        guard noteIndex < noteResults.count else { return }
        noteResults[noteIndex] = result
    }

    private func finishRecording() {
        audioEngine.stopRecording()
        noteTimer?.invalidate()
        let score = PitchGrader.phraseScore(noteResults.map { $0 ?? .undetected })
        phraseScores.append(score)
        phase = .results
    }

    private func resetPhrase() {
        noteResults = []
        pitchSamples = []
        currentNoteIndex = nil
        if !phraseScores.isEmpty { phraseScores.removeLast() }
        audioEngine.playReferencePitch(midiPitch: 60)
        phase = .preview
    }

    /// Called when app is backgrounded during recording — discards attempt, no score saved.
    private func resetToPreview() {
        noteTimer?.invalidate()
        noteResults = []
        pitchSamples = []
        currentNoteIndex = nil
        beatCount = 0
        phase = .preview
    }

    private func advanceOrFinish() {
        if currentPhraseIndex + 1 < lesson.phrases.count {
            currentPhraseIndex += 1
            noteResults = []
            pitchSamples = []
            currentNoteIndex = nil
            audioEngine.playReferencePitch(midiPitch: 60)
            phase = .preview
        } else {
            phase = .lessonComplete
        }
    }
}
