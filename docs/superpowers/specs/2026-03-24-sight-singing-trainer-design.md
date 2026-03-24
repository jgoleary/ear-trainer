# Sight Singing Trainer — Design Spec
**Date:** 2026-03-24
**Platform:** iOS (native SwiftUI + AudioKit)

---

## Overview

An iOS app that trains the user to sing music using solfege. The app displays phrases on a musical staff, plays a reference pitch, counts the singer in, records their singing via microphone, and grades pitch accuracy in real time and per-phrase. Lessons progress in difficulty and are unlocked by achieving 3 stars.

---

## Architecture

Five layers:

1. **Lesson Model** — Swift structs (`Note`, `Phrase`, `Lesson`) embedded as static data in the app.
2. **Lesson Browser** — Home screen; scrollable list of lessons grouped by difficulty, showing star ratings and lock state.
3. **Exercise View** — Main practice screen with staff, pitch indicator, controls, and results.
4. **Audio Engine** — AudioKit wrapper (`ObservableObject`) owning the microphone session, YIN pitch tracker, metronome, and note playback.
5. **Pitch Grader** — Pure logic layer. Takes a target frequency and measured frequency, returns a `PitchResult`: `.onPitch`, `.sharp(cents)`, or `.flat(cents)`.

---

## Data Model

```swift
struct Note {
    let solfege: String        // "Do", "Re", "Mi", etc.
    let midiPitch: Int         // e.g., 60 = C4
    let durationBeats: Double
}

struct Phrase {
    let notes: [Note]
    let tempoBPM: Int
}

struct Lesson {
    let title: String
    let difficulty: Difficulty  // .beginner, .intermediate, .advanced
    let description: String
    let phrases: [Phrase]       // always 10 phrases
}
```

Progression state (persisted via `UserDefaults`):
```swift
struct LessonProgress {
    let lessonID: String
    let bestStars: Int  // 0–3
}
```

---

## Lesson Curriculum

All lessons are in C major, treble clef. Each lesson has 10 phrases. Tempo starts at 60 BPM and may slow to 50 BPM for harder lessons. Note frequencies are derived from standard western equal temperament intervals (per `combined_intervals.csv`).

Each new pitch is introduced with a dedicated lesson alongside one familiar companion before being absorbed into broader scale context. Tonic triad leaps are introduced as soon as Do, Mi, and Sol are all known.

| # | Title | Notes | Focus |
|---|-------|-------|-------|
| 1 | Tonic & Dominant | Do, Sol | Perfect 5th anchor |
| 2 | First Step Up | Do, Re | Stepwise ascent from tonic |
| 3 | Do Through Mi | Do, Re, Mi | Complete lower tonic area |
| 4 | Tonic Triad Leaps | Do, Mi, Sol | Do→Mi, Do→Sol, Sol→Mi |
| 5 | The Half-Step Pull | Mi, Fa | Mi↔Fa, the strongest tonal pull |
| 6 | Fa & Sol | Fa, Sol | Subdominant to dominant step |
| 7 | Do Through Sol | Do, Re, Mi, Fa, Sol | Consolidate lower hexachord |
| 8 | Sol & La | Sol, La | Introduce La with one familiar companion |
| 9 | Do Through La | Do–La | Integrate La into full lower scale |
| 10 | La & Ti | La, Ti | Introduce Ti with one familiar companion |
| 11 | Ti Resolves | Ti, Do' | Leading tone resolution |
| 12 | Full Scale | Do–Do' | Complete octave, stepwise |
| 13 | Wider Leaps | All | Larger intervals, mixed motion |
| 14 | Full Melodies | All | Flowing phrases combining everything |

---

## Exercise Flow

Each lesson has exactly **10 exercises** (phrases). The exercise screen has three phases:

### Phase 1 — Preview
- Staff displays the phrase with solfege labels visible (toggle in top-right corner hides/shows labels).
- App automatically plays the reference pitch (Do) once on screen load.
- "Sing" button at the bottom.

### Phase 2 — Count-in & Recording
- Tapping "Sing" triggers 4 metronome clicks at lesson tempo.
- Recording begins immediately after the count-in.
- Beat indicator pulses on screen throughout.
- Real-time pitch indicator is active (see Pitch Indicator section).
- The current note is highlighted on the staff as the beat grid advances.

### Phase 3 — Results
- Recording stops after the last note's window closes.
- Each note on the staff shows a small indicator above it:
  - Green ✓ — on pitch
  - ♭ (colored by severity) — flat
  - ♯ (colored by severity) — sharp
- Total phrase score shown below the staff (percentage).
- "Try Again" resets to Phase 1 (no score saved).
- "Next Exercise" advances to the next of 10 phrases.

### End of Lesson
After all 10 exercises, the lesson score screen shows:
- Star rating (1–3 stars) based on average phrase score across all 10 exercises.
- "Try Lesson Again" or "Next Lesson" (if unlocked).

---

## Pitch Detection

**Algorithm:** YIN (via AudioKit's `PitchTap`) — estimates fundamental frequency from waveform periodicity. Handles the complex harmonic content of the human voice (overtones, vibrato) correctly by analyzing periodicity rather than peak frequency.

**Vibrato handling:** For each note, pitch samples are collected across the note's beat window. The first ~50ms (attack) and last ~30ms (release) are discarded. The remaining samples are averaged to produce a stable fundamental estimate that smooths out vibrato wobble.

**Amplitude threshold:** Samples below a configurable amplitude floor are ignored, preventing false readings from ambient noise.

**Timing:** The beat grid determines each note's sample window. Note duration in beats × (60 / BPM) = window in seconds.

---

## Pitch Indicator

A real-time color-coded indicator visible during Phase 2:

| State | Color | Symbol |
|-------|-------|--------|
| On pitch (±25¢) | Green | — |
| Flat 26–50¢ | Yellow | ♭ |
| Flat 51–100¢ | Orange | ♭ |
| Flat >100¢ | Red | ♭ |
| Sharp 26–50¢ | Yellow | ♯ |
| Sharp 51–100¢ | Orange | ♯ |
| Sharp >100¢ | Red | ♯ |
| No pitch detected | Gray | — |

The ♭ or ♯ symbol is embedded within the indicator so the singer knows both direction and severity at a glance.

---

## Scoring

### Per-Note Score
| Accuracy | Score |
|----------|-------|
| ±25¢ (on pitch) | 100% |
| 26–50¢ off | 60% |
| 51–100¢ off | 30% |
| >100¢ off or no pitch | 0% |

### Per-Phrase Score
Average of all note scores in the phrase. Displayed as a percentage after each exercise.

### Per-Lesson Star Rating
Based on average phrase score across all 10 exercises:

| Average Score | Stars |
|---------------|-------|
| 90%+ | ⭐⭐⭐ |
| 75–89% | ⭐⭐ |
| 50–74% | ⭐ |
| <50% | 0 (no unlock) |

**3 stars required** to unlock the next lesson. Best star score per lesson is persisted via `UserDefaults`.

---

## Lesson Browser

- Scrollable list of all 14 lessons grouped by difficulty.
- Each lesson card shows: title, description, best star rating.
- Locked lessons are visible but grayed out (shows what's ahead).
- Lesson 1 is always unlocked.

---

## Error Handling & Edge Cases

- **No microphone permission** — prompt on first launch; if denied, show message with link to iOS Settings.
- **No pitch detected** — counts as 0% for that note; indicator shows neutral gray.
- **Background noise** — AudioKit amplitude threshold filters out sub-threshold noise.
- **App backgrounded during recording** — recording stops, attempt discarded, user returned to Phase 1.
- **Lesson restart mid-session** — "Try Again" resets cleanly; no partial scores saved.

---

## Staff Display

- Treble clef, C major (no key signature).
- Notes displayed horizontally left-to-right.
- Solfege syllables displayed below each notehead (toggleable via top-right button).
- Current note highlighted during Phase 2.
- Per-note result indicators displayed above each notehead after Phase 3.

---

## Testing

| Area | Approach |
|------|----------|
| `PitchGrader` | Unit tests with known frequency inputs and expected cent/result outputs |
| Lesson model | Unit tests verifying all 14 lessons load, note counts, frequency values |
| Scoring logic | Unit tests for star threshold calculations |
| Audio Engine | Manual testing only (microphone input not simulatable in XCTest) |
| UI flow | XCUITest for phase transitions and navigation |

---

## Future Work (Out of Scope for v1)

- Custom lesson creation
- Adaptive tempo (slows down if user struggles)
- Server-side progress sync
- Interval ear training (identify intervals by ear, not just sing them)
