import { FormEvent, useEffect, useState } from 'react';
import { Navigate, useSearchParams } from 'react-router-dom';
import { fetchPublicConfig } from '../api';
import { useAuth } from '../auth';
import { BrandLogo } from '../components/Brand';

export default function LoginPage() {
  const { token, login, loginWithToken } = useAuth();
  const [params] = useSearchParams();
  const [tab, setTab] = useState<'noivos' | 'convidados'>('noivos');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [codigo, setCodigo] = useState(
    () => (params.get('c') || params.get('convite') || '').toUpperCase(),
  );
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [welcome, setWelcome] = useState('Bem-vindos ao nosso casamento!');

  useEffect(() => {
    fetchPublicConfig()
      .then((c) => {
        if (c?.mensagemBoasVindas) setWelcome(String(c.mensagemBoasVindas));
      })
      .catch(() => {});
  }, []);

  useEffect(() => {
    const c = params.get('c') || params.get('convite');
    if (c) {
      setTab('convidados');
      setCodigo(c.toUpperCase());
    }
  }, [params]);

  if (token) return <Navigate to="/" replace />;

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      if (tab === 'noivos') await login(email, password);
      else if (codigo.trim()) await loginWithToken(codigo);
      else await login(email, password);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Falha no login');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="center">
      <div className="login-wrap">
        <div className="hero">
          <BrandLogo size={168} />
          <p>{welcome}</p>
        </div>
        <form className="panel" onSubmit={onSubmit}>
          <div className="tabs">
            <button
              type="button"
              className={tab === 'noivos' ? 'active' : ''}
              onClick={() => setTab('noivos')}
            >
              Noivos
            </button>
            <button
              type="button"
              className={tab === 'convidados' ? 'active' : ''}
              onClick={() => setTab('convidados')}
            >
              Convidados
            </button>
          </div>

          {tab === 'noivos' && (
            <>
              <label>E-mail</label>
              <input
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                type="email"
                required
                autoComplete="username"
              />
              <label>Senha</label>
              <input
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                type="password"
                required
                autoComplete="current-password"
              />
            </>
          )}

          {tab === 'convidados' && (
            <>
              <p className="hint" style={{ textAlign: 'left', marginTop: 0 }}>
                Se você já criou cadastro, entre com e-mail e senha. No
                primeiro acesso, use o link enviado pelos noivos ou o código
                do convite.
              </p>
              <label>E-mail</label>
              <input
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                type="email"
                autoComplete="username"
              />
              <label>Senha</label>
              <input
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                type="password"
                autoComplete="current-password"
              />
              <label>Código do convite (primeiro acesso)</label>
              <input
                value={codigo}
                onChange={(e) => setCodigo(e.target.value.toUpperCase())}
                placeholder="CONV-XXXX"
              />
            </>
          )}

          {error && <div className="error">{error}</div>}
          <button
            className="primary"
            disabled={
              loading ||
              (tab === 'noivos'
                ? !email || !password
                : !(codigo.trim() || (email && password)))
            }
          >
            {loading ? 'Aguarde…' : 'Entrar'}
          </button>
        </form>
      </div>
    </div>
  );
}
