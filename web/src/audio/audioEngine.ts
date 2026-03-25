import { PitchDetector } from 'pitchy';

export class AudioEngine {
  onFrequencyChange: (freq: number, amp: number) => void = () => {};

  private audioCtx: AudioContext | null = null;
  private analyser: AnalyserNode | null = null;
  private oscillator: OscillatorNode | null = null;
  private gainNode: GainNode | null = null;
  private micStream: MediaStream | null = null;
  private detector: PitchDetector<Float32Array> | null = null;
  private buffer: Float32Array | null = null;
  private rafId: number | null = null;
  private pitchSilenceId: number | null = null;
  private countInTimeoutId: number | null = null;
  private isRecording = false;

  async setup(): Promise<void> {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    this.micStream = stream;

    const ctx = new AudioContext();
    this.audioCtx = ctx;

    const analyser = ctx.createAnalyser();
    analyser.fftSize = 2048;
    this.analyser = analyser;
    this.buffer = new Float32Array(2048);
    this.detector = PitchDetector.forFloat32Array(2048);

    const source = ctx.createMediaStreamSource(stream);
    source.connect(analyser);

    const osc = ctx.createOscillator();
    osc.type = 'sine';
    osc.start();
    this.oscillator = osc;

    const gain = ctx.createGain();
    gain.gain.value = 0;
    this.gainNode = gain;

    osc.connect(gain);
    gain.connect(ctx.destination);
  }

  playReferencePitch(midiPitch: number, duration = 1.0): void {
    if (!this.oscillator || !this.gainNode || !this.audioCtx) return;
    if (this.pitchSilenceId !== null) {
      clearTimeout(this.pitchSilenceId);
      this.pitchSilenceId = null;
    }
    const freq = 440 * Math.pow(2, (midiPitch - 69) / 12);
    this.oscillator.frequency.value = freq;
    this.gainNode.gain.value = 0.5;
    this.pitchSilenceId = window.setTimeout(() => {
      if (this.gainNode) this.gainNode.gain.value = 0;
      this.pitchSilenceId = null;
    }, duration * 1000);
  }

  private playClick(): void {
    if (!this.oscillator || !this.gainNode) return;
    this.oscillator.frequency.value = 1000;
    this.gainNode.gain.value = 0.4;
    setTimeout(() => {
      if (this.gainNode) this.gainNode.gain.value = 0;
    }, 50);
  }

  countInThenRecord(
    bpm: number,
    onBeat: (n: number) => void,
    onStart: () => void
  ): void {
    const beatMs = 60000 / bpm;
    let beat = 0;

    const tick = () => {
      beat++;
      if (beat <= 4) {
        this.playClick();
        onBeat(beat);
        this.countInTimeoutId = window.setTimeout(tick, beatMs);
      } else {
        this.startRecording();
        onStart();
      }
    };

    tick(); // beat 1 fires immediately
  }

  startRecording(): void {
    this.isRecording = true;
    this.schedulePitchLoop();
  }

  private schedulePitchLoop(): void {
    if (!this.isRecording) return;
    const loop = () => {
      if (!this.isRecording) return;
      this.readPitch();
      this.rafId = requestAnimationFrame(loop);
    };
    this.rafId = requestAnimationFrame(loop);
  }

  private readPitch(): void {
    if (!this.analyser || !this.buffer || !this.detector || !this.audioCtx) return;
    this.analyser.getFloatTimeDomainData(this.buffer);

    let sumSq = 0;
    for (let i = 0; i < this.buffer.length; i++) sumSq += this.buffer[i] ** 2;
    const rms = Math.sqrt(sumSq / this.buffer.length);

    if (rms > 0.01) {
      const [pitch] = this.detector.findPitch(this.buffer, this.audioCtx.sampleRate);
      if (pitch > 0) {
        this.onFrequencyChange(pitch, rms);
        return;
      }
    }
    this.onFrequencyChange(0, 0);
  }

  stopRecording(): void {
    this.isRecording = false;
    if (this.rafId !== null) {
      cancelAnimationFrame(this.rafId);
      this.rafId = null;
    }
    this.onFrequencyChange(0, 0);
  }

  stop(): void {
    if (this.countInTimeoutId !== null) {
      clearTimeout(this.countInTimeoutId);
      this.countInTimeoutId = null;
    }
    if (this.pitchSilenceId !== null) {
      clearTimeout(this.pitchSilenceId);
      this.pitchSilenceId = null;
    }
    this.stopRecording();
    if (this.gainNode) this.gainNode.gain.value = 0;
    if (this.micStream) {
      this.micStream.getTracks().forEach(t => t.stop());
      this.micStream = null;
    }
    if (this.audioCtx) {
      this.audioCtx.close();
      this.audioCtx = null;
    }
  }
}
