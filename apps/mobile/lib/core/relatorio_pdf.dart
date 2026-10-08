import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

typedef LinhaRelatorio = ({String nome, String meta});
typedef GrupoRelatorio = ({String titulo, List<LinhaRelatorio> items});

List<pw.Widget> _linhas(List<LinhaRelatorio> items) {
  if (items.isEmpty) {
    return [pw.Text('Nenhuma pessoa nesta seleção.')];
  }
  return [
    for (var i = 0; i < items.length; i++)
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 28,
              child: pw.Text(
                '${i + 1}.',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    items[i].nome,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (items[i].meta.isNotEmpty)
                    pw.Text(
                      items[i].meta,
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
  ];
}

class RelatorioPdf {
  static Future<void> imprimirLista({
    required String titulo,
    required List<LinhaRelatorio> items,
    String? subtitulo,
    List<GrupoRelatorio>? grupos,
    String rodape = 'relatório de convidados',
  }) async {
    final doc = pw.Document();
    final gerado = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final total = grupos == null
        ? items.length
        : grupos.fold<int>(0, (n, g) => n + g.items.length);
    final linha = subtitulo ?? '$total pessoa(s)';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 48),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              titulo,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '$linha · Gerado em $gerado',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (ctx) => pw.Text(
          'Ludmila & Dyego — $rodape · página ${ctx.pageNumber}/${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        build: (ctx) {
          if (grupos != null) {
            if (grupos.isEmpty) {
              return [pw.Text('Nenhuma pessoa nesta seleção.')];
            }
            return [
              for (final g in grupos) ...[
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 8, bottom: 6),
                  child: pw.Text(
                    g.titulo,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                ..._linhas(g.items),
              ],
            ];
          }
          if (items.isEmpty) {
            return [pw.Text('Nenhuma pessoa nesta seleção.')];
          }
          return _linhas(items);
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: titulo,
    );
  }
}
