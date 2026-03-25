import React, { useRef, useEffect } from 'react';
import { Note, PitchResult } from '../types';

interface StaffViewProps {
  notes: Note[];
  showSolfege: boolean;
  highlightedIndex: number | null;
  results: (PitchResult | null)[];
}

const LINE_SPACING = 10;
const NOTE_RADIUS = 7;
const STAFF_LEFT_PAD = 50;
const NOTE_SPACING = 60;
const STAFF_TOP_Y = 40;

const SLOT_MAP: Record<number, number> = {
  60: -2, 62: -1, 64: 0, 65: 1, 67: 2, 69: 3, 71: 4, 72: 5,
};

function slotForMidi(midi: number): number {
  return SLOT_MAP[midi] ?? 0;
}

function yForSlot(slot: number): number {
  const bottomLineY = STAFF_TOP_Y + 4 * LINE_SPACING;
  return bottomLineY - slot * (LINE_SPACING / 2);
}

function xForNote(index: number): number {
  return STAFF_LEFT_PAD + index * NOTE_SPACING + NOTE_SPACING / 2;
}

function staffWidth(noteCount: number): number {
  return STAFF_LEFT_PAD + Math.max(noteCount, 1) * NOTE_SPACING + NOTE_SPACING / 2;
}

const CANVAS_HEIGHT = 40 + 4 * LINE_SPACING + 60;

function indicatorSymbol(result: PitchResult): string {
  switch (result.kind) {
    case 'onPitch': return '✓';
    case 'sharp': return '♯';
    case 'flat': return '♭';
    case 'undetected': return '–';
  }
}

function indicatorColor(result: PitchResult): string {
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

export function StaffView({ notes, showSolfege, highlightedIndex, results }: StaffViewProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const width = staffWidth(notes.length);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    const dpr = window.devicePixelRatio || 1;
    canvas.width = width * dpr;
    canvas.height = CANVAS_HEIGHT * dpr;
    ctx.scale(dpr, dpr);
    ctx.clearRect(0, 0, width, CANVAS_HEIGHT);

    // Draw staff lines
    ctx.strokeStyle = getComputedStyle(canvas).color || '#000';
    ctx.lineWidth = 1;
    for (let line = 0; line < 5; line++) {
      const y = STAFF_TOP_Y + line * LINE_SPACING;
      ctx.beginPath();
      ctx.moveTo(10, y);
      ctx.lineTo(width - 10, y);
      ctx.stroke();
    }

    // Draw notes
    for (let i = 0; i < notes.length; i++) {
      const note = notes[i];
      const slot = slotForMidi(note.midiPitch);
      const x = xForNote(i);
      const y = yForSlot(slot);
      const isHighlighted = highlightedIndex === i;

      // Ledger line for C4 (slot -2)
      if (slot === -2) {
        ctx.beginPath();
        ctx.moveTo(x - NOTE_RADIUS - 4, y);
        ctx.lineTo(x + NOTE_RADIUS + 4, y);
        ctx.stroke();
      }

      // Notehead
      const fillColor = isHighlighted ? '#ffcc00' : (getComputedStyle(canvas).color || '#000');
      ctx.fillStyle = fillColor;
      ctx.beginPath();
      ctx.ellipse(x, y, NOTE_RADIUS, NOTE_RADIUS * 0.75, 0, 0, Math.PI * 2);
      ctx.fill();

      // Stem
      const stemUp = slot < 2;
      const stemX = stemUp ? x + NOTE_RADIUS - 1 : x - NOTE_RADIUS + 1;
      const stemEndY = stemUp ? y - LINE_SPACING * 3 : y + LINE_SPACING * 3;
      ctx.strokeStyle = fillColor;
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.moveTo(stemX, y);
      ctx.lineTo(stemX, stemEndY);
      ctx.stroke();
      ctx.strokeStyle = getComputedStyle(canvas).color || '#000';
      ctx.lineWidth = 1;

      // Solfege label
      if (showSolfege) {
        const labelY = yForSlot(-3) + 10;
        ctx.fillStyle = '#8e8e93';
        ctx.font = '10px system-ui';
        ctx.textAlign = 'center';
        ctx.fillText(note.solfege, x, labelY);
      }

      // Result indicator
      if (i < results.length && results[i] !== null) {
        const result = results[i]!;
        ctx.fillStyle = indicatorColor(result);
        ctx.font = 'bold 11px system-ui';
        ctx.textAlign = 'center';
        ctx.fillText(indicatorSymbol(result), x, STAFF_TOP_Y - 20);
      }
    }
  }, [notes, showSolfege, highlightedIndex, results, width]);

  return (
    <div style={{ position: 'relative', display: 'inline-block' }}>
      <canvas
        ref={canvasRef}
        style={{ width, height: CANVAS_HEIGHT, display: 'block' }}
      />
      {/* Treble clef rendered outside canvas for font support */}
      <span style={{
        position: 'absolute',
        left: 4,
        top: STAFF_TOP_Y - 12,
        fontSize: 60,
        lineHeight: 1,
        pointerEvents: 'none',
      }}>
        𝄞
      </span>
    </div>
  );
}
