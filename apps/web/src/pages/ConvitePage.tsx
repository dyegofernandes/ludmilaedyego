import { useEffect, useState } from 'react';
import { Link, Navigate, useParams } from 'react-router-dom';
import { useAuth } from '../auth';
import { BrandLogo } from '../components/Brand';

/**
 * Entra com o código do convite e deixa a Home exibir o slideshow
 * (flag welcome_pending setada em loginWithToken).
 */
export default function ConvitePage() {
  const { codigo } = useParams();
  const { loginWithToken } = useAuth();
  const [error, setError] = useState<string | null>(null);
  const [ok, setOk] = useState(false);
  const [busy, setBusy] = useState(true);

  useEffect(() => {
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
  }, [codigo, loginWithToken]);

  if (ok) return <Navigate to="/" replace />;

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
