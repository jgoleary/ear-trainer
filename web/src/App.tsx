import React from 'react';
import { HashRouter, Routes, Route } from 'react-router-dom';
import { ProgressProvider } from './store/progressStore';
import { LessonBrowserView } from './components/LessonBrowserView';
import { ExerciseView } from './components/ExerciseView';

export default function App() {
  return (
    <ProgressProvider>
      <HashRouter>
        <Routes>
          <Route path="/" element={<LessonBrowserView />} />
          <Route path="/lesson/:id" element={<ExerciseView />} />
        </Routes>
      </HashRouter>
    </ProgressProvider>
  );
}
