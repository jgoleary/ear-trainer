# EarTrainer Web App Design

## Goal

Build a full-featured web version of the EarTrainer iOS app — same 14-lesson solfege curriculum, microphone-based pitch grading, real-time pitch indicator, and star-based progress — deployed to GitHub Pages from the same repo.

## Architecture

The web app lives in `web/` at the repo root as a standalone Vite + React + TypeScript project. No code is shared with the Swift app; all logic is a direct TypeScript translation.

```
ear-trainer/
├── EarTrainer/          # iOS app (unchanged)
├── web/
│   ├── src/
│   │   ├── data/
│   │   │   └── curriculum.ts        # 14 lessons, 140 phrases (mirrors LessonCurriculum.swift)
│   │   ├── audio/
│   │   │   ├── pitchGrader.ts       # pure functions: grade(), phraseScore(), lessonScore(), stars()
│   │   │   └── audioEngine.ts       # Web Audio API wrapper (oscillator + mic + pitch detection)
│   │   ├── store/
│   │   │   └── progressStore.ts     # localStorage-backed progress
│   │   └── components/
│   │       ├── LessonBrowserView.tsx
│   │       ├── LessonCardView.tsx
│   │       ├── ExerciseView.tsx
│   │       ├── StaffView.tsx
│   │       ├── PitchIndicatorView.tsx
│   │       └── LessonResultView.tsx
│   ├── index.html
│   ├── vite.config.ts               # base: '/ear-trainer/' for GitHub Pages
│   └── package.json
└── project.yml                      # iOS (unchanged)
```

**Tech stack:** Vite 5, React 18, TypeScript, React Router v6, `pitchy` (pitch detection), `gh-pages` (deployment).

**Deployment:** `npm run deploy` in `web/` runs `vite build` then `gh-pages -d dist`. GitHub Pages serves from the `gh-pages` branch at `https://jgoleary.github.io/ear-trainer/`.

## Data Model

### Types

```ts
// frequency is a computed helper, not stored in curriculum data
function midiToFreq(midi: number): number {
  return 440 * Math.pow(2, (midi - 69) / 12);
}

interface Note {
  solfege: string;
  midiPitch: number;
  durationBeats: number;
}

interface Phrase {
  notes: Note[];
  tempoBPM: number;
}

interface Lesson {
  id: string;
  title: string;
  difficulty: 'beginner' | 'intermediate' | 'advanced';
  description: string;
  phrases: Phrase[];
}

type PitchResult =
  | { kind: 'onPitch' }
  | { kind: 'sharp'; cents: number }
  | { kind: 'flat';  cents: number }
  | { kind: 'undetected' };
```

`frequency` is not stored in the `Note` object — it is computed on demand via `midiToFreq(note.midiPitch)`, mirroring the Swift computed property.

### `curriculum.ts`

Exports `const curriculum: Lesson[]` — all 14 lessons with identical MIDI pitches and phrase structures as `LessonCurriculum.swift`.

### `progressStore.ts`

Wraps `localStorage` key `"lessonProgress"` (same key as iOS `ProgressStore.swift`) with JSON value `Record<string, { lessonId: string; bestStars: number }>`.

Public API:
- `bestStars(lessonId: string): number`
- `isUnlocked(lesson: Lesson, curriculum: Lesson[]): boolean`
- `record(lessonId: string, stars: number): void`

Uses a React context + `useReducer` for reactivity — components subscribe to progress changes without prop-drilling.

## Audio Engine (`audioEngine.ts`)

Wraps the Web Audio API. Public interface mirrors `AudioEngine.swift`, with one intentional difference: `setup()` is `async` because `getUserMedia` is a Promise on the web (iOS requests permission separately via `AVCaptureDevice.requestAccess`).

```ts
class AudioEngine {
  onFrequencyChange: (freq: number, amp: number) => void  // callback, not property

  async setup(): Promise<void>   // calls getUserMedia, builds audio graph, throws on denial
  playReferencePitch(midiPitch: number, duration?: number): void
  countInThenRecord(bpm: number, onBeat: (n: number) => void, onStart: () => void): void
  startRecording(): void
  stopRecording(): void
  stop(): void
}
```

**Audio graph:**
- Microphone → `AnalyserNode` (fftSize: 2048) → pitchy during recording
- `OscillatorNode` (type: `sine`) → `GainNode` → destination (reference pitch + clicks)

**Pitch detection:** During recording, a `requestAnimationFrame` loop reads a 2048-sample `Float32Array` from the `AnalyserNode` and passes it to `pitchy`'s `PitchDetector.forFloat32Array(2048, audioContext.sampleRate)`. If the RMS amplitude of the buffer exceeds 0.1, fires `onFrequencyChange(detectedHz, amplitude)`; otherwise fires `onFrequencyChange(0, 0)`.

**Count-in timing:** `countInThenRecord` is responsible only for the 4 click beats — it does NOT play the reference Do. The caller (`ExerciseView.startCountIn`) plays Do first (1 second), waits 1 second, then calls `countInThenRecord`. This matches the iOS split where `AudioEngine.countInThenRecord` only handles clicks and the view layer is responsible for the preceding Do playback.

**Count-in implementation:** `setTimeout`-based loop — fires 4 times at `60000/bpm` ms intervals, plays a 1000Hz click (50ms via `GainNode`), calls `onBeat(beat)`, then on beat 5 calls `startRecording()` and `onStart()`.

**Reference pitch cancellation:** Uses a stored `timeoutId` to cancel the pending silence when `playReferencePitch` is called again before the previous duration expires (mirrors `pitchSilenceTask` in Swift).

## Pitch Grader (`pitchGrader.ts`)

Direct TypeScript translation of `PitchGrader.swift`:

```ts
function grade(measured: number, target: number): PitchResult
function phraseScore(results: PitchResult[]): number
function lessonScore(phraseScores: number[]): number
function stars(averageScore: number): number
```

Same constants: ±25¢ on-pitch tolerance, score weights 1.0/0.6/0.3/0.0, star thresholds 0.90/0.75/0.50.

## Components

### `StaffView.tsx`

`<canvas>` element sized to `staffWidth × canvasHeight`. Drawing logic is a direct translation of `StaffView.swift`:
- Same slot map: `{ 60: -2, 62: -1, 64: 0, 65: 1, 67: 2, 69: 3, 71: 4, 72: 5 }`
- Same coordinate system: `staffTopY = 40`, `lineSpacing = 10`, `noteSpacing = 60`, `staffLeftPad = 50`
- `staffWidth = staffLeftPad + notes.length * noteSpacing + noteSpacing / 2`
- Treble clef rendered as an absolutely-positioned `<span>` overlay (font fallback works outside canvas)
- Re-renders on prop changes via `useEffect` watching `[notes, highlightedIndex, results, showSolfege]`

Props: `notes: Note[]`, `showSolfege: boolean`, `highlightedIndex: number | null`, `results: (PitchResult | null)[]`.

### `ExerciseView.tsx`

Three-phase state machine: `preview | countIn | recording | results | lessonComplete`.

- On mount: calls `audioEngine.setup()`, plays reference Do (MIDI 60, always C4 regardless of lesson)
- **preview:** "Sing" button + solfège toggle in header → `startCountIn()`
- **startCountIn():** sets phase to `countIn`, plays Do (MIDI 60) for 1s, waits 1s, then calls `audioEngine.countInThenRecord()`
- **countIn:** beat indicator (4 dots lighting up with each click)
- **recording:** `PitchIndicatorView` with live pitch; per-note window sampling (see below)
- **results:** phrase score + "Try Again" / "Next Exercise" or "Finish" buttons
- **lessonComplete:** navigates to `LessonResultView`

**Per-note window sampling** (mirrors iOS `scheduleNoteAdvance`):
- For each note, skip 50ms attack, then sample `currentFrequency` every 20ms for `(noteDurationSeconds - 0.05 - 0.03)` seconds
- Average all non-zero samples; grade the average via `pitchGrader.grade(avg, midiToFreq(note.midiPitch))`
- On "Try Again": reset `noteResults`, remove the last entry from `phraseScores`, replay reference Do, return to preview

Page visibility change (`document.addEventListener('visibilitychange')`) resets to preview if recording is interrupted, discarding the in-progress attempt without saving a score.

**Solfège toggle:** Checkbox in the exercise header (not the nav bar, since web has no native nav bar toolbar).

### `LessonBrowserView.tsx`

Reads progress from context. Renders 14 `LessonCardView` items. Locked lessons are non-interactive (opacity 0.5, no click handler).

### `LessonResultView.tsx`

Displays stars, average score. "Try Again" always shown. "Next Lesson" shown **only when `stars === 3`** (same condition as iOS). Calls `progressStore.record()` on mount.

## Routing

React Router v6:
- `/` → `LessonBrowserView`
- `/lesson/:id` → `ExerciseView` (renders `LessonResultView` as a full-screen overlay when `lessonComplete`)

## Progress Persistence

`localStorage` key `"lessonProgress"` (matches iOS). Unlock logic: `lesson-01` always unlocked; subsequent lessons require 3 stars on the previous lesson. Stars clamped to 0–3, only written if new value exceeds stored best.

## Error Handling

- `getUserMedia` denied: show inline message with instructions to allow mic in browser settings
- `getUserMedia` not supported: show message directing user to Chrome, Firefox, or Safari 14.1+
- Pitch detection returns no pitch for a full note window: grades as `{ kind: 'undetected' }` (score 0)

## Testing Strategy

- `pitchGrader.ts` — Vitest unit tests (same test cases as `PitchGraderTests.swift`)
- `curriculum.ts` — Vitest unit tests verifying 14 lessons, 10 phrases each, correct MIDI values for lesson 1
- `progressStore.ts` — Vitest unit tests with mocked `localStorage`
- Components — manual browser testing using the iOS Task 13 checklist as a guide
