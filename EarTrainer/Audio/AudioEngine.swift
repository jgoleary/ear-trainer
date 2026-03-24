import Foundation
import AudioKit
import AudioKitEX
import SoundpipeAudioKit
import AVFoundation

@MainActor
final class AudioEngine: ObservableObject {

    // MARK: - Published state
    @Published var currentFrequency: Double = 0      // 0 = no pitch detected
    @Published var currentAmplitude: Double = 0
    @Published var isRecording: Bool = false

    // MARK: - AudioKit nodes
    private let engine = AudioKit.AudioEngine()
    private var mic: AudioKit.AudioEngine.InputNode?
    private var pitchTap: PitchTap?
    private var oscillator: DynamicOscillator?
    private var mixer: AudioKit.Mixer?

    // MARK: - Playback coordination
    private var pitchSilenceTask: Task<Void, Never>?
    private var clickSilenceTask: Task<Void, Never>?
    private var countInTask: Task<Void, Never>?

    // MARK: - Configuration
    private let amplitudeThreshold: Double = 0.1

    // MARK: - Setup

    func setup() throws {
        guard let inputNode = engine.input else {
            throw AudioEngineError.microphoneUnavailable
        }
        mic = inputNode

        let osc = DynamicOscillator()
        osc.amplitude = 0
        oscillator = osc

        let mix = AudioKit.Mixer(inputNode, osc)
        mixer = mix
        engine.output = mix

        pitchTap = PitchTap(inputNode) { [weak self] freq, amp in
            Task { @MainActor [weak self] in
                guard let self,
                      let amplitude = amp.first,
                      let frequency = freq.first else { return }
                if amplitude > Float(self.amplitudeThreshold) {
                    self.currentFrequency = Double(frequency)
                    self.currentAmplitude = Double(amplitude)
                } else {
                    self.currentFrequency = 0
                    self.currentAmplitude = 0
                }
            }
        }

        try engine.start()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    // MARK: - Reference pitch playback

    /// Plays the given MIDI pitch for `duration` seconds, then stops.
    func playReferencePitch(midiPitch: Int, duration: Double = 1.0) {
        guard let oscillator else { return }
        pitchSilenceTask?.cancel()
        let freq = 440.0 * pow(2.0, Double(midiPitch - 69) / 12.0)
        oscillator.frequency = AUValue(freq)
        oscillator.amplitude = 0.5
        pitchSilenceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self?.oscillator?.amplitude = 0
        }
    }

    // MARK: - Count-in + recording

    private func playClick() {
        guard let oscillator else { return }
        clickSilenceTask?.cancel()
        oscillator.frequency = 1000
        oscillator.amplitude = 0.4
        clickSilenceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(50))
            guard !Task.isCancelled else { return }
            self?.oscillator?.amplitude = 0
        }
    }

    /// Plays 4 audible count-in beats, calls `onBeat` for each, then starts recording and calls `onStart`.
    func countInThenRecord(tempoBPM: Int, onBeat: @escaping (Int) -> Void, onStart: @escaping () -> Void) {
        let beatDuration = 60.0 / Double(tempoBPM)
        countInTask?.cancel()
        countInTask = Task { @MainActor [weak self] in
            for beat in 1...4 {
                guard !Task.isCancelled, let self else { return }
                self.playClick()
                onBeat(beat)
                try? await Task.sleep(for: .seconds(beatDuration))
            }
            guard !Task.isCancelled, let self else { return }
            self.startRecording()
            onStart()
        }
    }

    func startRecording() {
        guard let pitchTap else { return }
        pitchTap.start()
        isRecording = true
    }

    func stopRecording() {
        pitchTap?.stop()
        isRecording = false
        currentFrequency = 0
        currentAmplitude = 0
    }

    // MARK: - Teardown

    func stop() {
        countInTask?.cancel()
        countInTask = nil
        pitchSilenceTask?.cancel()
        pitchSilenceTask = nil
        clickSilenceTask?.cancel()
        clickSilenceTask = nil
        stopRecording()
        engine.stop()
    }

    // MARK: - Audio session interruption

    @objc nonisolated private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        Task { @MainActor [weak self] in
            switch type {
            case .began:
                self?.stopRecording()
            case .ended:
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        try? self?.engine.start()
                    }
                }
            @unknown default:
                break
            }
        }
    }
}

enum AudioEngineError: Error {
    case microphoneUnavailable
}
