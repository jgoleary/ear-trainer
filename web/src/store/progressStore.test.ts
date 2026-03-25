import { describe, it, expect, beforeEach, vi } from 'vitest';
import { makeProgressStore, isUnlocked } from './progressStore';
import { curriculum } from '../data/curriculum';

// Mock localStorage since jsdom doesn't initialize it properly in this setup
const localStorageMock = (() => {
  let store: Record<string, string> = {};

  return {
    getItem: (key: string) => store[key] || null,
    setItem: (key: string, value: string) => {
      store[key] = String(value);
    },
    removeItem: (key: string) => {
      delete store[key];
    },
    clear: () => {
      store = {};
    },
    get length() {
      return Object.keys(store).length;
    },
    key: (index: number) => {
      return Object.keys(store)[index] || null;
    },
  };
})();

beforeEach(() => {
  localStorageMock.clear();
  vi.stubGlobal('localStorage', localStorageMock);
});

describe('bestStars()', () => {
  it('returns 0 for unknown lesson', () => {
    const store = makeProgressStore();
    expect(store.bestStars('lesson-01')).toBe(0);
  });

  it('returns recorded stars', () => {
    const store = makeProgressStore();
    store.record('lesson-01', 3);
    expect(store.bestStars('lesson-01')).toBe(3);
  });

  it('only updates if new stars exceeds current best', () => {
    const store = makeProgressStore();
    store.record('lesson-01', 3);
    store.record('lesson-01', 1);
    expect(store.bestStars('lesson-01')).toBe(3);
  });

  it('clamps stars to 0–3', () => {
    const store = makeProgressStore();
    store.record('lesson-01', 5);
    expect(store.bestStars('lesson-01')).toBe(3);
    store.record('lesson-02', -1);
    expect(store.bestStars('lesson-02')).toBe(0);
  });
});

describe('record() persists to localStorage', () => {
  it('a second store instance reads persisted data', () => {
    const store1 = makeProgressStore();
    store1.record('lesson-01', 3);

    const store2 = makeProgressStore();
    expect(store2.bestStars('lesson-01')).toBe(3);
  });
});

describe('isUnlocked()', () => {
  it('lesson-01 is always unlocked', () => {
    const store = makeProgressStore();
    expect(isUnlocked(curriculum[0], curriculum, store.bestStars)).toBe(true);
  });

  it('lesson-02 is locked when lesson-01 has 0 stars', () => {
    const store = makeProgressStore();
    expect(isUnlocked(curriculum[1], curriculum, store.bestStars)).toBe(false);
  });

  it('lesson-02 unlocked when lesson-01 has 3 stars', () => {
    const store = makeProgressStore();
    store.record('lesson-01', 3);
    expect(isUnlocked(curriculum[1], curriculum, store.bestStars)).toBe(true);
  });

  it('lesson-02 stays locked with 2 stars on lesson-01', () => {
    const store = makeProgressStore();
    store.record('lesson-01', 2);
    expect(isUnlocked(curriculum[1], curriculum, store.bestStars)).toBe(false);
  });
});
