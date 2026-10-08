import { useState, type FormEvent } from 'react';
import { deleteAnotacao, upsertAnotacao, type Anotacao } from '../api';
import { useAuth } from '../auth';
import { imprimirRelatorioLista } from '../printReport';

function hoje() {
  const d = new Date();
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

function formatarData(iso: string) {
  const [y, m, d] = iso.slice(0, 10).split('-');
  if (!y || !m || !d) return iso;
  return `${d}/${m}/${y}`;
}

const LINK = /(?:https?:\/\/|www\.)[^\s<]+/gi;

function partesDoTexto(texto: string) {
  const partes: { texto: string; href?: string }[] = [];
  let ultimo = 0;
  for (const match of texto.matchAll(LINK)) {
    const inicio = match.index ?? 0;
    if (inicio > ultimo) {
      partes.push({ texto: texto.slice(ultimo, inicio) });
    }
    let valor = match[0];
    let sobra = '';
    while (valor && /[.,;:!?)\]]$/.test(valor)) {
      sobra = valor.slice(-1) + sobra;
      valor = valor.slice(0, -1);
    }
    if (valor) {
      const href = /^https?:\/\//i.test(valor) ? valor : `https://${valor}`;
      partes.push({ texto: valor, href });
    }
    if (sobra) partes.push({ texto: sobra });
    ultimo = inicio + match[0].length;
  }
  if (ultimo < texto.length) partes.push({ texto: texto.slice(ultimo) });
  return partes;
}

function TextoComLinks({ texto }: { texto: string }) {
  return (
    <p className="anotacao-texto">
      {partesDoTexto(texto).map((parte, i) =>
        parte.href ? (
          <a
            key={i}
            href={parte.href}
            target="_blank"
            rel="noopener noreferrer"
          >
            {parte.texto}
          </a>
        ) : (
          <span key={i}>{parte.texto}</span>
        ),
      )}
    </p>
  );
}

export default function AnotacoesPage({ anotacoes }: { anotacoes: Anotacao[] }) {
  const { token, refresh } = useAuth();
  const [data, setData] = useState(hoje);
  const [titulo, setTitulo] = useState('');
  const [descricao, setDescricao] = useState('');
  const [editId, setEditId] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [aviso, setAviso] = useState<string | null>(null);

  function limparForm() {
    setData(hoje());
    setTitulo('');
    setDescricao('');
    setEditId(null);
  }

  function editar(nota: Anotacao) {
    setEditId(nota.id);
    setData(nota.data.slice(0, 10));
    setTitulo(nota.titulo);
    setDescricao(nota.descricao);
    setAviso(null);
  }

  async function salvar(e: FormEvent) {
    e.preventDefault();
    if (!token) return;
    const t = titulo.trim();
    const desc = descricao.trim();
    if (!data) {
      setAviso('Informe a data.');
      return;
    }
    if (!t) {
      setAviso('Informe o título.');
      return;
    }
    if (!desc) {
      setAviso('Informe a descrição.');
      return;
    }
    setBusy(true);
    setAviso(null);
    try {
      await upsertAnotacao(token, {
        id: editId,
        data,
        titulo: t,
        descricao: desc,
      });
      await refresh(true);
      limparForm();
      setAviso(editId ? 'Anotação atualizada.' : 'Anotação adicionada.');
    } catch (err) {
      setAviso(err instanceof Error ? err.message : 'Erro ao salvar');
    } finally {
      setBusy(false);
    }
  }

  async function excluir(nota: Anotacao) {
    if (!token) return;
    if (!window.confirm(`Excluir a anotação “${nota.titulo}”?`)) return;
    setBusy(true);
    setAviso(null);
    try {
      await deleteAnotacao(token, nota.id);
      if (editId === nota.id) limparForm();
      await refresh(true);
      setAviso('Anotação excluída.');
    } catch (err) {
      setAviso(err instanceof Error ? err.message : 'Erro ao excluir');
    } finally {
      setBusy(false);
    }
  }

  function imprimir() {
    if (anotacoes.length === 0) {
      setAviso('Não há anotações para imprimir.');
      return;
    }
    try {
      imprimirRelatorioLista({
        titulo: 'Anotações',
        subtitulo: `${anotacoes.length} anotação(ões)`,
        rodape: 'anotações',
        items: anotacoes.map((n) => ({
          nome: n.titulo,
          meta: `${formatarData(n.data)} · ${n.descricao}`,
        })),
      });
    } catch (err) {
      setAviso(err instanceof Error ? err.message : 'Erro ao abrir impressão');
    }
  }

  return (
    <div className="list">
      <div className="panel">
        <h2 style={{ marginTop: 0 }}>
          {editId ? 'Editar anotação' : 'Nova anotação'}
        </h2>
        <form onSubmit={(e) => void salvar(e)}>
          <label htmlFor="anotacao-data">Data</label>
          <input
            id="anotacao-data"
            type="date"
            value={data}
            onChange={(e) => setData(e.target.value)}
          />
          <label htmlFor="anotacao-titulo">Título</label>
          <input
            id="anotacao-titulo"
            value={titulo}
            placeholder="Título da anotação"
            onChange={(e) => setTitulo(e.target.value)}
          />
          <label htmlFor="anotacao-descricao">Descrição</label>
          <textarea
            id="anotacao-descricao"
            rows={4}
            value={descricao}
            placeholder="O que você quer anotar"
            onChange={(e) => setDescricao(e.target.value)}
          />
          <div className="row">
            <button type="submit" className="primary" disabled={busy}>
              {editId ? 'Salvar alterações' : 'Adicionar'}
            </button>
            {editId && (
              <button
                type="button"
                className="ghost"
                disabled={busy}
                onClick={limparForm}
              >
                Cancelar
              </button>
            )}
          </div>
        </form>
        {aviso && (
          <p className="hint" style={{ textAlign: 'left' }}>
            {aviso}
          </p>
        )}
      </div>

      <div className="panel">
        <div className="row" style={{ justifyContent: 'space-between' }}>
          <h2 style={{ margin: 0 }}>Anotações</h2>
          <button
            type="button"
            className="ghost"
            disabled={busy || anotacoes.length === 0}
            onClick={imprimir}
          >
            Imprimir / PDF
          </button>
        </div>
        {anotacoes.length === 0 && <p>Nenhuma anotação ainda.</p>}
        {anotacoes.map((n) => (
          <article key={n.id} className="item">
            <strong>{n.titulo}</strong>
            <p style={{ margin: '4px 0', color: 'var(--muted)' }}>
              {formatarData(n.data)}
            </p>
            <TextoComLinks texto={n.descricao} />
            <div className="actions">
              <button
                type="button"
                className="ghost"
                disabled={busy}
                onClick={() => editar(n)}
              >
                Editar
              </button>
              <button
                type="button"
                className="danger"
                disabled={busy}
                onClick={() => void excluir(n)}
              >
                Excluir
              </button>
            </div>
          </article>
        ))}
      </div>
    </div>
  );
}
