const API_BASE = import.meta.env.VITE_API_BASE || '/api';

export type User = {
  id: string;
  nome: string;
  email: string;
  role: string;
  convidadoId?: string | null;
  temSenha?: boolean;
};

export type Bootstrap = {
  user: User;
  config: Record<string, unknown>;
  gastos: any[];
  tarefas: any[];
  compromissos: any[];
  convidados: any[];
  padrinhos: any[];
  presentes: any[];
  fotos: any[];
  cardapio: any[];
  atracoes: any[];
  convites: any[];
  despedidas: any[];
  despedidaParticipantes: any[];
};

function authHeaders(token?: string | null): HeadersInit {
  const h: Record<string, string> = {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  };
  if (token) h.Authorization = `Bearer ${token}`;
  return h;
}

async function parse(res: Response) {
  const text = await res.text();
  let data: any = {};
  if (text && text !== 'null') {
    try {
      data = JSON.parse(text);
    } catch {
      if (res.status === 413) {
        throw new Error(
          'Arquivo muito grande. Envie fotos menores ou menos arquivos de uma vez.',
        );
      }
      throw new Error(
        `Falha no envio (${res.status}). Tente de novo com fotos menores.`,
      );
    }
  }
  if (!res.ok) {
    const msg = Array.isArray(data.message)
      ? data.message.join(', ')
      : data.message || `Erro ${res.status}`;
    throw new Error(msg);
  }
  return data;
}

async function api(token: string, method: string, path: string, body?: unknown) {
  const res = await fetch(`${API_BASE}${path}`, {
    method,
    headers: authHeaders(token),
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  return parse(res);
}

export async function loginEmail(email: string, password: string) {
  const res = await fetch(`${API_BASE}/auth/login`, {
    method: 'POST',
    headers: authHeaders(),
    body: JSON.stringify({ email, password }),
  });
  return parse(res) as Promise<{ accessToken: string; user: User }>;
}

export async function loginToken(token: string) {
  const res = await fetch(`${API_BASE}/auth/token`, {
    method: 'POST',
    headers: authHeaders(),
    body: JSON.stringify({ token }),
  });
  return parse(res) as Promise<{ accessToken: string; user: User }>;
}

export async function fetchBootstrap(token: string) {
  return api(token, 'GET', '/bootstrap') as Promise<Bootstrap>;
}

export async function fetchPublicConfig() {
  const res = await fetch(`${API_BASE}/public/config`);
  return parse(res);
}

export async function listNoivos(token: string) {
  const data = await api(token, 'GET', '/auth/noivos');
  return (Array.isArray(data) ? data : []) as User[];
}

export async function inviteParceiro(
  token: string,
  input: { nome: string; email: string; password: string; telefone?: string },
) {
  return api(token, 'POST', '/auth/invite-parceiro', input);
}

export async function changePassword(
  token: string,
  input: { currentPassword: string; newPassword: string },
) {
  return api(token, 'PUT', '/auth/change-password', input);
}

export async function completarCadastroConvidado(
  token: string,
  input: { email: string; password: string; nome?: string },
) {
  return api(token, 'POST', '/auth/completar-cadastro', input);
}

export function conviteLink(codigo?: string | null) {
  if (!codigo) return '';
  const configured = (import.meta.env.VITE_PUBLIC_WEB_URL || '').replace(
    /\/$/,
    '',
  );
  const origin =
    configured ||
    (typeof window !== 'undefined' ? window.location.origin : '');
  return `${origin}/convite/${encodeURIComponent(codigo)}`;
}

export async function putRsvp(
  token: string,
  status: string,
  acompanhanteId?: string,
) {
  return api(token, 'PUT', '/rsvp', {
    status,
    ...(acompanhanteId ? { acompanhanteId } : {}),
  });
}

export async function reservarPresente(token: string, id: string) {
  return api(token, 'POST', `/presentes/${id}/reservar`, {});
}

export async function upsertGasto(token: string, body: Record<string, unknown>) {
  return api(token, 'POST', '/gastos', body);
}

export async function deleteGasto(token: string, id: string) {
  return api(token, 'DELETE', `/gastos/${id}`);
}

export async function upsertTarefa(token: string, body: Record<string, unknown>) {
  return api(token, 'POST', '/tarefas', body);
}

export async function deleteTarefa(token: string, id: string) {
  return api(token, 'DELETE', `/tarefas/${id}`);
}

export async function upsertCompromisso(
  token: string,
  body: Record<string, unknown>,
) {
  return api(token, 'POST', '/compromissos', body);
}

export async function deleteCompromisso(token: string, id: string) {
  return api(token, 'DELETE', `/compromissos/${id}`);
}

export async function upsertConvidado(
  token: string,
  body: Record<string, unknown>,
) {
  return api(token, 'POST', '/convidados', body);
}

export async function deleteConvidado(token: string, id: string) {
  return api(token, 'DELETE', `/convidados/${id}`);
}

export async function regenerarTokenConvidado(token: string, id: string) {
  return api(token, 'POST', `/convidados/${id}/token`, {});
}

export async function vincularPadrinho(
  token: string,
  body: { convidadoId: string; tipo: string; papel?: string },
) {
  return api(token, 'POST', '/padrinhos', body);
}

export async function deletePadrinho(token: string, id: string) {
  return api(token, 'DELETE', `/padrinhos/${id}`);
}

export async function upsertPresente(
  token: string,
  body: Record<string, unknown>,
) {
  return api(token, 'POST', '/presentes', body);
}

export async function deletePresente(token: string, id: string) {
  return api(token, 'DELETE', `/presentes/${id}`);
}

export async function criarCerimonialista(token: string, nome: string) {
  return api(token, 'POST', '/convites/cerimonialista', { nome });
}

export async function salvarConfig(
  token: string,
  body: Record<string, unknown>,
) {
  return api(token, 'PUT', '/config', body);
}

export async function upsertCardapio(
  token: string,
  body: Record<string, unknown>,
) {
  return api(token, 'POST', '/cardapio', body);
}

export async function deleteCardapio(token: string, id: string) {
  return api(token, 'DELETE', `/cardapio/${id}`);
}

export async function upsertAtracao(
  token: string,
  body: Record<string, unknown>,
) {
  return api(token, 'POST', '/atracoes', body);
}

export async function deleteAtracao(token: string, id: string) {
  return api(token, 'DELETE', `/atracoes/${id}`);
}

export async function salvarDespedidaEvento(
  token: string,
  body: Record<string, unknown>,
) {
  return api(token, 'PUT', '/despedida/evento', body);
}

export async function upsertDespedidaParticipante(
  token: string,
  body: Record<string, unknown>,
) {
  return api(token, 'POST', '/despedida/participantes', body);
}

export async function deleteDespedidaParticipante(token: string, id: string) {
  return api(token, 'DELETE', `/despedida/participantes/${id}`);
}

export async function adicionarFotos(
  token: string,
  files: Blob[],
  meta: { tipo: string; legenda?: string; publico: boolean },
) {
  const fd = new FormData();
  files.forEach((file, i) => {
    const name =
      file instanceof File && file.name ? file.name : `foto-${i + 1}.jpg`;
    fd.append('files', file, name);
  });
  fd.append('tipo', meta.tipo);
  if (meta.legenda) fd.append('legenda', meta.legenda);
  fd.append('publico', meta.publico ? 'true' : 'false');
  const headers: Record<string, string> = { Accept: 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(`${API_BASE}/fotos`, {
    method: 'POST',
    headers,
    body: fd,
  });
  return parse(res);
}

export async function atualizarFoto(
  token: string,
  body: Record<string, unknown>,
) {
  return api(token, 'PUT', '/fotos', body);
}

export async function deleteFoto(token: string, id: string) {
  return api(token, 'DELETE', `/fotos/${id}`);
}
