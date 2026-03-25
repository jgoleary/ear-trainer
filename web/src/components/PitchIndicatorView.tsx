import React from 'react';
import { PitchResult } from '../types';
import { grade } from '../audio/pitchGrader';

interface PitchIndicatorViewProps {
  measuredFrequency: number;  // 0 = no pitch
  targetFrequency: number;
}

function getResult(measured: number, target: number): PitchResult {
  if (measured <= 0) return { kind: 'undetected' };
  return grade(measured, target);
}

function getSymbol(result: PitchResult): string {
  switch (result.kind) {
    case 'onPitch': return '✓';
    case 'sharp': return '♯';
    case 'flat': return '♭';
    case 'undetected': return '–';
  }
}

function getBgColor(result: PitchResult): string {
  switch (result.kind) {
    case 'onPitch': return '#34c759';
    case 'sharp':
    case 'flat': {
      const c = Math.abs(result.cents);
      if (c < 51) return '#ffcc00';
      if (c < 101) return '#ff9500';
      return '#ff3b30';
    }
    case 'undetected': return '#8e8e93';
  }
}

export function PitchIndicatorView({ measuredFrequency, targetFrequency }: PitchIndicatorViewProps) {
  const result = getResult(measuredFrequency, targetFrequency);
  const symbol = getSymbol(result);
  const bgColor = getBgColor(result);

  return (
    <div style={{
      width: 80, height: 80,
      borderRadius: 12,
      background: bgColor,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 2,
    }}>
      <span style={{ fontSize: 32, fontWeight: 'bold', color: '#fff' }}>{symbol}</span>
      {(result.kind === 'sharp' || result.kind === 'flat') && (
        <span style={{ fontSize: 10, color: 'rgba(255,255,255,0.8)' }}>
          {Math.round(result.cents)}¢
        </span>
      )}
    </div>
  );
}
