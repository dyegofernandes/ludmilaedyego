import { FormEvent, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  adicionarFotos,
  atualizarFoto,
  changePassword,
  completarCadastroConvidado,
  conviteLink,
  criarCerimonialista,
  deleteAtracao,
  deleteCardapio,
  deleteCompromisso,
  deleteConvidado,
  deleteDespedidaParticipante,
  deleteFoto,
  deleteGasto,
  deletePadrinho,
  deletePresente,
  deleteTarefa,
  inviteParceiro,
  listNoivos,
  putRsvp,
  regenerarTokenConvidado,
  reservarPresente,
  salvarConfig,
  salvarDespedidaEvento,
  upsertAtracao,
  upsertCardapio,
  upsertCompromisso,
  upsertConvidado,
  upsertDespedidaParticipante,
  upsertGasto,
  upsertPresente,
  uploadPresenteImagem,
  upsertTarefa,
  vincularPadrinho,
  type User,
} from '../api';
import { useAuth } from '../auth';
import { BrandHeader } from '../components/Brand';
import { FotoLightbox } from '../components/FotoLightbox';
import {
  WelcomeSlideshow,
  clearWelcomePending,
  isWelcomePending,
} from '../components/WelcomeSlideshow';
import { compactarFoto } from '../image';
import {
  buildConviteWhatsAppCaption,
  shareConviteSlideshow,
} from '../inviteMessage';

type Tab =
  | 'resumo'
  | 'gastos'
  | 'tarefas'
  | 'agenda'
  | 'convidados'
  | 'padrinhos'
  | 'presentes'
  | 'tokens'
  | 'evento'
  | 'despedida'
  | 'fotos'
  | 'conta';

type AcompanhanteTipo =
  | 'esposa'
  | 'esposo'
  | 'namorada'
  | 'namorado'
  | 'amigo'
  | 'filho'
  | 'filho_adulto';

type Acompanhante = {
  id?: string;
  nome: string;
  tipo: AcompanhanteTipo;
  rsvp?: 'pendente' | 'sim' | 'nao' | 'talvez';
};

const ACOMP_TIPOS: AcompanhanteTipo[] = [
  'esposa',
  'esposo',
  'namorada',
  'namorado',
  'amigo',
  'filho',
  'filho_adulto',
];

const ACOMP_TIPO_LABEL: Record<AcompanhanteTipo, string> = {
  esposa: 'Esposa',
  esposo: 'Esposo',
  namorada: 'Namorada',
  namorado: 'Namorado',
  amigo: 'Amigo(a)',
  filho: 'Filho(a) criança',
  filho_adulto: 'Filho(a)',
};

const ACOMP_PARCEIRO = new Set<AcompanhanteTipo>([
  'esposa',
  'esposo',
  'namorada',
  'namorado',
]);

function normalizeAcompTipo(v: unknown): AcompanhanteTipo {
  return ACOMP_TIPOS.includes(v as AcompanhanteTipo)
    ? (v as AcompanhanteTipo)
    : 'amigo';
}

function ladoLabel(lado?: string) {
  if (lado === 'noivo') return 'Noivo';
  if (lado === 'noiva') return 'Noiva';
  return 'Ambos';
}

function parceiroDe(c: any): Acompanhante | null {
  const lista = Array.isArray(c?.acompanhantesLista)
    ? c.acompanhantesLista
    : Array.isArray(c?.acompanhantes)
      ? c.acompanhantes
      : [];
  for (const a of lista) {
    const tipo = normalizeAcompTipo(a?.tipo);
    const nome = String(a?.nome ?? '').trim();
    if (ACOMP_PARCEIRO.has(tipo) && nome) {
      return { id: a.id, nome, tipo, rsvp: a.rsvp };
    }
  }
  return null;
}

function nomeComParceiro(c: any): string {
  const nome = String(c?.nome ?? 'Convidado');
  const p = parceiroDe(c);
  return p ? `${nome} & ${p.nome}` : nome;
}
type TipoDespedida = 'solteiro' | 'solteira';

const TAB_KEY = 'casamento_tab';
const TABS: Tab[] = [
  'resumo',
  'gastos',
  'tarefas',
  'agenda',
  'convidados',
  'padrinhos',
  'presentes',
  'tokens',
  'evento',
  'despedida',
  'fotos',
  'conta',
];

function loadTab(): Tab {
  const v = sessionStorage.getItem(TAB_KEY);
  return TABS.includes(v as Tab) ? (v as Tab) : 'resumo';
}

function money(v: number) {
  return v.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
}

function fmtDate(v?: string | null) {
  if (!v) return '—';
  const d = new Date(v);
  if (Number.isNaN(d.getTime())) return '—';
  return d.toLocaleString('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  });
}

function toLocalInput(v?: string | null) {
  if (!v) return '';
  const d = new Date(v);
  if (Number.isNaN(d.getTime())) return '';
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

function toDateInput(v?: string | null) {
  if (!v) return '';
  const d = new Date(v);
  if (Number.isNaN(d.getTime())) return '';
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

function mapsUrl(query: string) {
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(query)}`;
}

function MapPlaceCard({
  titulo,
  endereco,
}: {
  titulo: string;
  endereco: string;
}) {
  const query = endereco.trim() || titulo.trim();
  if (!query) return null;
  return (
    <a
      className="map-card"
      href={mapsUrl(query)}
      target="_blank"
      rel="noreferrer"
    >
      <div className="map-preview">
        <span className="map-pin">📍</span>
        <span>Toque para abrir no Maps</span>
      </div>
      <div className="map-body">
        <strong>{titulo || 'Local'}</strong>
        {endereco && endereco !== titulo && <p>{endereco}</p>}
        <span className="map-link">Abrir no Google Maps</span>
      </div>
    </a>
  );
}

function EventoLocais({ cfg }: { cfg: Record<string, unknown> }) {
  const cerimoniaTitulo = String(cfg.localCerimonia || cfg.local || '').trim();
  const cerimoniaEndereco = String(
    cfg.enderecoCerimonia || cerimoniaTitulo,
  ).trim();
  const festaTitulo = String(cfg.localFesta || '').trim();
  const festaEndereco = String(cfg.enderecoFesta || festaTitulo).trim();
  const data = cfg.dataCerimonia ? String(cfg.dataCerimonia) : '';
  const temCerimonia = !!(cerimoniaTitulo || cerimoniaEndereco);
  const temFesta = !!(festaTitulo || festaEndereco);
  if (!data && !temCerimonia && !temFesta) return null;
  return (
    <div className="evento-locais">
      <h2>O grande dia</h2>
      {data && (
        <p className="evento-data">
          Data e horário · {fmtDate(data)}
        </p>
      )}
      {temCerimonia && (
        <>
          <h3>Cerimônia</h3>
          <MapPlaceCard
            titulo={cerimoniaTitulo || 'Local da cerimônia'}
            endereco={cerimoniaEndereco}
          />
        </>
      )}
      {temFesta && (
        <>
          <h3>Festa</h3>
          <MapPlaceCard
            titulo={festaTitulo || 'Local da festa'}
            endereco={festaEndereco}
          />
        </>
      )}
    </div>
  );
}

const emptyAcomp: Acompanhante = { nome: '', tipo: 'amigo', rsvp: 'pendente' };

const RSVP_OPTS = [
  ['sim', 'Sim'],
  ['nao', 'Não'],
  ['talvez', 'Talvez'],
] as const;

function rsvpLabel(v?: string) {
  if (v === 'sim') return 'Sim';
  if (v === 'nao') return 'Não';
  if (v === 'talvez') return 'Talvez';
  return 'Pendente';
}

function RsvpPessoa({
  nome,
  detalhe,
  atual,
  busy,
  onSelect,
}: {
  nome: string;
  detalhe?: string;
  atual: string;
  busy: boolean;
  onSelect: (status: string) => void;
}) {
  return (
    <div className="rsvp-hero">
      <h2>{nome}</h2>
      {detalhe ? <p className="evento-data">{detalhe}</p> : null}
      <p>
        Resposta: <strong>{rsvpLabel(atual)}</strong>
      </p>
      <div className="rsvp-actions">
        {RSVP_OPTS.map(([s, label]) => (
          <button
            key={s}
            type="button"
            className={`rsvp-btn rsvp-${s}${atual === s ? ' selected' : ''}`}
            disabled={busy}
            onClick={() => onSelect(s)}
          >
            {label}
          </button>
        ))}
      </div>
    </div>
  );
}

export default function HomePage() {
  const { user, data, logout, token, refresh } = useAuth();
  const [tab, setTab] = useState<Tab>(loadTab);
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState<string | null>(null);
  const [noivos, setNoivos] = useState<User[]>([]);

  const [gastoId, setGastoId] = useState<string | null>(null);
  const [gastoDesc, setGastoDesc] = useState('');
  const [gastoCat, setGastoCat] = useState('Geral');
  const [gastoValor, setGastoValor] = useState('');
  const [gastoStatus, setGastoStatus] = useState('pendente');

  const [tarefaId, setTarefaId] = useState<string | null>(null);
  const [tarefaTitulo, setTarefaTitulo] = useState('');
  const [tarefaDesc, setTarefaDesc] = useState('');
  const [tarefaStatus, setTarefaStatus] = useState('pendente');

  const [agendaId, setAgendaId] = useState<string | null>(null);
  const [agendaTitulo, setAgendaTitulo] = useState('');
  const [agendaInicio, setAgendaInicio] = useState('');
  const [agendaLocal, setAgendaLocal] = useState('');

  const [convId, setConvId] = useState<string | null>(null);
  const [convNome, setConvNome] = useState('');
  const [convTelefone, setConvTelefone] = useState('');
  const [convEmail, setConvEmail] = useState('');
  const [convMesa, setConvMesa] = useState('');
  const [convLado, setConvLado] = useState<'noivo' | 'noiva' | 'ambos'>('ambos');
  const [convEhCrianca, setConvEhCrianca] = useState(false);
  const [convRsvp, setConvRsvp] = useState<'pendente' | 'sim' | 'nao' | 'talvez'>(
    'pendente',
  );
  const [convAcomps, setConvAcomps] = useState<Acompanhante[]>([]);
  const [convToken, setConvToken] = useState<string | null>(null);

  const [padConvidadoId, setPadConvidadoId] = useState('');
  const [padTipo, setPadTipo] = useState<'padrinho' | 'madrinha'>('padrinho');
  const [padPapel, setPadPapel] = useState('');

  const [presenteId, setPresenteId] = useState<string | null>(null);
  const [presenteNome, setPresenteNome] = useState('');
  const [presenteValor, setPresenteValor] = useState('');
  const [presenteAudiencia, setPresenteAudiencia] = useState<
    'convidados' | 'padrinhos'
  >('convidados');
  const [presenteFiltro, setPresenteFiltro] = useState<
    'todos' | 'convidados' | 'padrinhos'
  >('todos');
  const [presenteImagemUrl, setPresenteImagemUrl] = useState<string | null>(
    null,
  );
  const [presenteImagemFile, setPresenteImagemFile] = useState<File | null>(
    null,
  );
  const [presenteImagemPreview, setPresenteImagemPreview] = useState<
    string | null
  >(null);

  const [cerimNome, setCerimNome] = useState('');

  const [noivaNome, setNoivaNome] = useState('');
  const [noivaEmail, setNoivaEmail] = useState('');
  const [noivaSenha, setNoivaSenha] = useState('');

  const [cadEmail, setCadEmail] = useState('');
  const [cadSenha, setCadSenha] = useState('');
  const [cadSenha2, setCadSenha2] = useState('');
  const [senhaAtual, setSenhaAtual] = useState('');
  const [senhaNova, setSenhaNova] = useState('');
  const [senhaConfirma, setSenhaConfirma] = useState('');

  const [evtNomeNoivo, setEvtNomeNoivo] = useState('');
  const [evtNomeNoiva, setEvtNomeNoiva] = useState('');
  const [evtData, setEvtData] = useState('');
  const [evtLocalCerim, setEvtLocalCerim] = useState('');
  const [evtEndCerim, setEvtEndCerim] = useState('');
  const [evtLocalFesta, setEvtLocalFesta] = useState('');
  const [evtEndFesta, setEvtEndFesta] = useState('');
  const [evtWhatsapp, setEvtWhatsapp] = useState('');
  const [evtMsg, setEvtMsg] = useState('');

  const [cardId, setCardId] = useState<string | null>(null);
  const [cardTitulo, setCardTitulo] = useState('');
  const [cardDesc, setCardDesc] = useState('');
  const [cardOrdem, setCardOrdem] = useState('0');

  const [atrId, setAtrId] = useState<string | null>(null);
  const [atrTitulo, setAtrTitulo] = useState('');
  const [atrDesc, setAtrDesc] = useState('');
  const [atrHorario, setAtrHorario] = useState('');
  const [atrOrdem, setAtrOrdem] = useState('0');

  const [despTipo, setDespTipo] = useState<TipoDespedida>('solteira');
  const [despData, setDespData] = useState('');
  const [despLocal, setDespLocal] = useState('');
  const [despEndereco, setDespEndereco] = useState('');
  const [despObs, setDespObs] = useState('');

  const [partId, setPartId] = useState<string | null>(null);
  const [partConvidadoId, setPartConvidadoId] = useState('');
  const [partTipo, setPartTipo] = useState<TipoDespedida>('solteira');
  const [partConf, setPartConf] = useState(false);
  const [partObs, setPartObs] = useState('');

  const [fotoTipo, setFotoTipo] = useState<'noivos' | 'evento' | 'outro'>(
    'evento',
  );
  const [fotoLegenda, setFotoLegenda] = useState('');
  const [fotoPublico, setFotoPublico] = useState(true);
  const [fotoArquivos, setFotoArquivos] = useState<File[]>([]);
  const [fotoPreviews, setFotoPreviews] = useState<string[]>([]);
  const [fotoAberta, setFotoAberta] = useState<string | null>(null);
  const [resumoDetail, setResumoDetail] = useState<{
    title: string;
    filterKey: string;
  } | null>(null);

  const role = user?.role ?? 'convidado';
  const isNoivo = role === 'noivo';
  const gestao = isNoivo || role === 'cerimonialista';
  const isGuest = role === 'convidado' || role === 'padrinho';
  const precisaCadastro = isGuest && !user?.temSenha;
  const [showWelcome, setShowWelcome] = useState(false);

  // Garante o slide após login/convite (token + bootstrap prontos)
  useEffect(() => {
    if (!user) return;
    const guest = user.role === 'convidado' || user.role === 'padrinho';
    if (guest && isWelcomePending()) {
      setShowWelcome(true);
      return;
    }
    if (!guest) {
      clearWelcomePending();
      setShowWelcome(false);
    }
  }, [user]);

  const dismissWelcome = useCallback(() => {
    clearWelcomePending();
    setShowWelcome(false);
  }, []);

  const totals = useMemo(() => {
    const gastos = data?.gastos ?? [];
    const previsto = gastos
      .filter((g) => g.status !== 'cancelado')
      .reduce((a, g) => a + Number(g.valorPrevisto || 0), 0);
    const pago = gastos
      .filter((g) => g.status === 'pago')
      .reduce(
        (a, g) => a + Number(g.valorReal ?? g.valorPrevisto ?? 0),
        0,
      );
    return { previsto, pago, restante: Math.max(0, previsto - pago) };
  }, [data]);

  const pessoas = useMemo(() => {
    const conv = data?.convidados ?? [];
    let total = 0;
    let adultos = 0;
    let criancas = 0;
    let confTotal = 0;
    let confAdultos = 0;
    let confCriancas = 0;
    let rsvpSim = 0;
    let rsvpNao = 0;
    let rsvpTalvez = 0;
    let rsvpPend = 0;
    for (const c of conv) {
      const ac = Array.isArray(c.acompanhantesLista)
        ? c.acompanhantesLista
        : [];
      const titularAdulto = c.ehCrianca ? 0 : 1;
      const titularCrianca = c.ehCrianca ? 1 : 0;
      total += 1 + ac.length;
      adultos += titularAdulto;
      criancas += titularCrianca;
      const conta = (rsvp: string, ad: number, cr: number) => {
        if (rsvp === 'sim') {
          rsvpSim += 1;
          confTotal += 1;
          confAdultos += ad;
          confCriancas += cr;
        } else if (rsvp === 'nao') rsvpNao += 1;
        else if (rsvp === 'talvez') rsvpTalvez += 1;
        else rsvpPend += 1;
      };
      conta(String(c.rsvp ?? 'pendente'), titularAdulto, titularCrianca);
      for (const a of ac) {
        const isKid = a.tipo === 'filho';
        adultos += isKid ? 0 : 1;
        criancas += isKid ? 1 : 0;
        conta(String(a.rsvp ?? 'pendente'), isKid ? 0 : 1, isKid ? 1 : 0);
      }
    }
    const hoje = new Date();
    hoje.setHours(0, 0, 0, 0);
    const agendaHoje = (data?.compromissos ?? []).filter((c) => {
      const d = new Date(c.inicio);
      if (Number.isNaN(d.getTime())) return false;
      d.setHours(0, 0, 0, 0);
      return d.getTime() === hoje.getTime();
    }).length;
    return {
      total,
      adultos,
      criancas,
      confTotal,
      confAdultos,
      confCriancas,
      rsvpSim,
      rsvpNao,
      rsvpTalvez,
      rsvpPend,
      convites: conv.length,
      pendentes: (data?.tarefas ?? []).filter((t) => t.status === 'pendente')
        .length,
      agendaHoje,
      reservados: (data?.presentes ?? []).filter((p) => p.reservadoPorConvidadoId)
        .length,
    };
  }, [data]);

  type PessoaLinha = {
    id: string;
    nome: string;
    rsvp: string;
    idade: 'adulto' | 'crianca';
    detalhe: string;
  };

  const pessoasLinhas = useMemo(() => {
    const out: PessoaLinha[] = [];
    for (const c of data?.convidados ?? []) {
      const ac = Array.isArray(c.acompanhantesLista)
        ? c.acompanhantesLista
        : [];
      out.push({
        id: String(c.id),
        nome: String(c.nome ?? 'Sem nome'),
        rsvp: String(c.rsvp ?? 'pendente'),
        idade: c.ehCrianca ? 'crianca' : 'adulto',
        detalhe: c.ehCrianca ? 'Criança' : 'Titular',
      });
      for (const a of ac) {
        const isKid = a.tipo === 'filho';
        const tipo = normalizeAcompTipo(a.tipo);
        out.push({
          id: String(a.id || `${c.id}-${a.nome}`),
          nome: String(a.nome ?? 'Acompanhante'),
          rsvp: String(a.rsvp ?? 'pendente'),
          idade: isKid ? 'crianca' : 'adulto',
          detalhe: `Acompanhante de ${c.nome}${
            isKid
              ? ' · criança'
              : ACOMP_PARCEIRO.has(tipo)
                ? ` · ${ACOMP_TIPO_LABEL[tipo].toLowerCase()}`
                : ''
          }`,
        });
      }
    }
    return out;
  }, [data]);

  const resumoFiltros: Record<
    string,
    { label: string; items: { nome: string; meta?: string }[] }
  > = useMemo(() => {
    const pessoas = (pred: (p: PessoaLinha) => boolean) =>
      pessoasLinhas.filter(pred).map((p) => ({
        nome: p.nome,
        meta: `${rsvpLabel(p.rsvp)} · ${p.detalhe}`,
      }));

    const gastos = (data?.gastos ?? []).filter((g) => g.status !== 'cancelado');
    const hoje = new Date();
    hoje.setHours(0, 0, 0, 0);

    return {
      previsto: {
        label: 'Gastos previstos',
        items: gastos.map((g) => ({
          nome: String(g.descricao ?? 'Gasto'),
          meta: `${money(Number(g.valorPrevisto || 0))} · ${g.categoria || '—'}`,
        })),
      },
      pago: {
        label: 'Gastos pagos',
        items: gastos
          .filter((g) => g.status === 'pago')
          .map((g) => ({
            nome: String(g.descricao ?? 'Gasto'),
            meta: money(Number(g.valorReal ?? g.valorPrevisto ?? 0)),
          })),
      },
      restante: {
        label: 'Gastos pendentes',
        items: gastos
          .filter((g) => g.status === 'pendente')
          .map((g) => ({
            nome: String(g.descricao ?? 'Gasto'),
            meta: money(Number(g.valorPrevisto || 0)),
          })),
      },
      confirmados: {
        label: 'Pessoas confirmadas (RSVP Sim)',
        items: pessoas((p) => p.rsvp === 'sim'),
      },
      total: {
        label: 'Todas as pessoas',
        items: pessoas(() => true),
      },
      adultos: {
        label: 'Adultos',
        items: pessoas((p) => p.idade === 'adulto'),
      },
      criancas: {
        label: 'Crianças',
        items: pessoas((p) => p.idade === 'crianca'),
      },
      confAdultos: {
        label: 'Confirmados · adultos',
        items: pessoas((p) => p.rsvp === 'sim' && p.idade === 'adulto'),
      },
      confCriancas: {
        label: 'Confirmados · crianças',
        items: pessoas((p) => p.rsvp === 'sim' && p.idade === 'crianca'),
      },
      rsvpNao: {
        label: 'RSVP · Não',
        items: pessoas((p) => p.rsvp === 'nao'),
      },
      rsvpTalvez: {
        label: 'RSVP · Talvez',
        items: pessoas((p) => p.rsvp === 'talvez'),
      },
      rsvpPend: {
        label: 'RSVP · Pendente',
        items: pessoas((p) => p.rsvp === 'pendente'),
      },
      tarefas: {
        label: 'Tarefas pendentes',
        items: (data?.tarefas ?? [])
          .filter((t) => t.status === 'pendente')
          .map((t) => ({
            nome: String(t.titulo ?? 'Tarefa'),
            meta: t.descricao ? String(t.descricao) : undefined,
          })),
      },
      agendaHoje: {
        label: 'Compromissos hoje',
        items: (data?.compromissos ?? [])
          .filter((c) => {
            const d = new Date(c.inicio);
            if (Number.isNaN(d.getTime())) return false;
            d.setHours(0, 0, 0, 0);
            return d.getTime() === hoje.getTime();
          })
          .map((c) => ({
            nome: String(c.titulo ?? 'Compromisso'),
            meta: c.local ? String(c.local) : undefined,
          })),
      },
      presentes: {
        label: 'Presentes reservados',
        items: (data?.presentes ?? [])
          .filter((p) => p.reservadoPorConvidadoId)
          .map((p) => {
            const quem = (data?.convidados ?? []).find(
              (c) => c.id === p.reservadoPorConvidadoId,
            );
            return {
              nome: String(p.nome ?? 'Presente'),
              meta: [
                p.audiencia === 'padrinhos' ? 'Padrinhos' : 'Convidados',
                quem?.nome ? `Reservado por ${quem.nome}` : 'Reservado',
              ].join(' · '),
            };
          }),
      },
    };
  }, [data, pessoasLinhas]);

  const openResumoDetail = (filterKey: string) => {
    const f = resumoFiltros[filterKey];
    if (!f) return;
    setResumoDetail({ title: f.label, filterKey });
  };

  const padrinhoConvidadoIds = useMemo(
    () => new Set((data?.padrinhos ?? []).map((p) => p.convidadoId)),
    [data],
  );

  const convidadosDisponiveis = useMemo(
    () =>
      (data?.convidados ?? []).filter((c) => !padrinhoConvidadoIds.has(c.id)),
    [data, padrinhoConvidadoIds],
  );

  const participantesConvidadoIds = useMemo(() => {
    const map = new Map<string, Set<string>>();
    for (const p of data?.despedidaParticipantes ?? []) {
      if (!p.convidadoId) continue;
      const set = map.get(p.tipo) ?? new Set<string>();
      set.add(p.convidadoId);
      map.set(p.tipo, set);
    }
    return map;
  }, [data]);

  const convidadosDespedida = useMemo(() => {
    const ja = participantesConvidadoIds.get(partTipo) ?? new Set<string>();
    return (data?.convidados ?? []).filter(
      (c) =>
        !ja.has(c.id) ||
        (partId != null &&
          (data?.despedidaParticipantes ?? []).some(
            (p) => p.id === partId && p.convidadoId === c.id,
          )),
    );
  }, [data, partTipo, partId, participantesConvidadoIds]);

  const convidadoById = useMemo(() => {
    const map = new Map<string, any>();
    for (const c of data?.convidados ?? []) map.set(c.id, c);
    return map;
  }, [data]);

  const meuConvidado = useMemo(() => {
    const id = user?.convidadoId;
    if (!id) return null;
    return convidadoById.get(id) ?? null;
  }, [user, convidadoById]);

  const meuRsvp = (meuConvidado?.rsvp ?? 'pendente') as
    | 'pendente'
    | 'sim'
    | 'nao'
    | 'talvez';

  const meusAcomps: Acompanhante[] = useMemo(() => {
    const lista = meuConvidado?.acompanhantesLista;
    return Array.isArray(lista) ? lista : [];
  }, [meuConvidado]);

  useEffect(() => {
    sessionStorage.setItem(TAB_KEY, tab);
  }, [tab]);

  useEffect(() => {
    if (tab === 'conta' && !isNoivo && !isGuest) setTab('resumo');
  }, [tab, isNoivo, isGuest]);

  useEffect(() => {
    if (!token || !isNoivo || tab !== 'conta') return;
    listNoivos(token)
      .then(setNoivos)
      .catch(() => setNoivos([]));
  }, [token, isNoivo, tab, msg]);

  const lastCfgKey = useRef('');
  useEffect(() => {
    const c = data?.config;
    if (!c) return;
    const key = JSON.stringify(c);
    if (key === lastCfgKey.current) return;
    lastCfgKey.current = key;
    setEvtNomeNoivo(String(c.nomeNoivo ?? ''));
    setEvtNomeNoiva(String(c.nomeNoiva ?? ''));
    setEvtData(toLocalInput(String(c.dataCerimonia ?? '')));
    setEvtLocalCerim(String(c.localCerimonia || c.local || ''));
    setEvtEndCerim(String(c.enderecoCerimonia ?? ''));
    setEvtLocalFesta(String(c.localFesta ?? ''));
    setEvtEndFesta(String(c.enderecoFesta ?? ''));
    setEvtWhatsapp(String(c.whatsapp ?? ''));
    setEvtMsg(String(c.mensagemBoasVindas ?? ''));
  }, [data?.config]);

  const lastDespKey = useRef('');
  useEffect(() => {
    const ev = (data?.despedidas ?? []).find((d) => d.tipo === despTipo);
    const key = `${despTipo}:${JSON.stringify(ev ?? null)}`;
    if (key === lastDespKey.current) return;
    lastDespKey.current = key;
    if (!ev) {
      setDespData('');
      setDespLocal('');
      setDespEndereco('');
      setDespObs('');
      return;
    }
    setDespData(toDateInput(ev.data));
    setDespLocal(ev.local ?? '');
    setDespEndereco(ev.endereco ?? '');
    setDespObs(ev.observacoes ?? '');
  }, [data?.despedidas, despTipo]);

  const nav: { id: Tab; label: string; show: boolean }[] = [
    { id: 'resumo', label: 'Resumo', show: true },
    { id: 'gastos', label: 'Gastos', show: gestao },
    { id: 'tarefas', label: 'Tarefas', show: role !== 'convidado' },
    { id: 'agenda', label: 'Agenda', show: gestao },
    { id: 'convidados', label: 'Convidados', show: gestao },
    { id: 'padrinhos', label: 'Padrinhos', show: gestao },
    { id: 'presentes', label: role === 'padrinho' ? 'Presentes dos padrinhos' : 'Presentes', show: true },
    { id: 'tokens', label: 'Cerimonialista', show: gestao },
    { id: 'evento', label: 'Evento', show: true },
    { id: 'fotos', label: 'Fotos', show: true },
    { id: 'despedida', label: 'Despedida', show: gestao },
    { id: 'conta', label: 'Conta', show: isNoivo || isGuest },
  ];

  async function run(action: () => Promise<unknown>, okMsg: string) {
    if (!token) return;
    setBusy(true);
    setMsg(null);
    try {
      await action();
      await refresh(true);
      setMsg(okMsg);
    } catch (e) {
      setMsg(e instanceof Error ? e.message : 'Erro');
    } finally {
      setBusy(false);
    }
  }

  function resetGasto() {
    setGastoId(null);
    setGastoDesc('');
    setGastoCat('Geral');
    setGastoValor('');
    setGastoStatus('pendente');
  }

  function resetTarefa() {
    setTarefaId(null);
    setTarefaTitulo('');
    setTarefaDesc('');
    setTarefaStatus('pendente');
  }

  function resetAgenda() {
    setAgendaId(null);
    setAgendaTitulo('');
    setAgendaInicio('');
    setAgendaLocal('');
  }

  function resetConvidado() {
    setConvId(null);
    setConvNome('');
    setConvTelefone('');
    setConvEmail('');
    setConvMesa('');
    setConvLado('ambos');
    setConvEhCrianca(false);
    setConvRsvp('pendente');
    setConvAcomps([]);
    setConvToken(null);
  }

  function resetPresente() {
    if (presenteImagemPreview?.startsWith('blob:')) {
      URL.revokeObjectURL(presenteImagemPreview);
    }
    setPresenteId(null);
    setPresenteNome('');
    setPresenteValor('');
    setPresenteAudiencia('convidados');
    setPresenteImagemUrl(null);
    setPresenteImagemFile(null);
    setPresenteImagemPreview(null);
  }

  function onPresenteImagem(list?: FileList | null) {
    if (presenteImagemPreview?.startsWith('blob:')) {
      URL.revokeObjectURL(presenteImagemPreview);
    }
    const file = Array.from(list ?? []).find((f) =>
      f.type.startsWith('image/'),
    );
    if (!file) {
      setPresenteImagemFile(null);
      setPresenteImagemPreview(presenteImagemUrl);
      return;
    }
    setPresenteImagemFile(file);
    setPresenteImagemPreview(URL.createObjectURL(file));
  }

  function limparPresenteImagem() {
    if (presenteImagemPreview?.startsWith('blob:')) {
      URL.revokeObjectURL(presenteImagemPreview);
    }
    setPresenteImagemFile(null);
    setPresenteImagemUrl(null);
    setPresenteImagemPreview(null);
  }

  async function onRsvp(status: string, acompanhanteId?: string) {
    await run(
      () => putRsvp(token!, status, acompanhanteId),
      'RSVP atualizado',
    );
  }

  async function onReservar(id: string) {
    await run(() => reservarPresente(token!, id), 'Presente reservado');
  }

  async function onSaveGasto(e: FormEvent) {
    e.preventDefault();
    await run(
      () =>
        upsertGasto(token!, {
          ...(gastoId ? { id: gastoId } : {}),
          descricao: gastoDesc,
          categoria: gastoCat,
          valorPrevisto: Number(gastoValor || 0),
          status: gastoStatus,
        }),
      gastoId ? 'Gasto atualizado' : 'Gasto cadastrado',
    );
    resetGasto();
  }

  async function onSaveTarefa(e: FormEvent) {
    e.preventDefault();
    await run(
      () =>
        upsertTarefa(token!, {
          ...(tarefaId ? { id: tarefaId } : {}),
          titulo: tarefaTitulo,
          descricao: tarefaDesc || undefined,
          status: tarefaStatus,
        }),
      tarefaId ? 'Tarefa atualizada' : 'Tarefa cadastrada',
    );
    resetTarefa();
  }

  async function onSaveAgenda(e: FormEvent) {
    e.preventDefault();
    await run(
      () =>
        upsertCompromisso(token!, {
          ...(agendaId ? { id: agendaId } : {}),
          titulo: agendaTitulo,
          inicio: new Date(agendaInicio).toISOString(),
          local: agendaLocal || undefined,
        }),
      agendaId ? 'Compromisso atualizado' : 'Compromisso cadastrado',
    );
    resetAgenda();
  }

  async function onSaveConvidado(e: FormEvent) {
    e.preventDefault();
    const acompanhantesLista = convAcomps
      .filter((a) => a.nome.trim())
      .map((a, i) => ({
        id: a.id || `ac-${Date.now()}-${i}`,
        nome: a.nome.trim(),
        tipo: a.tipo,
        rsvp: a.rsvp || 'pendente',
      }));
    await run(
      () =>
        upsertConvidado(token!, {
          ...(convId ? { id: convId } : {}),
          nome: convNome,
          telefone: convTelefone || undefined,
          email: convEmail || undefined,
          mesa: convMesa || undefined,
          lado: convLado,
          ehCrianca: convEhCrianca,
          rsvp: convRsvp,
          acompanhantesLista,
        }),
      convId ? 'Convidado atualizado' : 'Convidado cadastrado',
    );
    resetConvidado();
  }

  async function onSavePresente(e: FormEvent) {
    e.preventDefault();
    await run(async () => {
      let imagemUrl = presenteImagemUrl;
      if (presenteImagemFile) {
        const compactada = await compactarFoto(presenteImagemFile, 1200, 0.85);
        const uploaded = await uploadPresenteImagem(token!, compactada);
        imagemUrl = uploaded.url;
      }
      await upsertPresente(token!, {
        ...(presenteId ? { id: presenteId } : {}),
        nome: presenteNome,
        valorEstimado: presenteValor ? Number(presenteValor) : undefined,
        audiencia: presenteAudiencia,
        imagemUrl,
      });
    }, presenteId ? 'Presente atualizado' : 'Presente cadastrado');
    resetPresente();
  }

  async function onVincularPadrinho(e: FormEvent) {
    e.preventDefault();
    await run(
      () =>
        vincularPadrinho(token!, {
          convidadoId: padConvidadoId,
          tipo: padTipo,
          papel: padPapel || undefined,
        }),
      'Padrinho vinculado',
    );
    setPadConvidadoId('');
    setPadTipo('padrinho');
    setPadPapel('');
  }

  async function onCriarCerimonialista(e: FormEvent) {
    e.preventDefault();
    await run(
      () => criarCerimonialista(token!, cerimNome),
      'Link de acesso do cerimonialista criado',
    );
    setCerimNome('');
  }

  async function onRegenerarToken() {
    if (!convId || !token) return;
    setBusy(true);
    setMsg(null);
    try {
      const res = (await regenerarTokenConvidado(token, convId)) as {
        token?: string;
      };
      await refresh(true);
      setConvToken(res?.token ?? null);
      setMsg('Link de acesso gerado. Copie e envie ao convidado.');
    } catch (e) {
      setMsg(e instanceof Error ? e.message : 'Erro');
    } finally {
      setBusy(false);
    }
  }

  async function onInviteNoiva(e: FormEvent) {
    e.preventDefault();
    await run(
      () =>
        inviteParceiro(token!, {
          nome: noivaNome,
          email: noivaEmail,
          password: noivaSenha,
        }),
      'Noiva cadastrada com acesso total. Ela entra em Noivos com o e-mail dela.',
    );
    setNoivaNome('');
    setNoivaEmail('');
    setNoivaSenha('');
    if (token) setNoivos(await listNoivos(token));
  }

  async function onChangePassword(e: FormEvent) {
    e.preventDefault();
    if (senhaNova !== senhaConfirma) {
      setMsg('As senhas novas não coincidem.');
      return;
    }
    await run(
      () =>
        changePassword(token!, {
          currentPassword: senhaAtual,
          newPassword: senhaNova,
        }),
      'Senha alterada com sucesso.',
    );
    setSenhaAtual('');
    setSenhaNova('');
    setSenhaConfirma('');
  }

  async function copyConvite(codigo?: string | null) {
    const link = conviteLink(codigo);
    if (!link) {
      setMsg('Gere o link deste convidado primeiro');
      return;
    }
    await navigator.clipboard.writeText(link);
    setMsg('Link copiado. O convidado entra só na área de convidado.');
  }

  async function onCopiarLinkConvidado(id: string, codigo?: string | null) {
    if (!token) return;
    if (codigo) {
      await copyConvite(codigo);
      return;
    }
    setBusy(true);
    try {
      const res = (await regenerarTokenConvidado(token, id)) as {
        token?: string;
      };
      await refresh(true);
      await copyConvite(res?.token);
    } catch (e) {
      setMsg(e instanceof Error ? e.message : 'Erro');
    } finally {
      setBusy(false);
    }
  }

  async function ensureConvidadoToken(
    id: string,
    codigo?: string | null,
  ): Promise<string | null> {
    if (codigo) return codigo;
    if (!token) return null;
    const res = (await regenerarTokenConvidado(token, id)) as {
      token?: string;
    };
    await refresh(true);
    return res?.token ?? null;
  }

  async function onEnviarWhatsAppConvidado(
    id: string,
    opts: {
      token?: string | null;
      nome: string;
      telefone?: string | null;
    },
  ) {
    if (!token) return;
    setBusy(true);
    try {
      const codigo = await ensureConvidadoToken(id, opts.token);
      const link = conviteLink(codigo);
      if (!link) {
        setMsg('Não foi possível gerar o link deste convidado.');
        return;
      }
      const caption = buildConviteWhatsAppCaption({ link });
      const mode = await shareConviteSlideshow({
        caption,
        telefone: opts.telefone,
      });
      if (mode === 'shared') {
        setMsg(
          'Escolha o WhatsApp — convite, vídeo e link de confirmação vão juntos.',
        );
      } else {
        setMsg(
          'WhatsApp aberto com o link. Anexe a imagem e o vídeo do convite que foram baixados.',
        );
      }
    } catch (e) {
      if (e instanceof Error && e.name === 'AbortError') {
        setMsg('Compartilhamento cancelado.');
      } else {
        setMsg(e instanceof Error ? e.message : 'Erro ao enviar convite');
      }
    } finally {
      setBusy(false);
    }
  }

  async function onCompletarCadastro(e: FormEvent) {
    e.preventDefault();
    if (cadSenha !== cadSenha2) {
      setMsg('As senhas não coincidem.');
      return;
    }
    await run(
      () =>
        completarCadastroConvidado(token!, {
          email: cadEmail,
          password: cadSenha,
          nome: user?.nome,
        }),
      'Cadastro criado. Da próxima vez entre em Convidados com e-mail e senha.',
    );
    setCadEmail('');
    setCadSenha('');
    setCadSenha2('');
  }

  async function onSaveEvento(e: FormEvent) {
    e.preventDefault();
    await run(
      () =>
        salvarConfig(token!, {
          nomeNoivo: evtNomeNoivo,
          nomeNoiva: evtNomeNoiva,
          dataCerimonia: evtData || null,
          local: evtLocalCerim || null,
          localCerimonia: evtLocalCerim || null,
          enderecoCerimonia: evtEndCerim || null,
          localFesta: evtLocalFesta || null,
          enderecoFesta: evtEndFesta || null,
          whatsapp: evtWhatsapp || null,
          mensagemBoasVindas: evtMsg || null,
        }),
      'Dados do evento salvos',
    );
  }

  function resetCardapio() {
    setCardId(null);
    setCardTitulo('');
    setCardDesc('');
    setCardOrdem('0');
  }

  async function onSaveCardapio(e: FormEvent) {
    e.preventDefault();
    await run(
      () =>
        upsertCardapio(token!, {
          ...(cardId ? { id: cardId } : {}),
          titulo: cardTitulo,
          descricao: cardDesc || undefined,
          ordem: Number(cardOrdem) || 0,
        }),
      cardId ? 'Item do cardápio atualizado' : 'Item do cardápio cadastrado',
    );
    resetCardapio();
  }

  function resetAtracao() {
    setAtrId(null);
    setAtrTitulo('');
    setAtrDesc('');
    setAtrHorario('');
    setAtrOrdem('0');
  }

  async function onSaveAtracao(e: FormEvent) {
    e.preventDefault();
    await run(
      () =>
        upsertAtracao(token!, {
          ...(atrId ? { id: atrId } : {}),
          titulo: atrTitulo,
          descricao: atrDesc || undefined,
          horario: atrHorario || undefined,
          ordem: Number(atrOrdem) || 0,
        }),
      atrId ? 'Atração atualizada' : 'Atração cadastrada',
    );
    resetAtracao();
  }

  async function onSaveDespedida(e: FormEvent) {
    e.preventDefault();
    await run(
      () =>
        salvarDespedidaEvento(token!, {
          tipo: despTipo,
          data: despData || null,
          local: despLocal || null,
          endereco: despEndereco || null,
          observacoes: despObs || null,
        }),
      'Despedida salva',
    );
  }

  function resetParticipante() {
    setPartId(null);
    setPartConvidadoId('');
    setPartTipo('solteira');
    setPartConf(false);
    setPartObs('');
  }

  async function onSaveParticipante(e: FormEvent) {
    e.preventDefault();
    if (!partConvidadoId) {
      setMsg('Selecione um convidado');
      return;
    }
    const conv = convidadoById.get(partConvidadoId);
    await run(
      () =>
        upsertDespedidaParticipante(token!, {
          ...(partId ? { id: partId } : {}),
          convidadoId: partConvidadoId,
          nome: conv?.nome ?? '',
          tipo: partTipo,
          telefone: conv?.telefone || undefined,
          confirmado: partConf,
          observacoes: partObs || undefined,
        }),
      partId ? 'Participante atualizado' : 'Participante cadastrado',
    );
    resetParticipante();
  }

  function resetFoto() {
    fotoPreviews.forEach((u) => URL.revokeObjectURL(u));
    setFotoArquivos([]);
    setFotoPreviews([]);
    setFotoLegenda('');
    setFotoTipo('evento');
    setFotoPublico(true);
  }

  function onFotoFiles(list?: FileList | null) {
    fotoPreviews.forEach((u) => URL.revokeObjectURL(u));
    const files = Array.from(list ?? []).filter((f) =>
      f.type.startsWith('image/'),
    );
    setFotoArquivos(files);
    setFotoPreviews(files.map((f) => URL.createObjectURL(f)));
  }

  async function onSaveFoto(e: FormEvent) {
    e.preventDefault();
    if (!fotoArquivos.length) {
      setMsg('Escolha ao menos uma foto');
      return;
    }
    await run(async () => {
      const compactadas: File[] = [];
      for (const file of fotoArquivos) {
        compactadas.push(await compactarFoto(file));
      }
      await adicionarFotos(token!, compactadas, {
        tipo: fotoTipo,
        legenda: fotoLegenda || undefined,
        publico: fotoPublico,
      });
    }, fotoArquivos.length > 1 ? `${fotoArquivos.length} fotos enviadas` : 'Foto enviada');
    resetFoto();
  }

  function editGasto(g: any) {
    setGastoId(g.id);
    setGastoDesc(g.descricao ?? '');
    setGastoCat(g.categoria ?? 'Geral');
    setGastoValor(String(g.valorPrevisto ?? ''));
    setGastoStatus(g.status ?? 'pendente');
  }

  function editTarefa(t: any) {
    setTarefaId(t.id);
    setTarefaTitulo(t.titulo ?? '');
    setTarefaDesc(t.descricao ?? '');
    setTarefaStatus(t.status ?? 'pendente');
  }

  function editAgenda(c: any) {
    setAgendaId(c.id);
    setAgendaTitulo(c.titulo ?? '');
    setAgendaInicio(toLocalInput(c.inicio));
    setAgendaLocal(c.local ?? '');
  }

  function editConvidado(c: any) {
    setConvId(c.id);
    setConvNome(c.nome ?? '');
    setConvTelefone(c.telefone ?? '');
    setConvEmail(c.email ?? '');
    setConvMesa(c.mesa ?? '');
    setConvLado(c.lado ?? 'ambos');
    setConvEhCrianca(!!c.ehCrianca);
    setConvRsvp(c.rsvp ?? 'pendente');
    const lista = Array.isArray(c.acompanhantesLista)
      ? c.acompanhantesLista
      : Array.isArray(c.acompanhantes)
        ? c.acompanhantes
        : [];
    setConvAcomps(
      lista.map((a: any) => ({
        id: a.id,
        nome: a.nome ?? '',
        tipo: normalizeAcompTipo(a.tipo),
        rsvp: (['sim', 'nao', 'talvez', 'pendente'].includes(a.rsvp)
          ? a.rsvp
          : 'pendente') as Acompanhante['rsvp'],
      })),
    );
    setConvToken(c.token ?? null);
  }

  function editPresente(p: any) {
    if (presenteImagemPreview?.startsWith('blob:')) {
      URL.revokeObjectURL(presenteImagemPreview);
    }
    setPresenteId(p.id);
    setPresenteNome(p.nome ?? '');
    setPresenteValor(
      p.valorEstimado != null ? String(p.valorEstimado) : '',
    );
    setPresenteAudiencia(
      p.audiencia === 'padrinhos' ? 'padrinhos' : 'convidados',
    );
    setPresenteImagemUrl(p.imagemUrl ?? null);
    setPresenteImagemFile(null);
    setPresenteImagemPreview(p.imagemUrl ?? null);
  }

  const cfg = data?.config ?? {};

  return (
    <div className="shell">
      {showWelcome && isGuest ? (
        <WelcomeSlideshow onDone={dismissWelcome} />
      ) : null}
      <div className="topbar">
        <BrandHeader
          compact
          subtitle={`${user?.nome ?? ''} · ${user?.email || role}${isNoivo ? ' · acesso total' : ''}`}
        />
        <button className="ghost" onClick={logout}>
          Sair
        </button>
      </div>

      <div className="nav">
        {nav
          .filter((n) => n.show)
          .map((n) => (
            <button
              key={n.id}
              className={tab === n.id ? 'active' : ''}
              onClick={() => setTab(n.id)}
            >
              {n.label}
            </button>
          ))}
      </div>

      {msg && <p className="hint">{msg}</p>}

      {tab === 'conta' && (isNoivo || isGuest) && (
        <div className="list">
          {isGuest && precisaCadastro && (
            <div className="panel">
              <h2 style={{ marginTop: 0 }}>Criar meu cadastro</h2>
              <p style={{ color: 'var(--muted)', marginTop: 0 }}>
                Depois você entra na aba Convidados com e-mail e senha. O
                acesso continua só na área de convidado.
              </p>
              <form onSubmit={onCompletarCadastro}>
                <label>E-mail</label>
                <input
                  type="email"
                  value={cadEmail}
                  onChange={(e) => setCadEmail(e.target.value)}
                  required
                  autoComplete="username"
                />
                <label>Senha</label>
                <input
                  type="password"
                  value={cadSenha}
                  onChange={(e) => setCadSenha(e.target.value)}
                  required
                  minLength={6}
                  autoComplete="new-password"
                />
                <label>Confirmar senha</label>
                <input
                  type="password"
                  value={cadSenha2}
                  onChange={(e) => setCadSenha2(e.target.value)}
                  required
                  minLength={6}
                  autoComplete="new-password"
                />
                <button className="primary" disabled={busy}>
                  Criar cadastro
                </button>
              </form>
            </div>
          )}
          {isGuest && user?.temSenha && (
            <div className="panel">
              <h2 style={{ marginTop: 0 }}>Sua conta</h2>
              <p>
                {user.email || user.nome} · acesso de convidado
              </p>
            </div>
          )}
          {(isNoivo || (isGuest && user?.temSenha)) && (
            <div className="panel">
              <h2 style={{ marginTop: 0 }}>Trocar senha</h2>
              <form onSubmit={onChangePassword}>
                <label>Senha atual</label>
                <input
                  type="password"
                  value={senhaAtual}
                  onChange={(e) => setSenhaAtual(e.target.value)}
                  required
                />
                <label>Nova senha</label>
                <input
                  type="password"
                  value={senhaNova}
                  onChange={(e) => setSenhaNova(e.target.value)}
                  required
                  minLength={6}
                />
                <label>Confirmar nova senha</label>
                <input
                  type="password"
                  value={senhaConfirma}
                  onChange={(e) => setSenhaConfirma(e.target.value)}
                  required
                  minLength={6}
                />
                <button className="primary" disabled={busy}>
                  Salvar nova senha
                </button>
              </form>
            </div>
          )}

          {isNoivo && (
            <div className="panel">
              <h2 style={{ marginTop: 0 }}>
                Acessos do casal ({noivos.length}/2)
              </h2>
              <p style={{ color: 'var(--muted)' }}>
                Noivo e noiva têm o mesmo acesso total ao sistema.
              </p>
              <div className="list" style={{ marginBottom: 16 }}>
                {noivos.map((n) => (
                  <div key={n.id} className="item">
                    <h3>{n.nome}</h3>
                    <p>{n.email || 'Sem e-mail'}</p>
                  </div>
                ))}
              </div>
              {noivos.length < 2 && (
                <form onSubmit={onInviteNoiva}>
                  <h3>Cadastrar noiva</h3>
                  <p style={{ color: 'var(--muted)', marginTop: 0 }}>
                    Ela entra na aba Noivos com este e-mail e senha (acesso
                    total).
                  </p>
                  <label>Nome</label>
                  <input
                    value={noivaNome}
                    onChange={(e) => setNoivaNome(e.target.value)}
                    required
                  />
                  <label>E-mail</label>
                  <input
                    type="email"
                    value={noivaEmail}
                    onChange={(e) => setNoivaEmail(e.target.value)}
                    required
                  />
                  <label>Senha inicial</label>
                  <input
                    type="password"
                    value={noivaSenha}
                    onChange={(e) => setNoivaSenha(e.target.value)}
                    required
                    minLength={6}
                  />
                  <button className="primary" disabled={busy}>
                    Cadastrar noiva
                  </button>
                </form>
              )}
            </div>
          )}
        </div>
      )}

      {tab === 'resumo' && (
        <div className="list">
          {!gestao && (
            <>
              {cfg.mensagemBoasVindas ? (
                <p className="evento-data" style={{ fontSize: '1.05rem' }}>
                  {String(cfg.mensagemBoasVindas)}
                </p>
              ) : null}
              <EventoLocais cfg={cfg} />
              {(data?.cardapio ?? []).length > 0 && (
                <div className="item">
                  <h3>Cardápio</h3>
                  {(data?.cardapio ?? []).map((i) => (
                    <p key={i.id}>
                      <strong>{i.titulo}</strong>
                      {i.descricao ? ` — ${i.descricao}` : ''}
                    </p>
                  ))}
                </div>
              )}
              {(data?.atracoes ?? []).length > 0 && (
                <div className="item">
                  <h3>Atrações</h3>
                  {(data?.atracoes ?? []).map((i) => (
                    <p key={i.id}>
                      <strong>{i.horario || '—'}</strong> · {i.titulo}
                    </p>
                  ))}
                </div>
              )}
              <RsvpPessoa
                nome={meuConvidado?.nome ? `Você · ${meuConvidado.nome}` : 'Você'}
                detalhe="Confirme sua presença"
                atual={meuRsvp}
                busy={busy}
                onSelect={(s) => onRsvp(s)}
              />
              {meusAcomps.map((a, i) => (
                <RsvpPessoa
                  key={a.id || `${a.nome}-${i}`}
                  nome={a.nome}
                  detalhe={`Acompanhante · ${
                    a.tipo === 'filho'
                      ? 'criança'
                      : ACOMP_TIPO_LABEL[normalizeAcompTipo(a.tipo)].toLowerCase()
                  } — confirme a presença desta pessoa`}
                  atual={a.rsvp || 'pendente'}
                  busy={busy || !a.id}
                  onSelect={(s) => {
                    if (a.id) void onRsvp(s, a.id);
                  }}
                />
              ))}
              {precisaCadastro && (
                <div className="panel">
                  <h2 style={{ marginTop: 0 }}>Crie seu cadastro</h2>
                  <p className="hint" style={{ textAlign: 'left' }}>
                    Assim você entra sempre com e-mail e senha, só na área de
                    convidado.
                  </p>
                  <button
                    type="button"
                    className="primary"
                    onClick={() => setTab('conta')}
                  >
                    Cadastrar e-mail e senha
                  </button>
                </div>
              )}
            </>
          )}
          {gestao && (
            <>
              <div className="grid">
                <button
                  type="button"
                  className="stat stat-click"
                  onClick={() => openResumoDetail('previsto')}
                >
                  Previsto
                  <strong>{money(totals.previsto)}</strong>
                </button>
                <button
                  type="button"
                  className="stat stat-click"
                  onClick={() => openResumoDetail('pago')}
                >
                  Pago
                  <strong>{money(totals.pago)}</strong>
                </button>
                <button
                  type="button"
                  className="stat stat-click"
                  onClick={() => openResumoDetail('restante')}
                >
                  Restante
                  <strong>{money(totals.restante)}</strong>
                </button>
                <button
                  type="button"
                  className="stat stat-click"
                  onClick={() => openResumoDetail('confirmados')}
                >
                  Confirmados
                  <strong>{pessoas.confTotal}</strong>
                </button>
              </div>
              <div className="panel">
                <h2 style={{ marginTop: 0 }}>Pessoas</h2>
                <div className="summary-list">
                  <button
                    type="button"
                    className="summary-tile summary-tile-click"
                    onClick={() => openResumoDetail('confirmados')}
                  >
                    <span>Pessoas confirmadas</span>
                    <strong>{pessoas.rsvpSim}</strong>
                  </button>
                  <button
                    type="button"
                    className="summary-tile summary-tile-click"
                    onClick={() => openResumoDetail('total')}
                  >
                    <span>Total de pessoas</span>
                    <strong>{pessoas.total}</strong>
                  </button>
                  <button
                    type="button"
                    className="summary-tile summary-tile-click"
                    onClick={() => openResumoDetail('adultos')}
                  >
                    <span>Adultos</span>
                    <strong>{pessoas.adultos}</strong>
                  </button>
                  <button
                    type="button"
                    className="summary-tile summary-tile-click"
                    onClick={() => openResumoDetail('criancas')}
                  >
                    <span>Crianças</span>
                    <strong>{pessoas.criancas}</strong>
                  </button>
                  <button
                    type="button"
                    className="summary-tile summary-tile-click"
                    onClick={() => openResumoDetail('confAdultos')}
                  >
                    <span>Confirmados · adultos</span>
                    <strong>{pessoas.confAdultos}</strong>
                  </button>
                  <button
                    type="button"
                    className="summary-tile summary-tile-click"
                    onClick={() => openResumoDetail('confCriancas')}
                  >
                    <span>Confirmados · crianças</span>
                    <strong>{pessoas.confCriancas}</strong>
                  </button>
                  <button
                    type="button"
                    className="summary-tile summary-tile-click"
                    onClick={() => openResumoDetail('rsvpNao')}
                  >
                    <span>RSVP · Não</span>
                    <strong>{pessoas.rsvpNao}</strong>
                  </button>
                  <button
                    type="button"
                    className="summary-tile summary-tile-click"
                    onClick={() => openResumoDetail('rsvpTalvez')}
                  >
                    <span>RSVP · Talvez</span>
                    <strong>{pessoas.rsvpTalvez}</strong>
                  </button>
                  <button
                    type="button"
                    className="summary-tile summary-tile-click"
                    onClick={() => openResumoDetail('rsvpPend')}
                  >
                    <span>RSVP · Pendente</span>
                    <strong>{pessoas.rsvpPend}</strong>
                  </button>
                  <button
                    type="button"
                    className="summary-tile summary-tile-click"
                    onClick={() => openResumoDetail('tarefas')}
                  >
                    <span>Tarefas pendentes</span>
                    <strong>{pessoas.pendentes}</strong>
                  </button>
                  <button
                    type="button"
                    className="summary-tile summary-tile-click"
                    onClick={() => openResumoDetail('agendaHoje')}
                  >
                    <span>Compromissos hoje</span>
                    <strong>{pessoas.agendaHoje}</strong>
                  </button>
                  <button
                    type="button"
                    className="summary-tile summary-tile-click"
                    onClick={() => openResumoDetail('presentes')}
                  >
                    <span>Presentes reservados</span>
                    <strong>{pessoas.reservados}</strong>
                  </button>
                </div>
              </div>
              <div className="panel">
                <h2 style={{ marginTop: 0 }}>Padrinhos</h2>
                {(data?.padrinhos ?? []).length === 0 ? (
                  <p className="hint" style={{ textAlign: 'left' }}>
                    Nenhum padrinho vinculado ainda. Use a aba Padrinhos.
                  </p>
                ) : (
                  <div className="summary-list">
                    {(data?.padrinhos ?? []).map((p) => {
                      const conv = convidadoById.get(p.convidadoId);
                      return (
                        <div key={p.id} className="summary-tile">
                          <span>
                            {nomeComParceiro(conv)}
                            {conv?.lado ? ` · ${ladoLabel(conv.lado)}` : ''}
                            {p.papel ? ` · ${p.papel}` : ''}
                          </span>
                          <strong className="badge">
                            {p.tipo === 'madrinha' ? 'Madrinha' : 'Padrinho'}
                          </strong>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
              {resumoDetail && (
                <div
                  className="resumo-modal"
                  role="dialog"
                  aria-modal="true"
                  onClick={() => setResumoDetail(null)}
                >
                  <div
                    className="resumo-modal__panel"
                    onClick={(e) => e.stopPropagation()}
                  >
                    <div className="resumo-modal__head">
                      <h2>{resumoDetail.title}</h2>
                      <button
                        type="button"
                        className="ghost"
                        onClick={() => setResumoDetail(null)}
                      >
                        Fechar
                      </button>
                    </div>
                    <label htmlFor="resumo-filtro">Filtrar</label>
                    <select
                      id="resumo-filtro"
                      value={resumoDetail.filterKey}
                      onChange={(e) => {
                        const key = e.target.value;
                        const f = resumoFiltros[key];
                        if (f) setResumoDetail({ title: f.label, filterKey: key });
                      }}
                    >
                      {Object.entries(resumoFiltros).map(([key, f]) => (
                        <option key={key} value={key}>
                          {f.label} ({f.items.length})
                        </option>
                      ))}
                    </select>
                    <p className="hint" style={{ textAlign: 'left' }}>
                      {(resumoFiltros[resumoDetail.filterKey]?.items.length ??
                        0) === 0
                        ? 'Nenhum item nesta seleção.'
                        : `${resumoFiltros[resumoDetail.filterKey].items.length} item(ns)`}
                    </p>
                    <div className="resumo-nome-grid">
                      {(resumoFiltros[resumoDetail.filterKey]?.items ?? []).map(
                        (item, i) => (
                          <div key={`${item.nome}-${i}`} className="resumo-nome-card">
                            <strong>{item.nome}</strong>
                            {item.meta ? <span>{item.meta}</span> : null}
                          </div>
                        ),
                      )}
                    </div>
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      )}

      {tab === 'gastos' && (
        <div className="list">
          {gestao && (
            <form className="panel" onSubmit={onSaveGasto}>
              <h2 style={{ marginTop: 0 }}>
                {gastoId ? 'Editar gasto' : 'Novo gasto'}
              </h2>
              <label>Descrição</label>
              <input
                value={gastoDesc}
                onChange={(e) => setGastoDesc(e.target.value)}
                required
              />
              <label>Categoria</label>
              <input
                value={gastoCat}
                onChange={(e) => setGastoCat(e.target.value)}
                required
              />
              <label>Valor previsto</label>
              <input
                type="number"
                step="0.01"
                value={gastoValor}
                onChange={(e) => setGastoValor(e.target.value)}
                required
              />
              <label>Status</label>
              <select
                value={gastoStatus}
                onChange={(e) => setGastoStatus(e.target.value)}
              >
                <option value="pendente">Pendente</option>
                <option value="pago">Pago</option>
                <option value="cancelado">Cancelado</option>
              </select>
              <div className="row">
                <button className="primary" disabled={busy}>
                  {gastoId ? 'Salvar alterações' : 'Cadastrar gasto'}
                </button>
                {gastoId && (
                  <button
                    type="button"
                    className="ghost"
                    disabled={busy}
                    onClick={resetGasto}
                  >
                    Cancelar
                  </button>
                )}
              </div>
            </form>
          )}
          {(data?.gastos ?? []).map((g) => (
            <div key={g.id} className="item">
              <h3>{g.descricao}</h3>
              <p>
                {g.categoria} · {money(Number(g.valorPrevisto))} ·{' '}
                <span className="badge">{g.status}</span>
              </p>
              {gestao && (
                <div className="row">
                  <button
                    className="ghost"
                    disabled={busy}
                    onClick={() => editGasto(g)}
                  >
                    Editar
                  </button>
                  <button
                    className="ghost"
                    style={{ color: '#b84a4a' }}
                    disabled={busy}
                    onClick={() =>
                      run(() => deleteGasto(token!, g.id), 'Gasto excluído')
                    }
                  >
                    Excluir
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {tab === 'tarefas' && (
        <div className="list">
          {gestao && (
            <form className="panel" onSubmit={onSaveTarefa}>
              <h2 style={{ marginTop: 0 }}>
                {tarefaId ? 'Editar tarefa' : 'Nova tarefa'}
              </h2>
              <label>Título</label>
              <input
                value={tarefaTitulo}
                onChange={(e) => setTarefaTitulo(e.target.value)}
                required
              />
              <label>Descrição</label>
              <input
                value={tarefaDesc}
                onChange={(e) => setTarefaDesc(e.target.value)}
              />
              <label>Status</label>
              <select
                value={tarefaStatus}
                onChange={(e) => setTarefaStatus(e.target.value)}
              >
                <option value="pendente">Pendente</option>
                <option value="em_andamento">Em andamento</option>
                <option value="feito">Feito</option>
              </select>
              <div className="row">
                <button className="primary" disabled={busy}>
                  {tarefaId ? 'Salvar alterações' : 'Cadastrar tarefa'}
                </button>
                {tarefaId && (
                  <button
                    type="button"
                    className="ghost"
                    disabled={busy}
                    onClick={resetTarefa}
                  >
                    Cancelar
                  </button>
                )}
              </div>
            </form>
          )}
          {(data?.tarefas ?? []).map((t) => (
            <div key={t.id} className="item">
              <h3>{t.titulo}</h3>
              <p>
                {t.descricao || '—'} · <span className="badge">{t.status}</span>
              </p>
              {gestao && (
                <div className="row">
                  <button
                    className="ghost"
                    disabled={busy}
                    onClick={() => editTarefa(t)}
                  >
                    Editar
                  </button>
                  <button
                    className="ghost"
                    style={{ color: '#b84a4a' }}
                    disabled={busy}
                    onClick={() =>
                      run(() => deleteTarefa(token!, t.id), 'Tarefa excluída')
                    }
                  >
                    Excluir
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {tab === 'agenda' && (
        <div className="list">
          {gestao && (
            <form className="panel" onSubmit={onSaveAgenda}>
              <h2 style={{ marginTop: 0 }}>
                {agendaId ? 'Editar compromisso' : 'Novo compromisso'}
              </h2>
              <label>Título</label>
              <input
                value={agendaTitulo}
                onChange={(e) => setAgendaTitulo(e.target.value)}
                required
              />
              <label>Data e hora</label>
              <input
                type="datetime-local"
                value={agendaInicio}
                onChange={(e) => setAgendaInicio(e.target.value)}
                required
              />
              <label>Local</label>
              <input
                value={agendaLocal}
                onChange={(e) => setAgendaLocal(e.target.value)}
              />
              <div className="row">
                <button className="primary" disabled={busy}>
                  {agendaId ? 'Salvar alterações' : 'Cadastrar compromisso'}
                </button>
                {agendaId && (
                  <button
                    type="button"
                    className="ghost"
                    disabled={busy}
                    onClick={resetAgenda}
                  >
                    Cancelar
                  </button>
                )}
              </div>
            </form>
          )}
          {(data?.compromissos ?? []).map((c) => (
            <div key={c.id} className="item">
              <h3>{c.titulo}</h3>
              <p>
                {fmtDate(c.inicio)} · {c.local || 'Sem local'}
              </p>
              {gestao && (
                <div className="row">
                  <button
                    className="ghost"
                    disabled={busy}
                    onClick={() => editAgenda(c)}
                  >
                    Editar
                  </button>
                  <button
                    className="ghost"
                    style={{ color: '#b84a4a' }}
                    disabled={busy}
                    onClick={() =>
                      run(
                        () => deleteCompromisso(token!, c.id),
                        'Compromisso excluído',
                      )
                    }
                  >
                    Excluir
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {tab === 'convidados' && (
        <div className="list">
          {gestao && (
            <div className="panel">
              <h2 style={{ marginTop: 0 }}>Quantidades</h2>
              <p style={{ margin: '0 0 8px', fontWeight: 700 }}>
                Total {pessoas.total} · Adultos {pessoas.adultos} · Crianças{' '}
                {pessoas.criancas}
              </p>
              <p style={{ margin: 0, color: 'var(--muted)' }}>
                Confirmados: {pessoas.confTotal} ({pessoas.confAdultos} adultos /{' '}
                {pessoas.confCriancas} crianças)
              </p>
              <p style={{ margin: '6px 0 0', color: 'var(--muted)' }}>
                RSVP · Sim {pessoas.rsvpSim} · Não {pessoas.rsvpNao} · Talvez{' '}
                {pessoas.rsvpTalvez} · Pendente {pessoas.rsvpPend}
              </p>
            </div>
          )}
          {gestao && (
            <form className="panel" onSubmit={onSaveConvidado}>
              <h2 style={{ marginTop: 0 }}>
                {convId ? 'Editar convidado' : 'Novo convidado'}
              </h2>
              <label>Nome</label>
              <input
                value={convNome}
                onChange={(e) => setConvNome(e.target.value)}
                required
              />
              <label>Telefone</label>
              <input
                value={convTelefone}
                onChange={(e) => setConvTelefone(e.target.value)}
              />
              <label>E-mail</label>
              <input
                type="email"
                value={convEmail}
                onChange={(e) => setConvEmail(e.target.value)}
              />
              <label>Mesa</label>
              <input
                value={convMesa}
                onChange={(e) => setConvMesa(e.target.value)}
              />
              <label>Lado</label>
              <select
                value={convLado}
                onChange={(e) =>
                  setConvLado(e.target.value as 'noivo' | 'noiva' | 'ambos')
                }
              >
                <option value="noivo">Noivo</option>
                <option value="noiva">Noiva</option>
                <option value="ambos">Ambos</option>
              </select>
              <label>
                <input
                  type="checkbox"
                  checked={convEhCrianca}
                  onChange={(e) => setConvEhCrianca(e.target.checked)}
                />{' '}
                É criança
              </label>
              <label>RSVP</label>
              <select
                value={convRsvp}
                onChange={(e) =>
                  setConvRsvp(
                    e.target.value as 'pendente' | 'sim' | 'nao' | 'talvez',
                  )
                }
              >
                <option value="pendente">Pendente</option>
                <option value="sim">Sim</option>
                <option value="nao">Não</option>
                <option value="talvez">Talvez</option>
              </select>

              <h3>Acompanhantes</h3>
              {convAcomps.map((a, idx) => (
                <div key={idx} className="row" style={{ alignItems: 'end' }}>
                  <div style={{ flex: 1 }}>
                    <label>Nome</label>
                    <input
                      value={a.nome}
                      onChange={(e) => {
                        const next = [...convAcomps];
                        next[idx] = { ...next[idx], nome: e.target.value };
                        setConvAcomps(next);
                      }}
                    />
                  </div>
                  <div style={{ flex: 1 }}>
                    <label>Tipo</label>
                    <select
                      value={a.tipo}
                      onChange={(e) => {
                        const next = [...convAcomps];
                        next[idx] = {
                          ...next[idx],
                          tipo: e.target.value as Acompanhante['tipo'],
                        };
                        setConvAcomps(next);
                      }}
                    >
                      <option value="esposa">Esposa</option>
                      <option value="esposo">Esposo</option>
                      <option value="namorada">Namorada</option>
                      <option value="namorado">Namorado</option>
                      <option value="amigo">Amigo(a)</option>
                      <option value="filho_adulto">Filho(a)</option>
                      <option value="filho">Filho(a) criança</option>
                    </select>
                  </div>
                  <div>
                    <label>RSVP</label>
                    <select
                      value={a.rsvp || 'pendente'}
                      onChange={(e) => {
                        const next = [...convAcomps];
                        next[idx] = {
                          ...next[idx],
                          rsvp: e.target.value as Acompanhante['rsvp'],
                        };
                        setConvAcomps(next);
                      }}
                    >
                      <option value="pendente">Pendente</option>
                      <option value="sim">Sim</option>
                      <option value="nao">Não</option>
                      <option value="talvez">Talvez</option>
                    </select>
                  </div>
                  <button
                    type="button"
                    className="ghost"
                    style={{ color: '#b84a4a' }}
                    onClick={() =>
                      setConvAcomps(convAcomps.filter((_, i) => i !== idx))
                    }
                  >
                    Remover
                  </button>
                </div>
              ))}
              <button
                type="button"
                className="ghost"
                onClick={() => setConvAcomps([...convAcomps, { ...emptyAcomp }])}
              >
                Adicionar acompanhante
              </button>

              {convId && (
                <div style={{ marginTop: 12 }}>
                  {convToken && (
                    <>
                      <p className="hint" style={{ textAlign: 'left' }}>
                        Link de acesso:
                      </p>
                      <p className="hint" style={{ textAlign: 'left', wordBreak: 'break-all' }}>
                        {conviteLink(convToken)}
                      </p>
                    </>
                  )}
                  <div className="row">
                    {convToken && (
                      <button
                        type="button"
                        className="ghost"
                        disabled={busy}
                        onClick={() => copyConvite(convToken)}
                      >
                        Copiar link
                      </button>
                    )}
                    {convId && (
                      <button
                        type="button"
                        className="ghost"
                        disabled={busy}
                        onClick={() =>
                          onEnviarWhatsAppConvidado(convId, {
                            token: convToken,
                            nome: convNome,
                            telefone: convTelefone,
                          })
                        }
                      >
                        Enviar convite WhatsApp
                      </button>
                    )}
                    <button
                      type="button"
                      className="ghost"
                      disabled={busy}
                      onClick={onRegenerarToken}
                    >
                      Gerar novo link
                    </button>
                  </div>
                </div>
              )}

              <div className="row" style={{ marginTop: 12 }}>
                <button className="primary" disabled={busy}>
                  {convId ? 'Salvar alterações' : 'Cadastrar convidado'}
                </button>
                {convId && (
                  <button
                    type="button"
                    className="ghost"
                    disabled={busy}
                    onClick={resetConvidado}
                  >
                    Cancelar
                  </button>
                )}
              </div>
            </form>
          )}
          {(data?.convidados ?? []).map((c) => (
            <div key={c.id} className="item">
              <h3>
                {c.nome}
                {c.ehCrianca ? ' · criança' : ''}
              </h3>
              <p>
                RSVP <span className="badge">{c.rsvp}</span> · lado {c.lado}
                {c.mesa ? ` · mesa ${c.mesa}` : ''}
                {c.telefone ? ` · ${c.telefone}` : ''}
                {c.email ? ` · ${c.email}` : ''}
              </p>
              {Array.isArray(c.acompanhantesLista) &&
                c.acompanhantesLista.length > 0 && (
                  <p>
                    Acomps:{' '}
                    {c.acompanhantesLista
                      .map((a: any) => {
                        const tipo = normalizeAcompTipo(a.tipo);
                        return `${a.nome} (${ACOMP_TIPO_LABEL[tipo]}${
                          a.rsvp ? ` · ${rsvpLabel(a.rsvp)}` : ''
                        })`;
                      })
                      .join(', ')}
                  </p>
                )}
              {gestao && (
                <>
                  <p className="hint" style={{ textAlign: 'left', wordBreak: 'break-all' }}>
                    Link de acesso:{' '}
                    {c.token ? (
                      <a href={conviteLink(c.token)} target="_blank" rel="noreferrer">
                        {conviteLink(c.token)}
                      </a>
                    ) : (
                      <span>ainda não gerado</span>
                    )}
                  </p>
                  <div className="row">
                    <button
                      className="ghost"
                      disabled={busy}
                      onClick={() => editConvidado(c)}
                    >
                      Editar
                    </button>
                    <button
                      className="ghost"
                      disabled={busy}
                      onClick={() => onCopiarLinkConvidado(c.id, c.token)}
                    >
                      Copiar link
                    </button>
                    <button
                      className="ghost"
                      disabled={busy}
                      onClick={() =>
                        onEnviarWhatsAppConvidado(c.id, {
                          token: c.token,
                          nome: c.nome,
                          telefone: c.telefone,
                        })
                      }
                    >
                      Enviar convite WhatsApp
                    </button>
                    <button
                      className="ghost"
                      style={{ color: '#b84a4a' }}
                      disabled={busy}
                      onClick={() =>
                        run(
                          () => deleteConvidado(token!, c.id),
                          'Convidado excluído',
                        )
                      }
                    >
                      Excluir
                    </button>
                  </div>
                </>
              )}
            </div>
          ))}
        </div>
      )}

      {tab === 'padrinhos' && (
        <div className="list">
          {gestao && (
            <form className="panel" onSubmit={onVincularPadrinho}>
              <h2 style={{ marginTop: 0 }}>Vincular padrinho</h2>
              <p style={{ color: 'var(--muted)', marginTop: 0 }}>
                Escolha um convidado já cadastrado para ser padrinho ou
                madrinha.
              </p>
              <label>Convidado</label>
              <select
                value={padConvidadoId}
                onChange={(e) => setPadConvidadoId(e.target.value)}
                required
              >
                <option value="">Selecione…</option>
                {convidadosDisponiveis.map((c) => (
                  <option key={c.id} value={c.id}>
                    {nomeComParceiro(c)} · {ladoLabel(c.lado)}
                  </option>
                ))}
              </select>
              {padConvidadoId &&
                (() => {
                  const c = convidadosDisponiveis.find(
                    (x) => x.id === padConvidadoId,
                  );
                  const parceiro = c ? parceiroDe(c) : null;
                  if (!c) return null;
                  return (
                    <p className="hint" style={{ textAlign: 'left' }}>
                      Lado: {ladoLabel(c.lado)}
                      {parceiro
                        ? ` · ${ACOMP_TIPO_LABEL[parceiro.tipo]}: ${parceiro.nome}`
                        : ''}
                    </p>
                  );
                })()}
              {convidadosDisponiveis.length === 0 && (
                <p className="hint" style={{ textAlign: 'left' }}>
                  Todos os convidados já estão vinculados, ou ainda não há
                  convidados cadastrados.
                </p>
              )}
              <label>Tipo</label>
              <select
                value={padTipo}
                onChange={(e) =>
                  setPadTipo(e.target.value as 'padrinho' | 'madrinha')
                }
              >
                <option value="padrinho">Padrinho</option>
                <option value="madrinha">Madrinha</option>
              </select>
              <label>Papel (ex.: alianças)</label>
              <input
                value={padPapel}
                onChange={(e) => setPadPapel(e.target.value)}
                placeholder="Ex.: testemunha"
              />
              <button className="primary" disabled={busy || !padConvidadoId}>
                Vincular
              </button>
            </form>
          )}
          {(data?.padrinhos ?? []).length === 0 ? (
            <p className="hint">Nenhum padrinho vinculado ainda.</p>
          ) : (
            (data?.padrinhos ?? []).map((p) => {
              const conv = convidadoById.get(p.convidadoId);
              const parceiro = conv ? parceiroDe(conv) : null;
              return (
                <div key={p.id} className="item">
                  <h3>{nomeComParceiro(conv)}</h3>
                  <p>
                    <span className="badge">
                      {p.tipo === 'madrinha' ? 'Madrinha' : 'Padrinho'}
                    </span>
                    {conv?.lado ? ` · Lado ${ladoLabel(conv.lado)}` : ''}
                    {parceiro
                      ? ` · ${ACOMP_TIPO_LABEL[parceiro.tipo]}: ${parceiro.nome}`
                      : ''}
                    {p.papel ? ` · ${p.papel}` : ''}
                    {conv?.telefone ? ` · ${conv.telefone}` : ''}
                  </p>
                  {gestao && (
                    <div className="row">
                      <button
                        className="ghost"
                        style={{ color: '#b84a4a' }}
                        disabled={busy}
                        onClick={() =>
                          run(
                            () => deletePadrinho(token!, p.id),
                            'Padrinho desvinculado',
                          )
                        }
                      >
                        Desvincular
                      </button>
                    </div>
                  )}
                </div>
              );
            })
          )}
        </div>
      )}

      {tab === 'presentes' && (
        <div className="list">
          {gestao && (
            <form className="panel" onSubmit={onSavePresente}>
              <h2 style={{ marginTop: 0 }}>
                {presenteId ? 'Editar presente' : 'Novo presente'}
              </h2>
              <label>Nome</label>
              <input
                value={presenteNome}
                onChange={(e) => setPresenteNome(e.target.value)}
                required
              />
              <label>Valor estimado</label>
              <input
                type="number"
                step="0.01"
                value={presenteValor}
                onChange={(e) => setPresenteValor(e.target.value)}
              />
              <label>Para</label>
              <select
                value={presenteAudiencia}
                onChange={(e) =>
                  setPresenteAudiencia(
                    e.target.value as 'convidados' | 'padrinhos',
                  )
                }
              >
                <option value="convidados">Convidados</option>
                <option value="padrinhos">Padrinhos</option>
              </select>
              <label>Foto ilustrativa</label>
              <input
                type="file"
                accept="image/*"
                onChange={(e) => onPresenteImagem(e.target.files)}
              />
              {presenteImagemPreview && (
                <div className="presente-form-preview">
                  <img
                    src={presenteImagemPreview}
                    alt="Prévia do presente"
                  />
                  <button
                    type="button"
                    className="ghost"
                    disabled={busy}
                    onClick={limparPresenteImagem}
                  >
                    Remover foto
                  </button>
                </div>
              )}
              <div className="row">
                <button className="primary" disabled={busy}>
                  {presenteId ? 'Salvar alterações' : 'Cadastrar presente'}
                </button>
                {presenteId && (
                  <button
                    type="button"
                    className="ghost"
                    disabled={busy}
                    onClick={resetPresente}
                  >
                    Cancelar
                  </button>
                )}
              </div>
            </form>
          )}
          {gestao && (
            <div className="row" style={{ marginBottom: 8 }}>
              <label style={{ margin: 0 }}>Filtrar</label>
              <select
                value={presenteFiltro}
                onChange={(e) =>
                  setPresenteFiltro(
                    e.target.value as 'todos' | 'convidados' | 'padrinhos',
                  )
                }
              >
                <option value="todos">Todos</option>
                <option value="convidados">Convidados</option>
                <option value="padrinhos">Padrinhos</option>
              </select>
            </div>
          )}
          {!gestao && (
            <p className="hint" style={{ textAlign: 'left' }}>
              {role === 'padrinho'
                ? 'Lista de compras dos padrinhos'
                : 'Lista de presentes dos convidados'}
            </p>
          )}
          {(data?.presentes ?? [])
            .filter((p) => {
              if (!gestao) return true;
              if (presenteFiltro === 'todos') return true;
              return (p.audiencia ?? 'convidados') === presenteFiltro;
            })
            .map((p) => {
            const reservadoPor = p.reservadoPorConvidadoId
              ? convidadoById.get(p.reservadoPorConvidadoId)
              : null;
            let statusLabel = 'Disponível';
            if (p.reservadoPorConvidadoId) {
              if (gestao) {
                statusLabel = reservadoPor?.nome
                  ? `Reservado por ${reservadoPor.nome}`
                  : 'Reservado';
              } else if (p.reservadoPorConvidadoId === user?.convidadoId) {
                statusLabel = 'Você reservou';
              } else {
                statusLabel = 'Reservado';
              }
            }
            const audienciaLabel =
              p.audiencia === 'padrinhos' ? 'Padrinhos' : 'Convidados';
            return (
              <div key={p.id} className="item presente-item">
                {p.imagemUrl ? (
                  <img
                    className="presente-thumb"
                    src={p.imagemUrl}
                    alt={p.nome}
                  />
                ) : null}
                <div className="presente-item__body">
                  <h3>
                    {p.nome}
                    {gestao ? (
                      <>
                        {' '}
                        <span className="badge">{audienciaLabel}</span>
                      </>
                    ) : null}
                  </h3>
                  <p>
                    {p.valorEstimado != null
                      ? money(Number(p.valorEstimado))
                      : 'Sem valor'}{' '}
                    · {statusLabel}
                  </p>
                  {gestao && (
                    <div className="row">
                      <button
                        className="ghost"
                        disabled={busy}
                        onClick={() => editPresente(p)}
                      >
                        Editar
                      </button>
                      <button
                        className="ghost"
                        style={{ color: '#b84a4a' }}
                        disabled={busy}
                        onClick={() =>
                          run(
                            () => deletePresente(token!, p.id),
                            'Presente excluído',
                          )
                        }
                      >
                        Excluir
                      </button>
                    </div>
                  )}
                  {!gestao && !p.reservadoPorConvidadoId && (
                    <div className="row">
                      <button
                        className="ghost"
                        disabled={busy}
                        onClick={() => onReservar(p.id)}
                      >
                        Reservar
                      </button>
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {tab === 'tokens' && gestao && (
        <div className="list">
          <form className="panel" onSubmit={onCriarCerimonialista}>
            <h2 style={{ marginTop: 0 }}>Acesso do cerimonialista</h2>
            <p style={{ color: 'var(--muted)', marginTop: 0 }}>
              Gera um link para o cerimonialista entrar no site.
            </p>
            <label>Nome</label>
            <input
              value={cerimNome}
              onChange={(e) => setCerimNome(e.target.value)}
              required
              placeholder="Nome do cerimonialista"
            />
            <button className="primary" disabled={busy}>
              Gerar link
            </button>
          </form>
          {(data?.convites ?? []).map((c) => (
            <div key={c.id} className="item">
              <h3>{c.nome}</h3>
              <p>
                <span className="badge">
                  {c.role === 'cerimonialista'
                    ? 'Cerimonialista'
                    : c.role === 'padrinho'
                      ? 'Padrinho'
                      : 'Convidado'}
                </span>
                {c.ativo ? ' · ativo' : ' · inativo'}
              </p>
              <p className="hint" style={{ wordBreak: 'break-all' }}>
                {conviteLink(c.token)}
              </p>
              <button
                type="button"
                className="ghost"
                onClick={() => copyConvite(c.token)}
              >
                Copiar link
              </button>
            </div>
          ))}
        </div>
      )}

      {tab === 'fotos' && (
        <div className="list">
          {gestao && (
            <form className="panel" onSubmit={onSaveFoto}>
              <h2 style={{ marginTop: 0 }}>Novas fotos</h2>
              <label>Arquivos (pode escolher várias)</label>
              <input
                type="file"
                accept="image/*"
                multiple
                onChange={(e) => onFotoFiles(e.target.files)}
              />
              {fotoPreviews.length > 0 && (
                <div className="foto-preview-grid">
                  {fotoPreviews.map((src, i) => (
                    <img
                      key={src}
                      src={src}
                      alt={`Prévia ${i + 1}`}
                      className="foto-preview"
                    />
                  ))}
                </div>
              )}
              <p className="hint" style={{ textAlign: 'left', marginTop: 0 }}>
                {fotoArquivos.length
                  ? `${fotoArquivos.length} foto(s) selecionada(s)`
                  : 'Selecione uma ou várias imagens.'}
              </p>
              <label>Tipo</label>
              <select
                value={fotoTipo}
                onChange={(e) =>
                  setFotoTipo(e.target.value as 'noivos' | 'evento' | 'outro')
                }
              >
                <option value="noivos">Noivos</option>
                <option value="evento">Evento</option>
                <option value="outro">Outro</option>
              </select>
              <label>Legenda</label>
              <input
                value={fotoLegenda}
                onChange={(e) => setFotoLegenda(e.target.value)}
              />
              <label className="checks">
                <input
                  type="checkbox"
                  checked={fotoPublico}
                  onChange={(e) => setFotoPublico(e.target.checked)}
                />
                Públicas (visíveis para convidados)
              </label>
              <button className="primary" disabled={busy || !fotoArquivos.length}>
                {busy
                  ? 'Enviando…'
                  : fotoArquivos.length > 1
                    ? `Enviar ${fotoArquivos.length} fotos`
                    : 'Enviar foto'}
              </button>
            </form>
          )}

          {(data?.fotos ?? []).length === 0 ? (
            <p className="hint">Nenhuma foto ainda.</p>
          ) : (
            <div className="foto-grid">
              {(data?.fotos ?? []).map((f) => (
                <div key={f.id} className="foto-item">
                  <button
                    type="button"
                    className="foto-thumb"
                    onClick={() => setFotoAberta(f.url)}
                  >
                    <img src={f.url} alt={f.legenda || f.tipo} />
                  </button>
                  {(f.legenda || gestao) && (
                    <p>
                      {f.legenda || f.tipo}
                      {gestao ? (f.publico ? ' · Pública' : ' · Privada') : ''}
                    </p>
                  )}
                  {gestao && (
                    <div className="row">
                      <button
                        type="button"
                        className="ghost"
                        disabled={busy}
                        onClick={() =>
                          run(
                            () =>
                              atualizarFoto(token!, {
                                id: f.id,
                                tipo: f.tipo,
                                legenda: f.legenda,
                                publico: !f.publico,
                              }),
                            f.publico
                              ? 'Foto agora é privada'
                              : 'Foto agora é pública',
                          )
                        }
                      >
                        {f.publico ? 'Tornar privada' : 'Tornar pública'}
                      </button>
                      <button
                        type="button"
                        className="danger"
                        disabled={busy}
                        onClick={() =>
                          run(() => deleteFoto(token!, f.id), 'Foto excluída')
                        }
                      >
                        Excluir
                      </button>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}

          {fotoAberta && (
            <FotoLightbox
              src={fotoAberta}
              onClose={() => setFotoAberta(null)}
            />
          )}
        </div>
      )}

      {tab === 'evento' && (
        <div className="list">
          <EventoLocais cfg={cfg} />
          {gestao ? (
            <>
              <form className="panel" onSubmit={onSaveEvento}>
                <h2 style={{ marginTop: 0 }}>Dados do casamento</h2>
                <label>Nome do noivo</label>
                <input
                  value={evtNomeNoivo}
                  onChange={(e) => setEvtNomeNoivo(e.target.value)}
                  required
                />
                <label>Nome da noiva</label>
                <input
                  value={evtNomeNoiva}
                  onChange={(e) => setEvtNomeNoiva(e.target.value)}
                  required
                />
                <label>Data e hora da cerimônia</label>
                <input
                  type="datetime-local"
                  value={evtData}
                  onChange={(e) => setEvtData(e.target.value)}
                />
                <label>Local da cerimônia</label>
                <input
                  value={evtLocalCerim}
                  onChange={(e) => setEvtLocalCerim(e.target.value)}
                />
                <label>Endereço da cerimônia</label>
                <input
                  value={evtEndCerim}
                  onChange={(e) => setEvtEndCerim(e.target.value)}
                />
                <label>Local da festa</label>
                <input
                  value={evtLocalFesta}
                  onChange={(e) => setEvtLocalFesta(e.target.value)}
                />
                <label>Endereço da festa</label>
                <input
                  value={evtEndFesta}
                  onChange={(e) => setEvtEndFesta(e.target.value)}
                />
                <label>WhatsApp</label>
                <input
                  value={evtWhatsapp}
                  onChange={(e) => setEvtWhatsapp(e.target.value)}
                  placeholder="5511999999999"
                />
                <label>Mensagem de boas-vindas</label>
                <textarea
                  value={evtMsg}
                  onChange={(e) => setEvtMsg(e.target.value)}
                  rows={3}
                />
                <button className="primary" disabled={busy}>
                  Salvar evento
                </button>
              </form>

              <form className="panel" onSubmit={onSaveCardapio}>
                <h2 style={{ marginTop: 0 }}>
                  {cardId ? 'Editar cardápio' : 'Novo item do cardápio'}
                </h2>
                <label>Título</label>
                <input
                  value={cardTitulo}
                  onChange={(e) => setCardTitulo(e.target.value)}
                  required
                />
                <label>Descrição</label>
                <input
                  value={cardDesc}
                  onChange={(e) => setCardDesc(e.target.value)}
                />
                <label>Ordem</label>
                <input
                  type="number"
                  value={cardOrdem}
                  onChange={(e) => setCardOrdem(e.target.value)}
                />
                <div className="row">
                  <button className="primary" disabled={busy}>
                    {cardId ? 'Salvar alterações' : 'Cadastrar item'}
                  </button>
                  {cardId && (
                    <button
                      type="button"
                      className="ghost"
                      disabled={busy}
                      onClick={resetCardapio}
                    >
                      Cancelar
                    </button>
                  )}
                </div>
              </form>
              {(data?.cardapio ?? []).map((i) => (
                <div key={i.id} className="item">
                  <h3>
                    {i.titulo}
                    <span className="badge">#{i.ordem}</span>
                  </h3>
                  <p>{i.descricao || '—'}</p>
                  <div className="row">
                    <button
                      type="button"
                      className="ghost"
                      disabled={busy}
                      onClick={() => {
                        setCardId(i.id);
                        setCardTitulo(i.titulo ?? '');
                        setCardDesc(i.descricao ?? '');
                        setCardOrdem(String(i.ordem ?? 0));
                      }}
                    >
                      Editar
                    </button>
                    <button
                      type="button"
                      className="danger"
                      disabled={busy}
                      onClick={() =>
                        run(
                          () => deleteCardapio(token!, i.id),
                          'Item removido',
                        )
                      }
                    >
                      Excluir
                    </button>
                  </div>
                </div>
              ))}

              <form className="panel" onSubmit={onSaveAtracao}>
                <h2 style={{ marginTop: 0 }}>
                  {atrId ? 'Editar atração' : 'Nova atração'}
                </h2>
                <label>Título</label>
                <input
                  value={atrTitulo}
                  onChange={(e) => setAtrTitulo(e.target.value)}
                  required
                />
                <label>Descrição</label>
                <input
                  value={atrDesc}
                  onChange={(e) => setAtrDesc(e.target.value)}
                />
                <label>Horário</label>
                <input
                  value={atrHorario}
                  onChange={(e) => setAtrHorario(e.target.value)}
                  placeholder="20:00"
                />
                <label>Ordem</label>
                <input
                  type="number"
                  value={atrOrdem}
                  onChange={(e) => setAtrOrdem(e.target.value)}
                />
                <div className="row">
                  <button className="primary" disabled={busy}>
                    {atrId ? 'Salvar alterações' : 'Cadastrar atração'}
                  </button>
                  {atrId && (
                    <button
                      type="button"
                      className="ghost"
                      disabled={busy}
                      onClick={resetAtracao}
                    >
                      Cancelar
                    </button>
                  )}
                </div>
              </form>
              {(data?.atracoes ?? []).map((i) => (
                <div key={i.id} className="item">
                  <h3>
                    {i.horario || '—'} · {i.titulo}
                  </h3>
                  <p>{i.descricao || '—'}</p>
                  <div className="row">
                    <button
                      type="button"
                      className="ghost"
                      disabled={busy}
                      onClick={() => {
                        setAtrId(i.id);
                        setAtrTitulo(i.titulo ?? '');
                        setAtrDesc(i.descricao ?? '');
                        setAtrHorario(i.horario ?? '');
                        setAtrOrdem(String(i.ordem ?? 0));
                      }}
                    >
                      Editar
                    </button>
                    <button
                      type="button"
                      className="danger"
                      disabled={busy}
                      onClick={() =>
                        run(
                          () => deleteAtracao(token!, i.id),
                          'Atração removida',
                        )
                      }
                    >
                      Excluir
                    </button>
                  </div>
                </div>
              ))}
            </>
          ) : (
            <>
              {(data?.cardapio ?? []).length > 0 && (
                <div className="item">
                  <h3>Cardápio</h3>
                  {(data?.cardapio ?? []).map((i) => (
                    <p key={i.id}>
                      <strong>{i.titulo}</strong> — {i.descricao}
                    </p>
                  ))}
                </div>
              )}
              {(data?.atracoes ?? []).length > 0 && (
                <div className="item">
                  <h3>Atrações</h3>
                  {(data?.atracoes ?? []).map((i) => (
                    <p key={i.id}>
                      <strong>{i.horario || '—'}</strong> · {i.titulo}
                    </p>
                  ))}
                </div>
              )}
            </>
          )}
        </div>
      )}

      {tab === 'despedida' && (
        <div className="list">
          <form className="panel" onSubmit={onSaveDespedida}>
            <h2 style={{ marginTop: 0 }}>Evento da despedida</h2>
            <label>Tipo</label>
            <select
              value={despTipo}
              onChange={(e) => setDespTipo(e.target.value as TipoDespedida)}
            >
              <option value="solteira">Despedida da noiva</option>
              <option value="solteiro">Despedida do noivo</option>
            </select>
            <label>Data</label>
            <input
              type="date"
              value={despData}
              onChange={(e) => setDespData(e.target.value)}
            />
            <label>Local</label>
            <input
              value={despLocal}
              onChange={(e) => setDespLocal(e.target.value)}
            />
            <label>Endereço</label>
            <input
              value={despEndereco}
              onChange={(e) => setDespEndereco(e.target.value)}
            />
            <label>Observações</label>
            <textarea
              value={despObs}
              onChange={(e) => setDespObs(e.target.value)}
              rows={3}
            />
            <button className="primary" disabled={busy}>
              Salvar despedida
            </button>
          </form>

          {(data?.despedidas ?? []).map((d) => (
            <div key={d.tipo} className="item">
              <h3>
                {d.tipo === 'solteira'
                  ? 'Despedida da noiva'
                  : 'Despedida do noivo'}
              </h3>
              <p>
                {fmtDate(d.data)} · {d.local || '—'}
                <br />
                {d.endereco}
              </p>
              <button
                type="button"
                className="ghost"
                onClick={() => setDespTipo(d.tipo)}
              >
                Editar neste formulário
              </button>
            </div>
          ))}

          <form className="panel" onSubmit={onSaveParticipante}>
            <h2 style={{ marginTop: 0 }}>
              {partId ? 'Editar participante' : 'Novo participante'}
            </h2>
            <label>Despedida</label>
            <select
              value={partTipo}
              onChange={(e) => {
                setPartTipo(e.target.value as TipoDespedida);
                if (!partId) setPartConvidadoId('');
              }}
            >
              <option value="solteira">Noiva</option>
              <option value="solteiro">Noivo</option>
            </select>
            <label>Convidado</label>
            <select
              value={partConvidadoId}
              onChange={(e) => setPartConvidadoId(e.target.value)}
              required
            >
              <option value="">Selecione um convidado…</option>
              {convidadosDespedida.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.nome}
                  {c.telefone ? ` · ${c.telefone}` : ''}
                </option>
              ))}
            </select>
            {convidadosDespedida.length === 0 && (
              <p className="hint">
                Nenhum convidado disponível. Cadastre em Convidados ou todos já
                estão nesta despedida.
              </p>
            )}
            <label>
              <input
                type="checkbox"
                checked={partConf}
                onChange={(e) => setPartConf(e.target.checked)}
              />{' '}
              Confirmado
            </label>
            <label>Observações</label>
            <input
              value={partObs}
              onChange={(e) => setPartObs(e.target.value)}
            />
            <div className="row">
              <button
                className="primary"
                disabled={busy || !partConvidadoId}
              >
                {partId ? 'Salvar alterações' : 'Cadastrar participante'}
              </button>
              {partId && (
                <button
                  type="button"
                  className="ghost"
                  disabled={busy}
                  onClick={resetParticipante}
                >
                  Cancelar
                </button>
              )}
            </div>
          </form>

          {(data?.despedidaParticipantes ?? []).map((p) => {
            const conv = p.convidadoId
              ? convidadoById.get(p.convidadoId)
              : null;
            const nome = conv?.nome ?? p.nome;
            const tel = conv?.telefone ?? p.telefone;
            return (
              <div key={p.id} className="item">
                <h3>{nome}</h3>
                <p>
                  {p.tipo === 'solteira' ? 'Noiva' : 'Noivo'} ·{' '}
                  {p.confirmado ? 'Confirmado' : 'Pendente'}
                  {tel ? ` · ${tel}` : ''}
                </p>
                <div className="row">
                  <button
                    type="button"
                    className="ghost"
                    disabled={busy}
                    onClick={() => {
                      setPartId(p.id);
                      setPartConvidadoId(p.convidadoId ?? '');
                      setPartTipo(p.tipo ?? 'solteira');
                      setPartConf(!!p.confirmado);
                      setPartObs(p.observacoes ?? '');
                    }}
                  >
                    Editar
                  </button>
                  <button
                    type="button"
                    className="danger"
                    disabled={busy}
                    onClick={() =>
                      run(
                        () => deleteDespedidaParticipante(token!, p.id),
                        'Participante removido',
                      )
                    }
                  >
                    Excluir
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
