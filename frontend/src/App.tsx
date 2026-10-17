import type { ReactElement } from 'react';
import { Navigate, Route, Routes } from 'react-router-dom';
import { AnimalList } from './pages/AnimalList';
import { AnimalCreate } from './pages/AnimalCreate';
import { AnimalDetail } from './pages/AnimalDetail';
import { CentreList } from './pages/CentreList';
import { CentreCreate } from './pages/CentreCreate';
import { CentreDetail } from './pages/CentreDetail';
import { ReadinessQuestionnaire } from './pages/readiness/ReadinessQuestionnaire';

/**
 * Components that may be ABSENT from this checkout register their routes by
 * exporting `routes: ReactElement[]` (a list of <Route>s) from
 * `pages/<component>/routes.tsx`. The glob is resolved at build time and is
 * simply empty when no such folder exists — the lecturer's private library
 * module lives there, gitignored. Students: add your <Route>s below, like animals.
 */
const componentRoutes = Object.values(
  import.meta.glob<{ routes: ReactElement[] }>('./pages/*/routes.tsx', { eager: true }),
).flatMap((m) => m.routes);

export const App = () => (
  <Routes>
    <Route path="/" element={<Navigate to="/centres" replace />} />
    <Route path="/animals" element={<AnimalList />} />
    <Route path="/animals/new" element={<AnimalCreate />} />
    <Route path="/animals/:id" element={<AnimalDetail />} />
    <Route path="/centres" element={<CentreList />} />
    <Route path="/centres/new" element={<CentreCreate />} />
    <Route path="/centres/:id" element={<CentreDetail />} />
    <Route path="/readiness" element={<ReadinessQuestionnaire />} />
    {componentRoutes}
  </Routes>
);
