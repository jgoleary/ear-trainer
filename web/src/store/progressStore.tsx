import React, {
  createContext, useContext, useReducer, useCallback, useMemo
} from 'react';
import { Lesson } from '../types';

const STORAGE_KEY = 'lessonProgress';

type ProgressMap = Record<string, { lessonId: string; bestStars: number }>;

// --- Pure store factory (used in tests) ---

export interface ProgressStore {
  bestStars: (lessonId: string) => number;
  record: (lessonId: string, stars: number) => void;
}

export function makeProgressStore(): ProgressStore {
  let state: ProgressMap = {};

  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) state = JSON.parse(raw);
  } catch { /* ignore */ }

  function save() {
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); } catch { /* ignore */ }
  }

  function bestStars(lessonId: string): number {
    return state[lessonId]?.bestStars ?? 0;
  }

  function record(lessonId: string, stars: number): void {
    const clamped = Math.max(0, Math.min(3, stars));
    const current = bestStars(lessonId);
    if (clamped > current) {
      state = { ...state, [lessonId]: { lessonId, bestStars: clamped } };
      save();
    }
  }

  return { bestStars, record };
}

// --- isUnlocked pure function ---

export function isUnlocked(
  lesson: Lesson,
  curriculum: Lesson[],
  bestStars: (lessonId: string) => number
): boolean {
  if (lesson.id === 'lesson-01') return true;
  const idx = curriculum.findIndex(l => l.id === lesson.id);
  if (idx <= 0) return false;
  return bestStars(curriculum[idx - 1].id) >= 3;
}

// --- React context ---

interface ProgressState {
  progressMap: ProgressMap;
}

type ProgressAction = { type: 'record'; lessonId: string; stars: number };

function loadInitialState(): ProgressState {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) return { progressMap: JSON.parse(raw) };
  } catch { /* ignore */ }
  return { progressMap: {} };
}

function progressReducer(state: ProgressState, action: ProgressAction): ProgressState {
  if (action.type === 'record') {
    const clamped = Math.max(0, Math.min(3, action.stars));
    const current = state.progressMap[action.lessonId]?.bestStars ?? 0;
    if (clamped <= current) return state;
    const next: ProgressState = {
      progressMap: {
        ...state.progressMap,
        [action.lessonId]: { lessonId: action.lessonId, bestStars: clamped },
      },
    };
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(next.progressMap)); } catch { /* ignore */ }
    return next;
  }
  return state;
}

interface ProgressContextValue {
  bestStars: (lessonId: string) => number;
  record: (lessonId: string, stars: number) => void;
}

const ProgressContext = createContext<ProgressContextValue | null>(null);

export function ProgressProvider({ children }: { children: React.ReactNode }) {
  const [state, dispatch] = useReducer(progressReducer, undefined, loadInitialState);

  const bestStars = useCallback(
    (lessonId: string) => state.progressMap[lessonId]?.bestStars ?? 0,
    [state.progressMap]
  );

  const record = useCallback(
    (lessonId: string, stars: number) => dispatch({ type: 'record', lessonId, stars }),
    []
  );

  const value = useMemo(() => ({ bestStars, record }), [bestStars, record]);
  return <ProgressContext.Provider value={value}>{children}</ProgressContext.Provider>;
}

export function useProgress(): ProgressContextValue {
  const ctx = useContext(ProgressContext);
  if (!ctx) throw new Error('useProgress must be used within ProgressProvider');
  return ctx;
}
