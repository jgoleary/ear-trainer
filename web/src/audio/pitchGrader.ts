import { PitchResult, pitchResultScore } from '../types';

export function grade(measured: number, target: number): PitchResult {
  if (measured <= 0 || target <= 0) return { kind: 'undetected' };
  const cents = 1200 * Math.log2(measured / target);
  if (Math.abs(cents) < 25.5) return { kind: 'onPitch' };
  if (cents > 0) return { kind: 'sharp', cents };
  return { kind: 'flat', cents: Math.abs(cents) };
}

export function phraseScore(results: PitchResult[]): number {
  if (results.length === 0) return 0;
  const total = results.reduce((sum, r) => sum + pitchResultScore(r), 0);
  return total / results.length;
}

export function lessonScore(phraseScores: number[]): number {
  if (phraseScores.length === 0) return 0;
  return phraseScores.reduce((sum, s) => sum + s, 0) / phraseScores.length;
}

export function stars(averageScore: number): number {
  if (averageScore >= 0.90) return 3;
  if (averageScore >= 0.75) return 2;
  if (averageScore >= 0.50) return 1;
  return 0;
}
