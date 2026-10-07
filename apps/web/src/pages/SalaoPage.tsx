import { useEffect, useMemo, useState, type DragEvent } from 'react';
import {
  distribuirMesas,
  salvarPlanoMesas,
  type AlocacaoMesa,
  type PlanoMesas,
} from '../api';
import { useAuth } from '../auth';
import { imprimirRelatorioLista } from '../printReport';

type Lado = 'noivo' | 'noiva' | 'ambos';
type FiltroPadrinho = 'todos' | 'sim' | 'nao';

type Pessoa = {
  chave: string;
  nome: string;
  lado: Lado;
  rsvp: string;
  familiaId: string;
  familiaNome: string;
  familiaEhPadrinho: boolean;
  padrinhoLabel: string | null;
  confirmado: boolean;
  mesa?: number;
  cadeira?: number;
};

const PARCEIRO = new Set(['esposa', 'esposo', 'namorada', 'namorado']);

function ladoDe(v: unknown): Lado {
  if (v === 'noivo' || v === 'noiva' || v === 'ambos') return v;
  return 'ambos';
}

function semAcento(s: string) {
  return s
    .normalize('NFD')
    .replace(/\p{M}/gu, '')
    .toLowerCase();
}

function combinaNome(nome: string, busca: string) {
  const q = semAcento(busca.trim());
  if (!q) return true;
  return semAcento(nome).includes(q);
}

function ladoLabel(lado: string) {
  if (lado === 'noivo') return 'Noivo';
  if (lado === 'noiva') return 'Noiva';
  return 'Ambos';
}

function rsvpLabel(v: string) {
  if (v === 'sim') return 'Sim';
  if (v === 'nao') return 'Não';
  if (v === 'talvez') return 'Talvez';
  return 'Pendente';
}

function acompanhantesDe(c: any) {
  const lista = Array.isArray(c?.acompanhantesLista)
    ? c.acompanhantesLista
    : Array.isArray(c?.acompanhantes)
      ? c.acompanhantes
      : [];
  return lista.filter((a: any) => String(a?.nome ?? '').trim());
}

function pessoasDaLista(
  convidados: any[],
  padrinhos: any[],
  alocacoes: AlocacaoMesa[],
): Pessoa[] {
  const pad = new Map<string, any>(
    padrinhos.map((p) => [String(p.convidadoId), p]),
  );
  const lugar = new Map(alocacoes.map((a) => [a.chave, a]));
  const out: Pessoa[] = [];
  for (const c of convidados) {
    const acs = acompanhantesDe(c);
    const parceiro = acs.find(
      (a: any) => PARCEIRO.has(a.tipo) && String(a.nome).trim(),
    );
    const familiaNome = parceiro
      ? `${c.nome} & ${String(parceiro.nome).trim()}`
      : String(c.nome ?? '');
    const vinculo = pad.get(String(c.id));
    const familiaEhPadrinho = Boolean(vinculo);
    const padrinhoLabel = vinculo
      ? vinculo.tipo === 'madrinha'
        ? 'Madrinha'
        : 'Padrinho'
      : null;
    const lado = ladoDe(c.lado);
    const push = (
      chave: string,
      nome: string,
      rsvp: string,
      extraLabel: string | null,
    ) => {
      const seat = lugar.get(chave);
      out.push({
        chave,
        nome,
        lado,
        rsvp: rsvp || 'pendente',
        familiaId: String(c.id),
        familiaNome,
        familiaEhPadrinho,
        padrinhoLabel: extraLabel,
        confirmado: rsvp === 'sim',
        mesa: seat?.mesa,
        cadeira: seat?.cadeira,
      });
    };
    push(
      `c:${c.id}`,
      String(c.nome ?? ''),
      String(c.rsvp ?? 'pendente'),
      padrinhoLabel,
    );
    for (const a of acs) {
      push(
        `a:${c.id}:${a.id}`,
        String(a.nome).trim(),
        String(a.rsvp ?? 'pendente'),
        null,
      );
    }
  }
  return out;
}

function metaDe(p: Pessoa) {
  const bits = [`Lado ${ladoLabel(p.lado)}`];
  if (p.padrinhoLabel) bits.push(p.padrinhoLabel);
  bits.push(`RSVP ${rsvpLabel(p.rsvp)}`);
  if (p.mesa && p.cadeira) bits.push(`Mesa ${p.mesa}, cadeira ${p.cadeira}`);
  return bits.join(' · ');
}

function moverPessoa(
  lista: AlocacaoMesa[],
  chave: string,
  destino: { mesa: number; cadeira: number } | null,
): AlocacaoMesa[] {
  const origem = lista.find((a) => a.chave === chave);
  if (
    destino &&
    origem &&
    origem.mesa === destino.mesa &&
    origem.cadeira === destino.cadeira
  ) {
    return lista;
  }
  let next = lista.filter((a) => a.chave !== chave);
  if (!destino) return next;
  const ocupante = next.find(
    (a) => a.mesa === destino.mesa && a.cadeira === destino.cadeira,
  );
  if (ocupante) {
    next = next.filter((a) => a.chave !== ocupante.chave);
    if (origem) {
      next.push({
        chave: ocupante.chave,
        mesa: origem.mesa,
        cadeira: origem.cadeira,
      });
    }
  }
  next.push({ chave, mesa: destino.mesa, cadeira: destino.cadeira });
  return next;
}

function planoVazio(): PlanoMesas {
  return {
    id: null,
    mesas: 0,
    cadeirasPorMesa: 0,
    alocacoes: [],
    ladoMesas: [],
  };
}

export default function SalaoPage({
  convidados,
  padrinhos,
  plano,
}: {
  convidados: any[];
  padrinhos: any[];
  plano?: PlanoMesas | null;
}) {
  const { token, refresh } = useAuth();
  const base = plano ?? planoVazio();
  const planoKey = JSON.stringify(base);
  const [aba, setAba] = useState<'lista' | 'mesas'>('lista');
  const [filtroPadrinho, setFiltroPadrinho] = useState<FiltroPadrinho>('todos');
  const [filtroLado, setFiltroLado] = useState<'todos' | Lado>('todos');
  const [filtroFamilia, setFiltroFamilia] = useState('todas');
  const [agrupar, setAgrupar] = useState(true);
  const [qtdMesas, setQtdMesas] = useState(base.mesas ? String(base.mesas) : '');
  const [qtdCadeiras, setQtdCadeiras] = useState(
    base.cadeirasPorMesa ? String(base.cadeirasPorMesa) : '',
  );
  const [alocacoes, setAlocacoes] = useState<AlocacaoMesa[]>(base.alocacoes);
  const [ladoMesas, setLadoMesas] = useState<string[]>(base.ladoMesas);
  const [mesas, setMesas] = useState(base.mesas);
  const [cadeiras, setCadeiras] = useState(base.cadeirasPorMesa);
  const [busy, setBusy] = useState(false);
  const [aviso, setAviso] = useState<string | null>(null);
  const [buscaLado, setBuscaLado] = useState('');
  const [buscaCadeira, setBuscaCadeira] = useState('');
  const [cadeiraAberta, setCadeiraAberta] = useState<{
    mesa: number;
    cadeira: number;
  } | null>(null);

  useEffect(() => {
    const p: PlanoMesas = JSON.parse(planoKey);
    setQtdMesas(p.mesas ? String(p.mesas) : '');
    setQtdCadeiras(p.cadeirasPorMesa ? String(p.cadeirasPorMesa) : '');
    setAlocacoes(p.alocacoes ?? []);
    setLadoMesas(p.ladoMesas ?? []);
    setMesas(p.mesas ?? 0);
    setCadeiras(p.cadeirasPorMesa ?? 0);
  }, [planoKey]);

  const pessoas = useMemo(
    () => pessoasDaLista(convidados, padrinhos, alocacoes),
    [convidados, padrinhos, alocacoes],
  );

  const familias = useMemo(() => {
    const map = new Map<string, string>();
    for (const p of pessoas) {
      if (!map.has(p.familiaId)) map.set(p.familiaId, p.familiaNome);
    }
    return [...map.entries()].sort((a, b) => a[1].localeCompare(b[1], 'pt-BR'));
  }, [pessoas]);

  useEffect(() => {
    if (filtroFamilia !== 'todas' && !familias.some(([id]) => id === filtroFamilia)) {
      setFiltroFamilia('todas');
    }
  }, [familias, filtroFamilia]);

  const filtradas = useMemo(() => {
    return pessoas.filter((p) => {
      if (filtroLado !== 'todos' && p.lado !== filtroLado) return false;
      if (filtroFamilia !== 'todas' && p.familiaId !== filtroFamilia) return false;
      if (filtroPadrinho === 'sim' && !p.familiaEhPadrinho) return false;
      if (filtroPadrinho === 'nao' && p.familiaEhPadrinho) return false;
      return true;
    });
  }, [pessoas, filtroLado, filtroFamilia, filtroPadrinho]);

  const grupos = useMemo(() => {
    const map = new Map<string, { titulo: string; pessoas: Pessoa[] }>();
    for (const p of filtradas) {
      const g = map.get(p.familiaId);
      if (g) g.pessoas.push(p);
      else map.set(p.familiaId, { titulo: p.familiaNome, pessoas: [p] });
    }
    return [...map.values()].sort((a, b) =>
      a.titulo.localeCompare(b.titulo, 'pt-BR'),
    );
  }, [filtradas]);

  const confirmados = useMemo(
    () => pessoas.filter((p) => p.confirmado),
    [pessoas],
  );

  const semMesa = useMemo(
    () => confirmados.filter((p) => !p.mesa),
    [confirmados],
  );

  const semMesaLado = useMemo(
    () => semMesa.filter((p) => combinaNome(p.nome, buscaLado)),
    [semMesa, buscaLado],
  );

  const semMesaCadeira = useMemo(
    () => semMesa.filter((p) => combinaNome(p.nome, buscaCadeira)),
    [semMesa, buscaCadeira],
  );

  const porChave = useMemo(() => {
    const map = new Map<string, Pessoa>();
    for (const p of pessoas) map.set(p.chave, p);
    return map;
  }, [pessoas]);

  function descricaoFiltros() {
    const partes = [
      filtroPadrinho === 'sim'
        ? 'Só padrinhos'
        : filtroPadrinho === 'nao'
          ? 'Sem padrinhos'
          : 'Padrinhos e convidados',
      filtroLado === 'todos' ? 'Todos os lados' : `Lado ${ladoLabel(filtroLado)}`,
    ];
    if (filtroFamilia !== 'todas') {
      const nome = familias.find(([id]) => id === filtroFamilia)?.[1];
      if (nome) partes.push(`Família ${nome}`);
    }
    if (agrupar) partes.push('Agrupado por família');
    return partes.join(' · ');
  }

  function imprimir() {
    const linhas = (lista: Pessoa[]) =>
      lista.map((p) => ({
        nome: p.nome,
        meta: metaDe(p),
      }));
    try {
      imprimirRelatorioLista({
        titulo: 'Lista de convidados',
        subtitulo: `${descricaoFiltros()} · ${filtradas.length} pessoa(s)`,
        items: agrupar ? [] : linhas(filtradas),
        grupos: agrupar
          ? grupos.map((g) => ({ titulo: g.titulo, items: linhas(g.pessoas) }))
          : undefined,
      });
    } catch (e) {
      setAviso(e instanceof Error ? e.message : 'Erro ao abrir impressão');
    }
  }

  function imprimirMesas() {
    if (mesas < 1) {
      setAviso('Distribua as mesas antes de imprimir.');
      return;
    }
    const grupos: { titulo: string; items: { nome: string; meta: string }[] }[] =
      [];
    for (let numero = 1; numero <= mesas; numero++) {
      const lado = ladoLabel(ladoMesas[numero - 1] || 'ambos');
      const items = alocacoes
        .filter((a) => a.mesa === numero)
        .sort((a, b) => a.cadeira - b.cadeira)
        .map((a) => {
          const p = porChave.get(a.chave);
          const bits = [`Cadeira ${a.cadeira}`];
          if (p) {
            bits.push(`Lado ${ladoLabel(p.lado)}`);
            if (p.padrinhoLabel) bits.push(p.padrinhoLabel);
          }
          return { nome: p?.nome || 'Convidado', meta: bits.join(' · ') };
        });
      if (items.length === 0) continue;
      grupos.push({ titulo: `Mesa ${numero} · ${lado}`, items });
    }
    const livres = confirmados.filter((p) => !p.mesa);
    if (livres.length > 0) {
      grupos.push({
        titulo: 'Sem mesa',
        items: livres.map((p) => ({
          nome: p.nome,
          meta: [
            `Lado ${ladoLabel(p.lado)}`,
            p.padrinhoLabel,
            'Confirmou presença',
          ]
            .filter(Boolean)
            .join(' · '),
        })),
      });
    }
    if (grupos.length === 0) {
      setAviso('Ninguém está sentado ainda.');
      return;
    }
    try {
      imprimirRelatorioLista({
        titulo: 'Repartição de mesas',
        subtitulo: `${mesas} mesa(s) · ${cadeiras} cadeira(s) · ${alocacoes.length} pessoa(s) sentada(s)`,
        items: [],
        grupos,
      });
    } catch (e) {
      setAviso(e instanceof Error ? e.message : 'Erro ao abrir impressão');
    }
  }

  async function persistir(next: AlocacaoMesa[]) {
    if (!token) return;
    setAlocacoes(next);
    setBusy(true);
    setAviso(null);
    try {
      await salvarPlanoMesas(token, {
        id: base.id,
        mesas,
        cadeirasPorMesa: cadeiras,
        alocacoes: next,
        ladoMesas,
      });
      await refresh(true);
    } catch (e) {
      setAviso(e instanceof Error ? e.message : 'Erro ao salvar as mesas');
      return false;
    } finally {
      setBusy(false);
    }
    return true;
  }

  async function distribuir() {
    if (!token) return;
    const nMesas = Math.floor(Number(qtdMesas));
    const nCadeiras = Math.floor(Number(qtdCadeiras));
    if (!Number.isFinite(nMesas) || nMesas < 1 || nMesas > 100) {
      setAviso('Informe de 1 a 100 mesas.');
      return;
    }
    if (!Number.isFinite(nCadeiras) || nCadeiras < 1 || nCadeiras > 40) {
      setAviso('Informe de 1 a 40 cadeiras por mesa.');
      return;
    }
    if (
      alocacoes.length > 0 &&
      !window.confirm(
        'Redistribuir substitui os lugares que você já ajustou. Continuar?',
      )
    ) {
      return;
    }
    setBusy(true);
    setAviso(null);
    try {
      await distribuirMesas(token, {
        mesas: nMesas,
        cadeirasPorMesa: nCadeiras,
      });
      await refresh(true);
      setAviso('Lugares distribuídos.');
    } catch (e) {
      setAviso(e instanceof Error ? e.message : 'Erro ao distribuir');
    } finally {
      setBusy(false);
    }
  }

  async function limpar() {
    if (alocacoes.length === 0 || busy) return;
    if (
      !window.confirm(
        'Isso tira todo mundo das cadeiras. As mesas continuam e você pode preencher de novo. Continuar?',
      )
    ) {
      return;
    }
    const ok = await persistir([]);
    if (ok) setAviso('Lugares limpos. Você pode preencher de novo.');
  }

  function onDragStart(e: DragEvent, chave: string) {
    e.dataTransfer.setData('text/plain', chave);
    e.dataTransfer.effectAllowed = 'move';
  }

  function lerChave(e: DragEvent) {
    return e.dataTransfer.getData('text/plain');
  }

  return (
    <div className="list">
      <div className="tabs" role="tablist">
        <button
          type="button"
          className={aba === 'lista' ? 'active' : ''}
          onClick={() => setAba('lista')}
        >
          Convidados
        </button>
        <button
          type="button"
          className={aba === 'mesas' ? 'active' : ''}
          onClick={() => setAba('mesas')}
        >
          Repartição
        </button>
      </div>

      {aviso && <p className="hint">{aviso}</p>}

      {aba === 'lista' && (
        <div className="panel">
          <h2 style={{ marginTop: 0 }}>Todos os convidados</h2>
          <div className="salao-filtros">
            <div>
              <label htmlFor="filtro-padrinho">Padrinhos</label>
              <select
                id="filtro-padrinho"
                value={filtroPadrinho}
                onChange={(e) =>
                  setFiltroPadrinho(e.target.value as FiltroPadrinho)
                }
              >
                <option value="todos">Todos</option>
                <option value="sim">Só padrinhos</option>
                <option value="nao">Sem padrinhos</option>
              </select>
            </div>
            <div>
              <label htmlFor="filtro-lado">Lado</label>
              <select
                id="filtro-lado"
                value={filtroLado}
                onChange={(e) =>
                  setFiltroLado(e.target.value as 'todos' | Lado)
                }
              >
                <option value="todos">Todos</option>
                <option value="noivo">Noivo</option>
                <option value="noiva">Noiva</option>
                <option value="ambos">Ambos</option>
              </select>
            </div>
            <div>
              <label htmlFor="filtro-familia">Família</label>
              <select
                id="filtro-familia"
                value={filtroFamilia}
                onChange={(e) => setFiltroFamilia(e.target.value)}
              >
                <option value="todas">Todas</option>
                {familias.map(([id, nome]) => (
                  <option key={id} value={id}>
                    {nome}
                  </option>
                ))}
              </select>
            </div>
          </div>
          <div className="row" style={{ alignItems: 'center', marginTop: 8 }}>
            <label className="checks" style={{ margin: 0 }}>
              <input
                type="checkbox"
                checked={agrupar}
                onChange={(e) => setAgrupar(e.target.checked)}
              />
              Agrupar por família
            </label>
            <button type="button" className="primary" onClick={imprimir}>
              Imprimir / PDF
            </button>
          </div>
          <p className="hint" style={{ textAlign: 'left' }}>
            {descricaoFiltros()} · {filtradas.length} pessoa(s)
          </p>
          {filtradas.length === 0 && <p>Nenhuma pessoa nesta seleção.</p>}
          {agrupar
            ? grupos.map((g) => (
                <section key={g.titulo} className="salao-grupo">
                  <h3>{g.titulo}</h3>
                  {g.pessoas.map((p) => (
                    <PessoaLinha key={p.chave} pessoa={p} />
                  ))}
                </section>
              ))
            : filtradas.map((p) => <PessoaLinha key={p.chave} pessoa={p} />)}
        </div>
      )}

      {aba === 'mesas' && (
        <div className="salao-reparticao">
          <div className="panel">
            <h2 style={{ marginTop: 0 }}>Mesas</h2>
            <p className="hint" style={{ textAlign: 'left', marginTop: 0 }}>
              Só quem confirmou presença ganha cadeira. A noiva fica nas
              primeiras mesas e o noivo nas seguintes. Quem é dos dois lados
              entra nas cadeiras que sobrarem.
            </p>
            <div className="salao-filtros">
              <div>
                <label htmlFor="qtd-mesas">Quantidade de mesas</label>
                <input
                  id="qtd-mesas"
                  inputMode="numeric"
                  value={qtdMesas}
                  onChange={(e) => setQtdMesas(e.target.value)}
                />
              </div>
              <div>
                <label htmlFor="qtd-cadeiras">Cadeiras por mesa</label>
                <input
                  id="qtd-cadeiras"
                  inputMode="numeric"
                  value={qtdCadeiras}
                  onChange={(e) => setQtdCadeiras(e.target.value)}
                />
              </div>
            </div>
            <button
              type="button"
              className="primary"
              disabled={busy}
              onClick={distribuir}
            >
              {alocacoes.length > 0 ? 'Redistribuir' : 'Distribuir'}
            </button>
            <button
              type="button"
              className="danger"
              style={{ width: '100%', marginTop: 8 }}
              disabled={busy || alocacoes.length === 0}
              onClick={limpar}
            >
              Limpar lugares
            </button>
            <button
              type="button"
              className="ghost"
              style={{ width: '100%', marginTop: 8 }}
              disabled={busy || mesas < 1}
              onClick={imprimirMesas}
            >
              Imprimir mesas
            </button>
          </div>

          <div className="salao-board">
            <div
              className="panel salao-pessoas"
              onDragOver={(e) => e.preventDefault()}
              onDrop={(e) => {
                e.preventDefault();
                const chave = lerChave(e);
                if (!chave || busy) return;
                void persistir(moverPessoa(alocacoes, chave, null));
              }}
            >
              <h2 style={{ marginTop: 0 }}>Sem mesa</h2>
              <p className="hint" style={{ textAlign: 'left', marginTop: 0 }}>
                Quem já sentou sai desta lista. Pesquise e arraste para uma
                cadeira, ou solte aqui para tirar da mesa.
              </p>
              <label htmlFor="busca-lado">Pesquisar</label>
              <input
                id="busca-lado"
                value={buscaLado}
                placeholder="Nome de quem está sem mesa"
                onChange={(e) => setBuscaLado(e.target.value)}
              />
              <div className="salao-pessoas-lista">
                {semMesaLado.map((p) => (
                  <div
                    key={p.chave}
                    className="salao-chip"
                    draggable={!busy}
                    onDragStart={(e) => onDragStart(e, p.chave)}
                  >
                    <strong>{p.nome}</strong>
                    <span>
                      {ladoLabel(p.lado)}
                      {p.familiaEhPadrinho && p.padrinhoLabel
                        ? ` · ${p.padrinhoLabel}`
                        : ''}
                    </span>
                  </div>
                ))}
                {confirmados.length === 0 && (
                  <p>Ninguém confirmou presença ainda.</p>
                )}
                {confirmados.length > 0 && semMesa.length === 0 && (
                  <p>Todas as pessoas confirmadas já têm lugar.</p>
                )}
                {semMesa.length > 0 && semMesaLado.length === 0 && (
                  <p>Nenhuma pessoa com esse nome.</p>
                )}
              </div>
            </div>

            <div className="salao-mesas">
              {mesas < 1 && (
                <div className="panel">
                  <p>Informe as mesas e toque em Distribuir.</p>
                </div>
              )}
              {Array.from({ length: mesas }, (_, i) => i + 1).map((numero) => {
                const lado = ladoMesas[numero - 1] || 'ambos';
                return (
                  <section
                    key={numero}
                    className={`panel salao-mesa salao-mesa-${lado}`}
                  >
                    <h3>
                      Mesa {numero}
                      <span className="badge">{ladoLabel(lado)}</span>
                    </h3>
                    <div className="salao-cadeiras">
                      {Array.from({ length: cadeiras }, (_, c) => c + 1).map(
                        (cadeira) => {
                          const aloc = alocacoes.find(
                            (a) => a.mesa === numero && a.cadeira === cadeira,
                          );
                          const pessoa = aloc
                            ? porChave.get(aloc.chave)
                            : undefined;
                          return (
                            <div
                              key={cadeira}
                              className={`salao-cadeira${pessoa ? ' ocupada' : ''}`}
                              onDragOver={(e) => e.preventDefault()}
                              onDrop={(e) => {
                                e.preventDefault();
                                e.stopPropagation();
                                const chave = lerChave(e);
                                if (!chave || busy) return;
                                void persistir(
                                  moverPessoa(alocacoes, chave, {
                                    mesa: numero,
                                    cadeira,
                                  }),
                                );
                              }}
                            >
                              <span className="salao-cadeira-num">
                                Cadeira {cadeira}
                              </span>
                              {pessoa ? (
                                <strong
                                  draggable={!busy}
                                  onDragStart={(e) => {
                                    e.stopPropagation();
                                    onDragStart(e, pessoa.chave);
                                  }}
                                >
                                  {pessoa.nome}
                                </strong>
                              ) : (
                                <button
                                  type="button"
                                  className="salao-vazia"
                                  disabled={busy}
                                  onClick={() => {
                                    setBuscaCadeira('');
                                    setCadeiraAberta({
                                      mesa: numero,
                                      cadeira,
                                    });
                                  }}
                                >
                                  Vazia · escolher
                                </button>
                              )}
                            </div>
                          );
                        },
                      )}
                    </div>
                  </section>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {cadeiraAberta && (
        <div
          className="salao-busca-modal"
          role="presentation"
          onClick={() => setCadeiraAberta(null)}
        >
          <div
            className="panel salao-busca-painel"
            role="dialog"
            aria-modal="true"
            aria-labelledby="busca-cadeira-titulo"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 id="busca-cadeira-titulo" style={{ marginTop: 0 }}>
              Mesa {cadeiraAberta.mesa}, cadeira {cadeiraAberta.cadeira}
            </h2>
            <label htmlFor="busca-cadeira">
              Pesquisar quem ainda está sem mesa
            </label>
            <input
              id="busca-cadeira"
              autoFocus
              value={buscaCadeira}
              placeholder="Digite o nome"
              onChange={(e) => setBuscaCadeira(e.target.value)}
            />
            <div className="salao-busca-lista">
              {semMesaCadeira.map((p) => (
                <button
                  key={p.chave}
                  type="button"
                  className="salao-busca-item"
                  disabled={busy}
                  onClick={() => {
                    const destino = cadeiraAberta;
                    setCadeiraAberta(null);
                    void persistir(
                      moverPessoa(alocacoes, p.chave, destino),
                    );
                  }}
                >
                  <strong>{p.nome}</strong>
                  <span>
                    {ladoLabel(p.lado)}
                    {p.padrinhoLabel ? ` · ${p.padrinhoLabel}` : ''}
                  </span>
                </button>
              ))}
              {semMesa.length === 0 && (
                <p>Todas as pessoas confirmadas já têm lugar.</p>
              )}
              {semMesa.length > 0 && semMesaCadeira.length === 0 && (
                <p>Nenhuma pessoa com esse nome.</p>
              )}
            </div>
            <button
              type="button"
              className="ghost"
              onClick={() => setCadeiraAberta(null)}
            >
              Fechar
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

function PessoaLinha({ pessoa }: { pessoa: Pessoa }) {
  return (
    <div className="item">
      <strong>{pessoa.nome}</strong>
      <p>{metaDe(pessoa)}</p>
    </div>
  );
}
