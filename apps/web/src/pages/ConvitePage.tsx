import { useEffect, useState } from 'react';
import { Link, Navigate, useParams } from 'react-router-dom';
import { useAuth } from '../auth';
import { BrandLogo } from '../components/Brand';
import { unlockWelcomeAudio } from '../components/WelcomeSlideshow';

/**
 * Entra com o código do convite e deixa a Home exibir o slideshow
 * (flag welcome_pending setada em loginWithToken).
 * O toque inicial destrava o áudio (os navegadores bloqueiam autoplay).
 */
export default function ConvitePage() {
  const { codigo } = useParams();
  const { loginWithToken } = useAuth();
  const [opened, setOpened] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [ok, setOk] = useState(false);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!opened) return;
    const code = codigo?.trim();
    if (!code) {
      setError('Link inválido');
      setBusy(false);
      return;
    }
    let cancelled = false;
    setBusy(true);
    loginWithToken(code)
      .then(() => {
        if (!cancelled) setOk(true);
      })
      .catch((err) => {
        if (!cancelled) {
          setError(
            err instanceof Error ? err.message : 'Não foi possível entrar',
          );
        }
      })
      .finally(() => {
        if (!cancelled) setBusy(false);
      });
    return () => {
      cancelled = true;
    };
  }, [opened, codigo, loginWithToken]);

  if (ok) return <Navigate to="/" replace />;

  if (!opened) {
    return (
      <div className="center">
        <button
          type="button"
          className="welcome-unlock"
          onClick={() => {
            void unlockWelcomeAudio();
            setOpened(true);
          }}
        >
          <BrandLogo size={140} />
          <p>Toque para abrir o convite</p>
          <span>A música começa junto com o slide</span>
        </button>
      </div>
    );
  }

  return (
    <div className="center">
      <div className="login-wrap">
        <div className="hero">
          <BrandLogo size={140} />
          <p>
            {busy
              ? 'Entrando com o seu convite…'
              : error || 'Não foi possível entrar'}
          </p>
        </div>
        {error && (
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
        )}
      </div>
    </div>
  );
}
