import React from 'react';
import { Lesson } from '../types';

interface LessonCardViewProps {
  lesson: Lesson;
  stars: number;       // 0–3
  isUnlocked: boolean;
  onClick?: () => void;
}

export function LessonCardView({ lesson, stars, isUnlocked, onClick }: LessonCardViewProps) {
  return (
    <div
      onClick={isUnlocked ? onClick : undefined}
      style={{
        display: 'flex',
        alignItems: 'center',
        padding: '12px 16px',
        background: '#f2f2f7',
        borderRadius: 10,
        opacity: isUnlocked ? 1 : 0.5,
        cursor: isUnlocked && onClick ? 'pointer' : 'default',
      }}
    >
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontWeight: 600,
          fontSize: 16,
          color: isUnlocked ? '#000' : '#8e8e93',
          whiteSpace: 'nowrap',
          overflow: 'hidden',
          textOverflow: 'ellipsis',
        }}>
          {lesson.title}{' '}
          <span style={{ fontSize: 11, color: '#8e8e93', textTransform: 'capitalize' }}>
            {lesson.difficulty}
          </span>
        </div>
        <div style={{
          fontSize: 12,
          color: '#8e8e93',
          marginTop: 2,
          overflow: 'hidden',
          textOverflow: 'ellipsis',
          whiteSpace: 'nowrap',
        }}>
          {lesson.description}
        </div>
      </div>
      <div style={{ marginLeft: 12, flexShrink: 0 }}>
        <span style={{ fontSize: 14, color: '#ffcc00' }}>
          {isUnlocked ? '★'.repeat(stars) + '☆'.repeat(3 - stars) : '🔒'}
        </span>
      </div>
    </div>
  );
}
