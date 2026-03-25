import { describe, it, expect } from 'vitest';
import { curriculum } from './curriculum';

describe('curriculum', () => {
  it('has 14 lessons', () => {
    expect(curriculum).toHaveLength(14);
  });

  it('each lesson has exactly 10 phrases', () => {
    for (const lesson of curriculum) {
      expect(lesson.phrases, `${lesson.id} phrase count`).toHaveLength(10);
    }
  });

  it('lesson IDs are lesson-01 through lesson-14', () => {
    const ids = curriculum.map(l => l.id);
    for (let i = 1; i <= 14; i++) {
      expect(ids).toContain(`lesson-${String(i).padStart(2, '0')}`);
    }
  });

  it('lesson-01 title is "Tonic & Dominant"', () => {
    expect(curriculum[0].title).toBe('Tonic & Dominant');
  });

  it('lesson-01 difficulty is beginner', () => {
    expect(curriculum[0].difficulty).toBe('beginner');
  });

  it('lesson-01 phrase 1 has notes Do(60) and Sol(67)', () => {
    const phrase = curriculum[0].phrases[0];
    expect(phrase.notes).toHaveLength(2);
    expect(phrase.notes[0]).toMatchObject({ solfege: 'Do', midiPitch: 60 });
    expect(phrase.notes[1]).toMatchObject({ solfege: 'Sol', midiPitch: 67 });
  });

  it('lesson-01 phrase 1 tempoBPM is 60', () => {
    expect(curriculum[0].phrases[0].tempoBPM).toBe(60);
  });

  it('all notes have durationBeats 1.0', () => {
    for (const lesson of curriculum) {
      for (const phrase of lesson.phrases) {
        for (const note of phrase.notes) {
          expect(note.durationBeats, `${lesson.id} beat`).toBe(1.0);
        }
      }
    }
  });
});
