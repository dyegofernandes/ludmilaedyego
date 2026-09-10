/** Abre janela de impressão / salvar PDF com lista numerada. */
export function imprimirRelatorioLista(input: {
  titulo: string;
  subtitulo?: string;
  items: { nome: string; meta?: string }[];
}) {
  const agora = new Date().toLocaleString('pt-BR');
  const linhas = input.items
    .map((item, i) => {
      const meta = item.meta
        ? `<span class="meta">${escapeHtml(item.meta)}</span>`
        : '';
      return `<li><strong>${escapeHtml(item.nome)}</strong>${meta}</li>`;
    })
    .join('\n');

  const html = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8" />
  <title>${escapeHtml(input.titulo)}</title>
  <style>
    @page { margin: 18mm 16mm; }
    body {
      font-family: Georgia, "Times New Roman", serif;
      color: #1a1a1a;
      margin: 0;
      padding: 0;
      font-size: 12pt;
      line-height: 1.45;
    }
    h1 {
      font-size: 18pt;
      margin: 0 0 4px;
      font-weight: 700;
    }
    .sub {
      color: #555;
      font-size: 10pt;
      margin: 0 0 16px;
    }
    ol {
      margin: 0;
      padding-left: 1.6em;
    }
    li {
      margin: 0 0 8px;
      padding-bottom: 6px;
      border-bottom: 1px solid #e8e2d8;
    }
    li strong { display: block; }
    .meta {
      display: block;
      color: #666;
      font-size: 9.5pt;
      font-family: Arial, Helvetica, sans-serif;
      margin-top: 2px;
    }
    .foot {
      margin-top: 20px;
      font-size: 9pt;
      color: #888;
      font-family: Arial, Helvetica, sans-serif;
    }
  </style>
</head>
<body>
  <h1>${escapeHtml(input.titulo)}</h1>
  <p class="sub">${escapeHtml(
    input.subtitulo || `${input.items.length} pessoa(s)`,
  )} · Gerado em ${escapeHtml(agora)}</p>
  ${
    input.items.length === 0
      ? '<p>Nenhuma pessoa nesta seleção.</p>'
      : `<ol>${linhas}</ol>`
  }
  <p class="foot">Ludmila &amp; Dyego — relatório de convidados</p>
  <script>
    window.onload = function () {
      window.focus();
      window.print();
    };
  </script>
</body>
</html>`;

  const win = window.open('', '_blank', 'noopener,noreferrer');
  if (!win) {
    throw new Error(
      'Não foi possível abrir a janela de impressão. Permita pop-ups neste site.',
    );
  }
  win.document.open();
  win.document.write(html);
  win.document.close();
}

function escapeHtml(s: string) {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
