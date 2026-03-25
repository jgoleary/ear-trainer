import { Lesson, Note, Phrase } from '../types';

// MIDI values: Do=60, Re=62, Mi=64, Fa=65, Sol=67, La=69, Ti=71, Do'=72
function n(solfege: string, midiPitch: number): Note {
  return { solfege, midiPitch, durationBeats: 1.0 };
}

function p(notes: Note[], tempoBPM = 60): Phrase {
  return { notes, tempoBPM };
}

const Do  = () => n('Do',  60);
const Re  = () => n('Re',  62);
const Mi  = () => n('Mi',  64);
const Fa  = () => n('Fa',  65);
const Sol = () => n('Sol', 67);
const La  = () => n('La',  69);
const Ti  = () => n('Ti',  71);
const DoH = () => n("Do'", 72);

// Standard 2-note pattern for beginner lessons
// A=note1, B=note2, 10 phrases of variations
function twoPhrases(a: () => Note, b: () => Note): Phrase[] {
  return [
    p([a(), b()]),
    p([b(), a()]),
    p([a(), b(), a()]),
    p([b(), a(), b()]),
    p([a(), a(), b()]),
    p([b(), b(), a()]),
    p([a(), b(), b(), a()]),
    p([b(), a(), a(), b()]),
    p([a(), b(), a(), b()]),
    p([b(), a(), b(), a()]),
  ];
}

export const curriculum: Lesson[] = [
  // lesson-01: Tonic & Dominant — Do(60) and Sol(67)
  {
    id: 'lesson-01',
    title: 'Tonic & Dominant',
    difficulty: 'beginner',
    description: 'Sing Do and Sol — the two most fundamental notes of any key.',
    phrases: twoPhrases(Do, Sol),
  },

  // lesson-02: First Step Up — Do(60) and Re(62)
  {
    id: 'lesson-02',
    title: 'First Step Up',
    difficulty: 'beginner',
    description: 'Sing Do and Re — a whole step up from the tonic.',
    phrases: twoPhrases(Do, Re),
  },

  // lesson-03: Do Through Mi — Do(60), Re(62), Mi(64)
  {
    id: 'lesson-03',
    title: 'Do Through Mi',
    difficulty: 'beginner',
    description: 'Sing the first three notes of the scale: Do, Re, Mi.',
    phrases: [
      p([Do(), Mi()]),
      p([Mi(), Do()]),
      p([Do(), Re(), Mi()]),
      p([Mi(), Re(), Do()]),
      p([Do(), Mi(), Re()]),
      p([Re(), Do(), Mi()]),
      p([Do(), Re(), Mi(), Re()]),
      p([Mi(), Re(), Do(), Re()]),
      p([Do(), Mi(), Do(), Mi()]),
      p([Mi(), Do(), Re(), Do()]),
    ],
  },

  // lesson-04: Tonic Triad Leaps — Do(60), Mi(64), Sol(67)
  {
    id: 'lesson-04',
    title: 'Tonic Triad Leaps',
    difficulty: 'beginner',
    description: 'Leap through the tonic triad: Do, Mi, Sol.',
    phrases: [
      p([Do(), Mi()]),
      p([Mi(), Sol()]),
      p([Do(), Sol()]),
      p([Sol(), Do()]),
      p([Do(), Mi(), Sol()]),
      p([Sol(), Mi(), Do()]),
      p([Do(), Sol(), Mi()]),
      p([Mi(), Do(), Sol()]),
      p([Do(), Mi(), Sol(), Mi()]),
      p([Sol(), Mi(), Do(), Mi()]),
    ],
  },

  // lesson-05: The Half-Step Pull — Mi(64) and Fa(65)
  {
    id: 'lesson-05',
    title: 'The Half-Step Pull',
    difficulty: 'beginner',
    description: 'Feel the tension of the half step between Mi and Fa.',
    phrases: twoPhrases(Mi, Fa),
  },

  // lesson-06: Fa & Sol — Fa(65) and Sol(67)
  {
    id: 'lesson-06',
    title: 'Fa & Sol',
    difficulty: 'beginner',
    description: 'Sing Fa and Sol — neighboring notes above the half-step.',
    phrases: twoPhrases(Fa, Sol),
  },

  // lesson-07: Do Through Sol — Do(60)-Sol(67), 5 notes, last 2 at BPM 55
  {
    id: 'lesson-07',
    title: 'Do Through Sol',
    difficulty: 'intermediate',
    description: 'Sing the first five notes of the scale: Do through Sol.',
    phrases: [
      p([Do(), Re(), Mi(), Fa(), Sol()]),
      p([Sol(), Fa(), Mi(), Re(), Do()]),
      p([Do(), Mi(), Sol(), Mi(), Do()]),
      p([Sol(), Mi(), Do(), Mi(), Sol()]),
      p([Do(), Re(), Mi(), Re(), Do()]),
      p([Sol(), Fa(), Mi(), Fa(), Sol()]),
      p([Do(), Sol(), Mi(), Re(), Do()]),
      p([Sol(), Do(), Re(), Mi(), Sol()]),
      p([Do(), Re(), Sol(), Fa(), Mi()], 55),
      p([Mi(), Fa(), Sol(), Re(), Do()], 55),
    ],
  },

  // lesson-08: Sol & La — Sol(67) and La(69)
  {
    id: 'lesson-08',
    title: 'Sol & La',
    difficulty: 'intermediate',
    description: 'Sing Sol and La — moving into the upper half of the scale.',
    phrases: twoPhrases(Sol, La),
  },

  // lesson-09: Do Through La — Do-La (6 notes), last 5 at BPM 55
  {
    id: 'lesson-09',
    title: 'Do Through La',
    difficulty: 'intermediate',
    description: 'Sing six notes of the scale: Do through La.',
    phrases: [
      p([Do(), Re(), Mi(), Fa(), Sol(), La()]),
      p([La(), Sol(), Fa(), Mi(), Re(), Do()]),
      p([Do(), Mi(), Sol(), La(), Sol(), Mi()]),
      p([La(), Sol(), Mi(), Do(), Mi(), Sol()]),
      p([Do(), Re(), Mi(), Sol(), La(), Sol()]),
      p([La(), Sol(), Mi(), Fa(), Mi(), Re()], 55),
      p([Do(), Sol(), La(), Sol(), Mi(), Do()], 55),
      p([La(), Mi(), Do(), Re(), Mi(), La()], 55),
      p([Do(), Fa(), Mi(), Re(), Sol(), La()], 55),
      p([La(), Sol(), Fa(), Mi(), Re(), Do()], 55),
    ],
  },

  // lesson-10: La & Ti — La(69) and Ti(71)
  {
    id: 'lesson-10',
    title: 'La & Ti',
    difficulty: 'intermediate',
    description: 'Sing La and Ti — approaching the leading tone.',
    phrases: twoPhrases(La, Ti),
  },

  // lesson-11: Ti Resolves — Ti(71), Do'(72), plus some La
  {
    id: 'lesson-11',
    title: 'Ti Resolves',
    difficulty: 'intermediate',
    description: 'Feel Ti resolve upward to Do — the leading tone resolution.',
    phrases: [
      p([Ti(), DoH()]),
      p([DoH(), Ti()]),
      p([Ti(), DoH(), Ti()]),
      p([La(), Ti(), DoH()]),
      p([DoH(), Ti(), La()]),
      p([La(), Ti(), DoH(), Ti()]),
      p([Ti(), La(), Ti(), DoH()]),
      p([DoH(), Ti(), DoH(), La()]),
      p([La(), Ti(), DoH(), Ti(), La()]),
      p([Ti(), DoH(), Ti(), La(), Ti()]),
    ],
  },

  // lesson-12: Full Scale — All 8 notes Do-Do', all at BPM 55
  {
    id: 'lesson-12',
    title: 'Full Scale',
    difficulty: 'advanced',
    description: 'Sing all eight notes of the scale from Do to Do\'.',
    phrases: [
      p([Do(), Re(), Mi(), Fa(), Sol(), La(), Ti(), DoH()], 55),
      p([DoH(), Ti(), La(), Sol(), Fa(), Mi(), Re(), Do()], 55),
      p([Do(), Mi(), Sol(), DoH(), Sol(), Mi(), Do(), Sol()], 55),
      p([DoH(), La(), Fa(), Re(), Fa(), La(), DoH(), Sol()], 55),
      p([Do(), Re(), Mi(), Sol(), La(), Ti(), DoH(), Ti()], 55),
      p([DoH(), Ti(), La(), Sol(), Mi(), Re(), Do(), Re()], 55),
      p([Do(), Sol(), Mi(), DoH(), Ti(), La(), Sol(), Do()], 55),
      p([DoH(), Sol(), Mi(), Do(), Re(), Fa(), La(), DoH()], 55),
      p([Do(), Fa(), Mi(), Sol(), La(), Mi(), Ti(), DoH()], 55),
      p([DoH(), Ti(), Sol(), Fa(), Mi(), Re(), Sol(), Do()], 55),
    ],
  },

  // lesson-13: Wider Leaps — larger intervals, first 5 at BPM 55, last 5 at BPM 50
  {
    id: 'lesson-13',
    title: 'Wider Leaps',
    difficulty: 'advanced',
    description: 'Practice larger melodic leaps across the scale.',
    phrases: [
      p([Do(), Sol(), Re(), La(), Mi()], 55),
      p([Mi(), La(), Re(), Sol(), Do()], 55),
      p([Do(), Mi(), Sol(), DoH(), Sol()], 55),
      p([DoH(), Sol(), Mi(), Do(), Mi()], 55),
      p([Re(), Sol(), Ti(), Sol(), Re()], 55),
      p([Mi(), DoH(), Sol(), Do(), Sol()], 50),
      p([Do(), La(), Mi(), Ti(), Sol()], 50),
      p([Sol(), Ti(), Mi(), La(), Do()], 50),
      p([Do(), Fa(), Ti(), Mi(), La()], 50),
      p([La(), Mi(), Ti(), Fa(), Do()], 50),
    ],
  },

  // lesson-14: Full Melodies — 7-8 note flowing melodies, first 5 at BPM 55, last 5 at BPM 50
  {
    id: 'lesson-14',
    title: 'Full Melodies',
    difficulty: 'advanced',
    description: 'Sing flowing melodies using the full scale.',
    phrases: [
      p([Do(), Re(), Mi(), Fa(), Sol(), La(), Ti(), DoH()], 55),
      p([DoH(), Ti(), La(), Sol(), Fa(), Mi(), Re(), Do()], 55),
      p([Do(), Mi(), Re(), Fa(), Mi(), Sol(), Fa(), La()], 55),
      p([La(), Fa(), Sol(), Mi(), Fa(), Re(), Mi(), Do()], 55),
      p([Do(), Sol(), Mi(), La(), Fa(), Ti(), Sol(), DoH()], 55),
      p([DoH(), Sol(), Ti(), Fa(), La(), Mi(), Sol(), Do()], 50),
      p([Do(), Re(), Sol(), Mi(), La(), Fa(), Ti(), DoH()], 50),
      p([DoH(), Ti(), Fa(), La(), Mi(), Sol(), Re(), Do()], 50),
      p([Do(), Fa(), Re(), Ti(), Sol(), Mi(), La(), DoH()], 50),
      p([DoH(), La(), Mi(), Sol(), Re(), Ti(), Fa(), Do()], 50),
    ],
  },
];
