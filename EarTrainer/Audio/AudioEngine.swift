import AudioKit
import AudioKitEX
import AVFoundation
import Combine

@MainActor
final class AudioEngine: ObservableObject {

    // MARK: - Published state
    @Published var currentFrequency: Double = 0      // 0 = no pitch detected
    @Published var currentAmplitude: Double = 0
    @Published var isRecording: Bool = false

    // MARK: - AudioKit nodes
    private let engine = AudioKit.AudioEngine()
    private var mic: AudioKit.AudioEngine.InputNode!
    private var pitchTap: PitchTap!
    private var oscillator: DynamicOscillator!
    private var mixer: Mixer!

    // MARK: - Metronome / count-in
    private var countInTimer: Timer?

    // MARK: - Configuration
    private let amplitudeThreshold: Double = 0.1

    // MARK: - Setup

    func setup() throws {
        guard let inputNode = engine.input else {
            throw AudioEngineError.microphoneUnavailable
        }
        mic = inputNode

        oscillator = DynamicOscillator()
        oscillator.amplitude = 0

        mixer = Mixer(mic, oscillator)
        engine.output = mixer

        pitchTap = PitchTap(mic) { [weak self] freq, amp in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if amp[0] > Float(self.amplitudeThreshold) {
                    self.currentFrequency = Double(freq[0])
                    self.currentAmplitude = Double(amp[0])
                } else {
                    self.currentFrequency = 0
                    self.currentAmplitude = 0
                }
            }
        }

        try engine.start()
    }

    // MARK: - Reference pitch playback

    /// Plays the given MIDI pitch for `duration` seconds, then stops.
    func playReferencePitch(midiPitch: Int, duration: Double = 1.0) {
        let freq = 440.0 * pow(2.0, Double(midiPitch - 69) / 12.0)
        oscillator.frequency = AUValue(freq)
        oscillator.amplitude = 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.oscillator.amplitude = 0
        }
    }

    // MARK: - Count-in + recording

    /// Plays a single audible click using the oscillator (1000 Hz for 50ms).
    private func playClick() {
        oscillator.frequency = 1000
        oscillator.amplitude = 0.4
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.oscillator.amplitude = 0
        }
    }

    /// Plays 4 audible count-in beats, calls `onBeat` for each, then starts recording and calls `onStart`.
    func countInThenRecord(tempoBPM: Int, onBeat: @escaping (Int) -> Void, onStart: @escaping () -> Void) {
        let beatDuration = 60.0 / Double(tempoBPM)
        var beat = 1
        countInTimer = Timer.scheduledTimer(withTimeInterval: beatDuration, repeats: true) { [weak self] timer in
            self?.playClick()
            onBeat(beat)
            beat += 1
            if beat > 4 {
                timer.invalidate()
                self?.startRecording()
                Task { @MainActor in onStart() }
            }
        }
    }

    func startRecording() {
        pitchTap.start()
        isRecording = true
    }

    func stopRecording() {
        pitchTap.stop()
        isRecording = false
        currentFrequency = 0
        currentAmplitude = 0
    }

    // MARK: - Teardown

    func stop() {
        stopRecording()
        countInTimer?.invalidate()
        engine.stop()
    }
}

enum AudioEngineError: Error {
    case microphoneUnavailable
}
