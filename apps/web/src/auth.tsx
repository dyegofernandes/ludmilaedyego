import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import {
  fetchBootstrap,
  loginEmail,
  loginToken,
  type Bootstrap,
  type User,
} from './api';
import { WELCOME_PENDING_KEY } from './components/WelcomeSlideshow';

type AuthCtx = {
  token: string | null;
  user: User | null;
  data: Bootstrap | null;
  loading: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<void>;
  loginWithToken: (token: string) => Promise<void>;
  logout: () => void;
  /** silent=true não mostra tela de loading (não desmonta a Home). */
  refresh: (silent?: boolean) => Promise<void>;
};

const Ctx = createContext<AuthCtx | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(
    () => localStorage.getItem('access_token'),
  );
  const [user, setUser] = useState<User | null>(null);
  const [data, setData] = useState<Bootstrap | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(
    async (silent = false) => {
      if (!token) {
        setUser(null);
        setData(null);
        setLoading(false);
        return;
      }
      if (!silent) setLoading(true);
      try {
        const boot = await fetchBootstrap(token);
        setData(boot);
        setUser(boot.user);
        setError(null);
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Falha ao carregar');
        localStorage.removeItem('access_token');
        setToken(null);
        setUser(null);
        setData(null);
      } finally {
        if (!silent) setLoading(false);
      }
    },
    [token],
  );

  useEffect(() => {
    void refresh(false);
  }, [refresh]);

  const login = useCallback(async (email: string, password: string) => {
    const res = await loginEmail(email, password);
    localStorage.setItem('access_token', res.accessToken);
    sessionStorage.setItem(WELCOME_PENDING_KEY, '1');
    setToken(res.accessToken);
  }, []);

  const loginWithTokenFn = useCallback(async (tok: string) => {
    const res = await loginToken(tok);
    localStorage.setItem('access_token', res.accessToken);
    sessionStorage.setItem(WELCOME_PENDING_KEY, '1');
    setToken(res.accessToken);
  }, []);

  const logout = () => {
    localStorage.removeItem('access_token');
    sessionStorage.removeItem(WELCOME_PENDING_KEY);
    setToken(null);
    setUser(null);
    setData(null);
  };

  const value = useMemo(
    () => ({
      token,
      user,
      data,
      loading,
      error,
      login,
      loginWithToken: loginWithTokenFn,
      logout,
      refresh,
    }),
    [token, user, data, loading, error, refresh, login, loginWithTokenFn],
  );

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useAuth() {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error('AuthProvider ausente');
  return ctx;
}
