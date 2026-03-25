import { describe, it, expect } from 'vitest';
import { grade, phraseScore, lessonScore, stars } from './pitchGrader';

const sharp = (c: number) => ({ kind: 'sharp' as const, cents: c });
const flat  = (c: number) => ({ kind: 'flat'  as const, cents: c });
const onPitch = { kind: 'onPitch' as const };
const undetected = { kind: 'undetected' as const };

describe('grade()', () => {
  it('exact match → onPitch', () => {
    expect(grade(440, 440)).toEqual(onPitch);
  });

  it('25 cents sharp → onPitch (inclusive boundary)', () => {
    const f = 440 * Math.pow(2, 25 / 1200);
    expect(grade(f, 440)).toEqual(onPitch);
  });

  it('26 cents sharp → sharp', () => {
    const f = 440 * Math.pow(2, 26 / 1200);
    const r = grade(f, 440);
    expect(r.kind).toBe('sharp');
  });

  it('35 cents sharp → sharp with score 0.6', () => {
    const f = 440 * Math.pow(2, 35 / 1200);
    const r = grade(f, 440);
    expect(r.kind).toBe('sharp');
    if (r.kind === 'sharp') expect(r.cents).toBeCloseTo(35, 0);
  });

  it('70 cents flat → flat with score 0.3', () => {
    const f = 440 * Math.pow(2, -70 / 1200);
    const r = grade(f, 440);
    expect(r.kind).toBe('flat');
    if (r.kind === 'flat') expect(r.cents).toBeCloseTo(70, 0);
  });

  it('150 cents sharp → sharp (score 0)', () => {
    const f = 440 * Math.pow(2, 150 / 1200);
    const r = grade(f, 440);
    expect(r.kind).toBe('sharp');
  });

  it('zero measured → undetected', () => {
    expect(grade(0, 440)).toEqual(undetected);
  });
});

describe('phraseScore()', () => {
  it('all onPitch → 1.0', () => {
    expect(phraseScore([onPitch, onPitch, onPitch])).toBeCloseTo(1.0);
  });

  it('mixed → (1.0 + 0.6 + 0.0) / 3 ≈ 0.533', () => {
    expect(phraseScore([onPitch, sharp(35), undetected])).toBeCloseTo(0.533, 2);
  });

  it('empty → 0', () => {
    expect(phraseScore([])).toBe(0);
  });
});

describe('lessonScore()', () => {
  it('averages phrase scores', () => {
    expect(lessonScore([1.0, 0.5, 0.75])).toBeCloseTo(0.75, 2);
  });

  it('empty → 0', () => {
    expect(lessonScore([])).toBe(0);
  });
});

describe('stars()', () => {
  it('0.95 → 3 stars', () => { expect(stars(0.95)).toBe(3); });
  it('0.90 → 3 stars (boundary)', () => { expect(stars(0.90)).toBe(3); });
  it('0.8999 → 2 stars', () => { expect(stars(0.8999)).toBe(2); });
  it('0.80 → 2 stars', () => { expect(stars(0.80)).toBe(2); });
  it('0.60 → 1 star', () => { expect(stars(0.60)).toBe(1); });
  it('0.40 → 0 stars', () => { expect(stars(0.40)).toBe(0); });
});
