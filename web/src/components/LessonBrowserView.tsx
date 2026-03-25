import React from 'react';
import { useNavigate } from 'react-router-dom';
import { curriculum } from '../data/curriculum';
import { isUnlocked } from '../store/progressStore';
import { useProgress } from '../store/progressStore';
import { LessonCardView } from './LessonCardView';

export function LessonBrowserView() {
  const navigate = useNavigate();
  const { bestStars } = useProgress();

  return (
    <div style={{ maxWidth: 600, margin: '0 auto', padding: '16px 16px 32px' }}>
      <h1 style={{ fontSize: 28, fontWeight: 700, marginBottom: 20 }}>EarTrainer</h1>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {curriculum.map(lesson => {
          const unlocked = isUnlocked(lesson, curriculum, bestStars);
          return (
            <LessonCardView
              key={lesson.id}
              lesson={lesson}
              stars={bestStars(lesson.id)}
              isUnlocked={unlocked}
              onClick={() => navigate(`/lesson/${lesson.id}`)}
            />
          );
        })}
      </div>
    </div>
  );
}
