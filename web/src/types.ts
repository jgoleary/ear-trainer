export function midiToFreq(midi: number): number {
  return 440 * Math.pow(2, (midi - 69) / 12);
}

export interface Note {
  solfege: string;
  midiPitch: number;
  durationBeats: number;
}

export interface Phrase {
  notes: Note[];
  tempoBPM: number;
}

export interface Lesson {
  id: string;
  title: string;
  difficulty: 'beginner' | 'intermediate' | 'advanced';
  description: string;
  phrases: Phrase[];
}

export type PitchResult =
  | { kind: 'onPitch' }
  | { kind: 'sharp'; cents: number }
  | { kind: 'flat'; cents: number }
  | { kind: 'undetected' };

export function pitchResultScore(result: PitchResult): number {
  switch (result.kind) {
    case 'onPitch': return 1.0;
    case 'sharp':
    case 'flat': {
      const c = result.cents;
      if (c >= 26 && c <= 50) return 0.6;
      if (c >= 51 && c <= 100) return 0.3;
      return 0.0;
    }
    case 'undetected': return 0.0;
  }
}

/** Duration of a note window in seconds. */
export function windowSeconds(phrase: Phrase, note: Note): number {
  return note.durationBeats * (60.0 / phrase.tempoBPM);
}
