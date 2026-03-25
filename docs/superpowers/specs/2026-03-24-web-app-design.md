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
│   │   │   └── progressStore.ts     # localStorage-backed progress (mirrors ProgressStore.swift)
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

### Types (mirrors Swift models)

```ts
interface Note {
  solfege: string;
  midiPitch: number;
  durationBeats: number;
  frequency: number;  // 440 * 2^((midi-69)/12)
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

### `curriculum.ts`

Exports `const curriculum: Lesson[]` — all 14 lessons with identical MIDI pitches and phrase structures as `LessonCurriculum.swift`.

### `progressStore.ts`

Wraps `localStorage` key `"eartrainer_progress"` (JSON: `Record<string, { lessonId: string; bestStars: number }>`).

Public API:
- `bestStars(lessonId: string): number`
- `isUnlocked(lesson: Lesson, curriculum: Lesson[]): boolean`
- `record(lessonId: string, stars: number): void`

Uses a React context + `useReducer` for reactivity — components subscribe to progress changes without prop-drilling.

## Audio Engine (`audioEngine.ts`)

Wraps the Web Audio API. Public interface mirrors `AudioEngine.swift`:

```ts
class AudioEngine {
  currentFrequency: number   // reactive via callback
  currentAmplitude: number
  isRecording: boolean

  async setup(): Promise<void>          // requests mic, builds graph
  playReferencePitch(midiPitch: number, duration?: number): void
  countInThenRecord(bpm: number, onBeat: (n: number) => void, onStart: () => void): void
  startRecording(): void
  stopRecording(): void
  stop(): void
}
```

**Audio graph:**
- Microphone → `AnalyserNode` → `pitchy` (via `requestAnimationFrame` loop during recording)
- `OscillatorNode` (type: `sine`) → `GainNode` → destination (reference pitch + clicks)

**Pitch detection:** On each animation frame during recording, reads a `Float32Array` from the `AnalyserNode`, passes it to `pitchy`'s `PitchDetector.forFloat32Array()`. If amplitude exceeds 0.1, publishes the detected frequency via callback. Otherwise publishes 0.

**Count-in:** `setTimeout`-based loop (same logic as `Task.sleep` in Swift) — fires 4 times at `60000/bpm` ms intervals, plays a 1000Hz click (50ms), calls `onBeat`, then calls `onStart` and begins recording.

**Reference pitch interruption:** Uses a cancellation token (stored `timeoutId`) to cancel a pending silence, same as `pitchSilenceTask` in Swift.

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
- Treble clef rendered as an absolutely-positioned `<span>` overlay (same fix as iOS — font fallback works outside Canvas)
- Re-renders on prop changes via `useEffect` watching `[notes, highlightedIndex, results, showSolfege]`

### `ExerciseView.tsx`

Three-phase state machine: `preview | countIn | recording | results | lessonComplete`.

- On mount: calls `audioEngine.setup()`, plays reference Do
- **preview:** "Sing" button → `startCountIn()`
- **countIn:** plays Do, waits 1s, then 4 clicks with beat indicator
- **recording:** `PitchIndicatorView` showing live pitch; note-window timer grading each note
- **results:** phrase score + "Try Again" / "Next" buttons
- **lessonComplete:** navigates to `LessonResultView`

Page visibility change (`visibilitychange` event) mirrors the iOS `scenePhase` background handler — resets to preview if recording is interrupted.

### `LessonBrowserView.tsx`

Reads progress from context. Renders 14 `LessonCardView` items. Locked lessons are non-interactive (opacity 0.5).

### `LessonResultView.tsx`

Displays stars, average score, "Try Again" / "Next Lesson". Calls `progressStore.record()` on mount.

## Routing

React Router v6:
- `/` → `LessonBrowserView`
- `/lesson/:id` → `ExerciseView`
- `/lesson/:id/result` → `LessonResultView` (or modal from ExerciseView)

## Progress Persistence

`localStorage` key `"eartrainer_progress"`. Same unlock logic: lesson-01 always unlocked; subsequent lessons require 3 stars on the previous lesson. Stars clamped to 0–3, only written if new value exceeds stored best.

## Error Handling

- Mic permission denied: alert with link to browser settings (same as iOS)
- `getUserMedia` not supported: show message directing user to a supported browser (Chrome/Firefox/Safari 14.1+)
- Pitch detection returns no pitch for a full note window: grades as `.undetected` (score 0)

## Testing Strategy

- `pitchGrader.ts` — unit tests with Vitest (same test cases as `PitchGraderTests.swift`)
- `curriculum.ts` — unit tests verifying 14 lessons, 10 phrases each, correct MIDI values for lesson 1
- `progressStore.ts` — unit tests with a mocked `localStorage`
- Components — no automated tests; manual testing in browser mirrors Task 13 checklist
