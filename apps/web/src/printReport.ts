/** Imprime / salva PDF uma lista numerada (sem depender de pop-up). */
export function imprimirRelatorioLista(input: {
  titulo: string;
  subtitulo?: string;
  items: { nome: string; meta?: string }[];
}) {
  const agora = new Date().toLocaleString('pt-BR');
  const linhas = input.items
    .map((item) => {
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
    @page { margin: 18mm 16mm; size: A4; }
    * { box-sizing: border-box; }
    html, body {
      font-family: Georgia, "Times New Roman", serif;
      color: #1a1a1a;
      margin: 0;
      padding: 16px;
      font-size: 12pt;
      line-height: 1.45;
      background: #fff;
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
      page-break-inside: avoid;
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
</body>
</html>`;

  const iframe = document.createElement('iframe');
  iframe.setAttribute('title', 'Impressão do relatório');
  iframe.style.position = 'fixed';
  iframe.style.right = '0';
  iframe.style.bottom = '0';
  iframe.style.width = '0';
  iframe.style.height = '0';
  iframe.style.border = '0';
  iframe.style.opacity = '0';
  iframe.style.pointerEvents = 'none';
  document.body.appendChild(iframe);

  const doc = iframe.contentDocument || iframe.contentWindow?.document;
  if (!doc || !iframe.contentWindow) {
    iframe.remove();
    // Fallback: blob + nova aba (sem noopener, para conseguir escrever)
    const blob = new Blob([html], { type: 'text/html;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const win = window.open(url, '_blank');
    if (!win) {
      URL.revokeObjectURL(url);
      throw new Error(
        'Não foi possível imprimir. Permita pop-ups neste site e tente de novo.',
      );
    }
    win.focus();
    window.setTimeout(() => {
      try {
        win.print();
      } finally {
        URL.revokeObjectURL(url);
      }
    }, 400);
    return;
  }

  doc.open();
  doc.write(html);
  doc.close();

  let printed = false;
  const cleanup = () => {
    window.setTimeout(() => iframe.remove(), 1500);
  };

  const runPrint = () => {
    if (printed) return;
    printed = true;
    try {
      iframe.contentWindow?.focus();
      iframe.contentWindow?.print();
    } finally {
      cleanup();
    }
  };

  iframe.onload = () => window.setTimeout(runPrint, 80);
  window.setTimeout(runPrint, 400);
}

function escapeHtml(s: string) {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
