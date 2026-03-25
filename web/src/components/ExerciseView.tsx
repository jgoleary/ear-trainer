import React, { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { curriculum } from '../data/curriculum';
import { AudioEngine } from '../audio/audioEngine';
import { grade, phraseScore } from '../audio/pitchGrader';
import { midiToFreq, windowSeconds, PitchResult } from '../types';
import { StaffView } from './StaffView';
import { PitchIndicatorView } from './PitchIndicatorView';
import { LessonResultView } from './LessonResultView';

type Phase = 'preview' | 'countIn' | 'recording' | 'results' | 'lessonComplete';

export function ExerciseView() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const lesson = curriculum.find(l => l.id === id);
  if (!lesson) return <div>Lesson not found</div>;

  const [phraseIndex, setPhraseIndex] = useState(0);
  const [phase, setPhase] = useState<Phase>('preview');
  const [beatCount, setBeatCount] = useState(0);
  const [currentNoteIndex, setCurrentNoteIndex] = useState<number | null>(null);
  const [noteResults, setNoteResults] = useState<(PitchResult | null)[]>([]);
  const [phraseScores, setPhraseScores] = useState<number[]>([]);
  const [showSolfege, setShowSolfege] = useState(true);
  const [micError, setMicError] = useState<'denied' | 'unsupported' | null>(null);
  const [currentFreq, setCurrentFreq] = useState(0);

  // Ref so setTimeout/setInterval callbacks read the live frequency value
  // without stale closures. Both the ref and state are updated together.
  const currentFreqRef = useRef(0);

  const engineRef = useRef<AudioEngine | null>(null);
  const noteTimersRef = useRef<number[]>([]);
  // Pitch samples for current note window — lives in a ref to avoid stale closures
  const pitchSamplesRef = useRef<number[]>([]);

  const currentPhrase = lesson.phrases[phraseIndex];

  const currentLessonIdx = curriculum.findIndex(l => l.id === id);
  const nextLesson = currentLessonIdx < curriculum.length - 1
    ? curriculum[currentLessonIdx + 1]
    : null;

  function clearNoteTimers() {
    noteTimersRef.current.forEach(id => {
      clearTimeout(id);
      clearInterval(id);
    });
    noteTimersRef.current = [];
  }

  // Setup audio on mount
  useEffect(() => {
    const engine = new AudioEngine();
    engineRef.current = engine;
    engine.onFrequencyChange = (freq) => {
      currentFreqRef.current = freq;
      setCurrentFreq(freq);
    };

    (async () => {
      try {
        await engine.setup();
        engine.playReferencePitch(60);
      } catch {
        if (!navigator.mediaDevices?.getUserMedia) {
          setMicError('unsupported');
        } else {
          setMicError('denied');
        }
      }
    })();

    return () => {
      clearNoteTimers();
      engine.stop();
    };
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  // Reset to preview on tab hide during active session
  useEffect(() => {
    const handler = () => {
      if (document.hidden && (phase === 'recording' || phase === 'countIn')) {
        engineRef.current?.stopRecording();
        clearNoteTimers();
        resetToPreview();
      }
    };
    document.addEventListener('visibilitychange', handler);
    return () => document.removeEventListener('visibilitychange', handler);
  });

  function resetToPreview() {
    setPhase('preview');
    setBeatCount(0);
    setCurrentNoteIndex(null);
    setNoteResults([]);
  }

  function startCountIn() {
    setPhase('countIn');
    setBeatCount(0);
    engineRef.current?.playReferencePitch(60, 1.0);
    setTimeout(() => {
      engineRef.current?.countInThenRecord(
        currentPhrase.tempoBPM,
        (beat) => setBeatCount(beat),
        () => beginRecording(),
      );
    }, 1000);
  }

  function beginRecording() {
    const noteCount = currentPhrase.notes.length;
    setPhase('recording');
    setCurrentNoteIndex(0);
    setNoteResults(Array(noteCount).fill(null));
    scheduleNoteAdvance(0, Array(noteCount).fill(null));
  }

  function scheduleNoteAdvance(noteIndex: number, results: (PitchResult | null)[]) {
    if (noteIndex >= currentPhrase.notes.length) {
      finishRecording(results);
      return;
    }

    const note = currentPhrase.notes[noteIndex];
    const winSecs = windowSeconds(currentPhrase, note);
    const attackSkip = 0.05;
    const releaseSkip = 0.03;
    const sampleWindow = winSecs - attackSkip - releaseSkip;
    const sampleIntervalMs = 20;
    const sampleCount = Math.floor((sampleWindow * 1000) / sampleIntervalMs);

    const attackId = window.setTimeout(() => {
      pitchSamplesRef.current = [];
      let sampled = 0;

      const sampleId = window.setInterval(() => {
        const f = currentFreqRef.current;  // live value via ref — no stale closure
        if (f > 0) pitchSamplesRef.current.push(f);
        sampled++;

        if (sampled >= sampleCount) {
          clearInterval(sampleId);

          const validSamples = pitchSamplesRef.current;
          let result: PitchResult;
          if (validSamples.length === 0) {
            result = { kind: 'undetected' };
          } else {
            const avg = validSamples.reduce((a, b) => a + b, 0) / validSamples.length;
            result = grade(avg, midiToFreq(note.midiPitch));
          }

          const nextResults = [...results];
          nextResults[noteIndex] = result;
          setNoteResults(nextResults);
          setCurrentNoteIndex(noteIndex + 1);
          scheduleNoteAdvance(noteIndex + 1, nextResults);
        }
      }, sampleIntervalMs);

      noteTimersRef.current.push(sampleId);
    }, attackSkip * 1000);

    noteTimersRef.current.push(attackId);
  }

  function finishRecording(results: (PitchResult | null)[]) {
    engineRef.current?.stopRecording();
    const score = phraseScore(results.map(r => r ?? { kind: 'undetected' }));
    setPhraseScores(prev => [...prev, score]);
    setPhase('results');
  }

  function resetPhrase() {
    setNoteResults([]);
    setCurrentNoteIndex(null);
    setPhraseScores(prev => prev.slice(0, -1));
    engineRef.current?.playReferencePitch(60);
    setPhase('preview');
  }

  function advanceOrFinish() {
    if (phraseIndex + 1 < lesson.phrases.length) {
      setPhraseIndex(phraseIndex + 1);
      setNoteResults([]);
      setCurrentNoteIndex(null);
      engineRef.current?.playReferencePitch(60);
      setPhase('preview');
    } else {
      setPhase('lessonComplete');
    }
  }

  if (micError) {
    return (
      <div style={{ padding: 24, maxWidth: 400, margin: '0 auto' }}>
        <h2>Microphone Required</h2>
        {micError === 'unsupported'
          ? <p>Your browser doesn't support microphone access. Try Chrome, Firefox, or Safari 14.1+.</p>
          : <p>EarTrainer needs microphone access to grade your singing. Allow access in your browser settings and reload.</p>
        }
        <button onClick={() => navigate('/')}>Back</button>
      </div>
    );
  }

  const displayResults = phase === 'results'
    ? noteResults
    : Array(currentPhrase.notes.length).fill(null);

  return (
    <div style={{ maxWidth: 600, margin: '0 auto', padding: 16 }}>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <button onClick={() => navigate('/')} style={{ background: 'none', border: 'none', fontSize: 16, cursor: 'pointer', color: '#007aff' }}>
          ← Back
        </button>
        <span style={{ fontWeight: 600 }}>
          Exercise {phraseIndex + 1} of {lesson.phrases.length}
        </span>
        <label style={{ fontSize: 14, display: 'flex', alignItems: 'center', gap: 4 }}>
          <input type="checkbox" checked={showSolfege} onChange={e => setShowSolfege(e.target.checked)} />
          Solfège
        </label>
      </div>

      {/* Staff */}
      <div style={{ overflowX: 'auto', marginBottom: 24 }}>
        <StaffView
          notes={currentPhrase.notes}
          showSolfege={showSolfege}
          highlightedIndex={currentNoteIndex}
          results={displayResults}
        />
      </div>

      {/* Phase UI */}
      {phase === 'preview' && (
        <div style={{ textAlign: 'center' }}>
          <button onClick={startCountIn} style={filledBtn}>Sing</button>
        </div>
      )}

      {phase === 'countIn' && (
        <div style={{ textAlign: 'center' }}>
          <p style={{ fontSize: 18, fontWeight: 600, marginBottom: 12 }}>Get ready...</p>
          <div style={{ display: 'flex', justifyContent: 'center', gap: 12 }}>
            {[1, 2, 3, 4].map(i => (
              <div key={i} style={{
                width: 20, height: 20, borderRadius: '50%',
                background: i <= beatCount ? '#007aff' : '#d1d1d6',
              }} />
            ))}
          </div>
        </div>
      )}

      {phase === 'recording' && (
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 16 }}>
          <PitchIndicatorView
            measuredFrequency={currentFreq}
            targetFrequency={
              currentNoteIndex !== null && currentNoteIndex < currentPhrase.notes.length
                ? midiToFreq(currentPhrase.notes[currentNoteIndex].midiPitch)
                : 0
            }
          />
          <p style={{ fontSize: 20, fontWeight: 700, color: '#007aff' }}>Sing!</p>
        </div>
      )}

      {phase === 'results' && (
        <div style={{ textAlign: 'center' }}>
          <p style={{ fontSize: 22, fontWeight: 700, marginBottom: 16 }}>
            Score: {Math.round(phraseScore(noteResults.map(r => r ?? { kind: 'undetected' })) * 100)}%
          </p>
          <div style={{ display: 'flex', justifyContent: 'center', gap: 16 }}>
            <button onClick={resetPhrase} style={outlineBtn}>Try Again</button>
            <button onClick={advanceOrFinish} style={filledBtn}>
              {phraseIndex + 1 < lesson.phrases.length ? 'Next Exercise' : 'Finish'}
            </button>
          </div>
        </div>
      )}

      {phase === 'lessonComplete' && (
        <LessonResultView
          lesson={lesson}
          phraseScores={phraseScores}
          onTryAgain={() => {
            setPhraseIndex(0);
            setPhraseScores([]);
            setNoteResults([]);
            setCurrentNoteIndex(null);
            engineRef.current?.playReferencePitch(60);
            setPhase('preview');
          }}
          onNextLesson={nextLesson ? () => navigate(`/lesson/${nextLesson.id}`) : null}
        />
      )}
    </div>
  );
}

const filledBtn: React.CSSProperties = {
  padding: '12px 28px', borderRadius: 10, border: 'none',
  background: '#007aff', color: '#fff', fontSize: 18, cursor: 'pointer',
};
const outlineBtn: React.CSSProperties = {
  padding: '12px 28px', borderRadius: 10,
  border: '1.5px solid #007aff', background: 'transparent',
  color: '#007aff', fontSize: 18, cursor: 'pointer',
};
