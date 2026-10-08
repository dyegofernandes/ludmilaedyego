import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/relatorio_pdf.dart';
import '../../core/theme.dart';
import '../../data/app_store.dart';
import '../../models/models.dart';

final _link = RegExp(r'(?:https?:\/\/|www\.)\S+', caseSensitive: false);

class _TextoComLinks extends StatefulWidget {
  const _TextoComLinks({required this.texto});

  final String texto;

  @override
  State<_TextoComLinks> createState() => _TextoComLinksState();
}

class _TextoComLinksState extends State<_TextoComLinks> {
  final List<TapGestureRecognizer> _toques = [];
  late List<InlineSpan> _spans;

  @override
  void initState() {
    super.initState();
    _spans = _montar(widget.texto);
  }

  @override
  void didUpdateWidget(_TextoComLinks oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.texto == widget.texto) return;
    _spans = _montar(widget.texto);
  }

  @override
  void dispose() {
    _liberar();
    super.dispose();
  }

  void _liberar() {
    for (final toque in _toques) {
      toque.dispose();
    }
    _toques.clear();
  }

  TapGestureRecognizer _abrir(String href) {
    final toque = TapGestureRecognizer()
      ..onTap = () {
        final uri = Uri.tryParse(href);
        if (uri == null) return;
        launchUrl(uri, mode: LaunchMode.externalApplication);
      };
    _toques.add(toque);
    return toque;
  }

  List<InlineSpan> _montar(String texto) {
    _liberar();
    final spans = <InlineSpan>[];
    var ultimo = 0;
    for (final match in _link.allMatches(texto)) {
      if (match.start > ultimo) {
        spans.add(TextSpan(text: texto.substring(ultimo, match.start)));
      }
      var valor = match.group(0)!;
      var sobra = '';
      while (valor.isNotEmpty && RegExp(r'[.,;:!?)\]]$').hasMatch(valor)) {
        sobra = valor.substring(valor.length - 1) + sobra;
        valor = valor.substring(0, valor.length - 1);
      }
      if (valor.isNotEmpty) {
        final href = valor.toLowerCase().startsWith('http')
            ? valor
            : 'https://$valor';
        spans.add(
          TextSpan(
            text: valor,
            style: const TextStyle(
              color: AppColors.primaryDark,
              decoration: TextDecoration.underline,
            ),
            recognizer: _abrir(href),
          ),
        );
      }
      if (sobra.isNotEmpty) spans.add(TextSpan(text: sobra));
      ultimo = match.end;
    }
    if (ultimo < texto.length) {
      spans.add(TextSpan(text: texto.substring(ultimo)));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(TextSpan(children: _spans));
  }
}

class AnotacoesScreen extends StatefulWidget {
  const AnotacoesScreen({super.key});

  @override
  State<AnotacoesScreen> createState() => _AnotacoesScreenState();
}

class _AnotacoesScreenState extends State<AnotacoesScreen> {
  final _tituloCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  DateTime _data = DateTime.now();
  String? _editId;
  bool _busy = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
  }

  void _limpar() {
    setState(() {
      _editId = null;
      _data = DateTime.now();
      _tituloCtrl.clear();
      _descricaoCtrl.clear();
    });
  }

  void _editar(Anotacao nota) {
    setState(() {
      _editId = nota.id;
      _data = nota.data;
      _tituloCtrl.text = nota.titulo;
      _descricaoCtrl.text = nota.descricao;
    });
  }

  Future<void> _salvar() async {
    final titulo = _tituloCtrl.text.trim();
    final descricao = _descricaoCtrl.text.trim();
    if (titulo.isEmpty) {
      _aviso('Informe o título.');
      return;
    }
    if (descricao.isEmpty) {
      _aviso('Informe a descrição.');
      return;
    }
    final store = context.read<AppStore>();
    setState(() => _busy = true);
    final err = await store.upsertAnotacao(
      id: _editId,
      data: _data,
      titulo: titulo,
      descricao: descricao,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      _aviso(err);
    } else {
      _limpar();
      _aviso('Anotação salva.');
    }
  }

  Future<void> _excluir(Anotacao nota) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir anotação'),
        content: Text('Excluir “${nota.titulo}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final err = await context.read<AppStore>().removerAnotacao(nota.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (_editId == nota.id) _limpar();
    if (err != null) _aviso(err);
  }

  Future<void> _imprimir(List<Anotacao> lista) async {
    if (lista.isEmpty) {
      _aviso('Não há anotações para imprimir.');
      return;
    }
    final fmt = DateFormat('dd/MM/yyyy');
    await RelatorioPdf.imprimirLista(
      titulo: 'Anotações',
      subtitulo: '${lista.length} anotação(ões)',
      rodape: 'anotações',
      items: [
        for (final n in lista)
          (nome: n.titulo, meta: '${fmt.format(n.data)} · ${n.descricao}'),
      ],
    );
  }

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final lista = [...store.anotacoes]..sort((a, b) {
        final porData = b.data.compareTo(a.data);
        if (porData != 0) return porData;
        return b.createdAt.compareTo(a.createdAt);
      });
    final fmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Text(
                    'Anotações',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Imprimir',
                  onPressed: _busy ? null : () => _imprimir(lista),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _editId == null ? 'Nova anotação' : 'Editar anotação',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _escolherData,
              icon: const Icon(Icons.event_outlined),
              label: Text(fmt.format(_data)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(labelText: 'Título'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descricaoCtrl,
              decoration: const InputDecoration(labelText: 'Descrição'),
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _salvar,
              child: Text(_editId == null ? 'Adicionar' : 'Salvar alterações'),
            ),
            if (_editId != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : _limpar,
                child: const Text('Cancelar'),
              ),
            ],
            const SizedBox(height: 20),
            if (lista.isEmpty)
              const Text('Nenhuma anotação ainda.')
            else
              for (final n in lista)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.titulo,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fmt.format(n.data),
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 6),
                        _TextoComLinks(texto: n.descricao),
                        Row(
                          children: [
                            TextButton(
                              onPressed: _busy ? null : () => _editar(n),
                              child: const Text('Editar'),
                            ),
                            TextButton(
                              onPressed: _busy ? null : () => _excluir(n),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.danger,
                              ),
                              child: const Text('Excluir'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
