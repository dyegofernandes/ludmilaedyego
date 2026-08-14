import { Navigate, Route, Routes } from 'react-router-dom';
import { useAuth } from './auth';
import LoginPage from './pages/LoginPage';
import HomePage from './pages/HomePage';
import ConvitePage from './pages/ConvitePage';

function Guard({ children }: { children: React.ReactNode }) {
  const { token, loading } = useAuth();
  if (loading) {
    return (
      <div className="center">
        <div className="hero">
          <img
            src="/logo_ludmila_dyego.png"
            alt=""
            className="brand-logo"
            width={120}
            height={120}
          />
          <p>Carregando…</p>
        </div>
      </div>
    );
  }
  if (!token) return <Navigate to="/login" replace />;
  return <>{children}</>;
}

export default function App() {
  return (
    <div className="app-root">
      <div className="logo-watermark" aria-hidden="true" />
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/convite/:codigo" element={<ConvitePage />} />
        <Route
          path="/*"
          element={
            <Guard>
              <HomePage />
            </Guard>
          }
        />
      </Routes>
    </div>
  );
}
