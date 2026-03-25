import React, { useEffect } from 'react';
import { Lesson } from '../types';
import { lessonScore, stars as calcStars } from '../audio/pitchGrader';
import { useProgress } from '../store/progressStore';

interface LessonResultViewProps {
  lesson: Lesson;
  phraseScores: number[];
  onTryAgain: () => void;
  onNextLesson: (() => void) | null;  // null if last lesson
}

export function LessonResultView({
  lesson, phraseScores, onTryAgain, onNextLesson,
}: LessonResultViewProps) {
  const { record } = useProgress();
  const avgScore = lessonScore(phraseScores);
  const starCount = calcStars(avgScore);

  useEffect(() => {
    record(lesson.id, starCount);
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <div style={{
      position: 'fixed', inset: 0,
      background: '#fff',
      display: 'flex', flexDirection: 'column',
      alignItems: 'center', justifyContent: 'center',
      gap: 24, padding: 24, zIndex: 100,
    }}>
      <h2 style={{ fontSize: 28, fontWeight: 700, textAlign: 'center' }}>{lesson.title}</h2>

      <div style={{ display: 'flex', gap: 12 }}>
        {[1, 2, 3].map(i => (
          <span key={i} style={{ fontSize: 44, color: '#ffcc00' }}>
            {i <= starCount ? '★' : '☆'}
          </span>
        ))}
      </div>

      <p style={{ fontSize: 20, color: '#8e8e93' }}>
        {Math.round(avgScore * 100)}% average
      </p>

      {starCount < 3 && (
        <p style={{ fontSize: 15, color: '#8e8e93', textAlign: 'center', maxWidth: 280 }}>
          3 stars required to unlock the next lesson.
        </p>
      )}

      <div style={{ display: 'flex', gap: 16 }}>
        <button onClick={onTryAgain} style={outlineBtn}>Try Again</button>
        {starCount === 3 && onNextLesson && (
          <button onClick={onNextLesson} style={filledBtn}>Next Lesson</button>
        )}
      </div>
    </div>
  );
}

const outlineBtn: React.CSSProperties = {
  padding: '10px 20px', borderRadius: 10,
  border: '1.5px solid #007aff', background: 'transparent',
  color: '#007aff', fontSize: 16, cursor: 'pointer',
};

const filledBtn: React.CSSProperties = {
  padding: '10px 20px', borderRadius: 10,
  border: 'none', background: '#007aff',
  color: '#fff', fontSize: 16, cursor: 'pointer',
};
