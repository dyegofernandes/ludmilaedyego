import { useState } from 'react';
import { Link, Navigate, useParams } from 'react-router-dom';
import { useAuth } from '../auth';
import { BrandLogo } from '../components/Brand';
import {
  unlockWelcomeAudio,
  stopWelcomeAudio,
} from '../components/WelcomeSlideshow';

/**
 * Entra com o código do convite e deixa a Home exibir o slideshow
 * (flag welcome_pending setada em loginWithToken para convidado/padrinho).
 */
export default function ConvitePage() {
  const { codigo } = useParams();
  const { loginWithToken } = useAuth();
  const [error, setError] = useState<string | null>(null);
  const [ok, setOk] = useState(false);
  const [busy, setBusy] = useState(false);

  async function abrir() {
    const code = codigo?.trim();
    if (!code) {
      setError('Link inválido');
      return;
    }
    setBusy(true);
    setError(null);
    try {
      const u = await loginWithToken(code);
      const guest = u.role === 'convidado' || u.role === 'padrinho';
      if (guest) void unlockWelcomeAudio();
      else stopWelcomeAudio();
      setOk(true);
    } catch (err) {
      stopWelcomeAudio();
      setError(err instanceof Error ? err.message : 'Não foi possível entrar');
    } finally {
      setBusy(false);
    }
  }

  if (ok) return <Navigate to="/" replace />;

  if (!error) {
    return (
      <div className="center">
        <button
          type="button"
          className="welcome-unlock"
          disabled={busy}
          onClick={() => void abrir()}
        >
          <BrandLogo size={140} />
          <p>{busy ? 'Entrando…' : 'Toque para abrir'}</p>
          <span>Acesso ao casamento Ludmila & Dyego</span>
        </button>
      </div>
    );
  }

  return (
    <div className="center">
      <div className="login-wrap">
        <div className="hero">
          <BrandLogo size={140} />
          <p>Não foi possível entrar</p>
        </div>
        <div className="panel">
          <div className="error">{error}</div>
          <p className="hint">
            Peça um novo link aos noivos ou entre com e-mail e senha.
          </p>
          <Link
            to="/login"
            className="primary"
            style={{ display: 'inline-block' }}
          >
            Ir para o login
          </Link>
        </div>
      </div>
    </div>
  );
}
