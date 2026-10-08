import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/relatorio_pdf.dart';
import '../../core/theme.dart';
import '../../data/app_store.dart';
import '../../models/models.dart';

String _semAcento(String s) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const para = 'aaaaaeeeeiiiiooooouuuucn';
  var out = s.toLowerCase();
  for (var i = 0; i < de.length; i++) {
    out = out.replaceAll(de[i], para[i]);
  }
  return out;
}

class _BuscaSemMesa extends StatefulWidget {
  const _BuscaSemMesa({required this.pessoas, required this.titulo});

  final List<_Pessoa> pessoas;
  final String titulo;

  @override
  State<_BuscaSemMesa> createState() => _BuscaSemMesaState();
}

class _BuscaSemMesaState extends State<_BuscaSemMesa> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final termo = _semAcento(_busca.trim());
    final lista = widget.pessoas
        .where((p) => termo.isEmpty || _semAcento(p.nome).contains(termo))
        .toList();
    final altura = MediaQuery.sizeOf(context).height * 0.72;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: altura,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.titulo, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Pesquisar quem está sem mesa',
                ),
                onChanged: (v) => setState(() => _busca = v),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: lista.isEmpty
                    ? Text(
                        widget.pessoas.isEmpty
                            ? 'Todas as pessoas confirmadas já têm lugar.'
                            : 'Nenhuma pessoa com esse nome.',
                      )
                    : ListView(
                        children: [
                          for (final p in lista)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(p.nome),
                              subtitle: Text(_detalhePessoa(p)),
                              onTap: () => Navigator.pop(context, p.chave),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pessoa {
  _Pessoa({
    required this.chave,
    required this.nome,
    required this.lado,
    required this.rsvp,
    required this.familiaId,
    required this.familiaNome,
    required this.titularNome,
    required this.familiaEhPadrinho,
    required this.confirmado,
    this.padrinhoLabel,
    this.mesa,
    this.cadeira,
  });

  final String chave;
  final String nome;
  final LadoConvidado lado;
  final RsvpStatus rsvp;
  final String familiaId;
  final String familiaNome;
  final String titularNome;
  final bool familiaEhPadrinho;
  final String? padrinhoLabel;
  final bool confirmado;
  final int? mesa;
  final int? cadeira;

  String get meta {
    final bits = <String>['Lado ${lado.label}'];
    if (padrinhoLabel != null) bits.add(padrinhoLabel!);
    bits.add('RSVP ${rsvp.label}');
    if (mesa != null && cadeira != null) {
      bits.add('Mesa $mesa, cadeira $cadeira');
    }
    return bits.join(' · ');
  }
}

String _detalhePessoa(_Pessoa p) {
  final bits = <String>[p.lado.label];
  if (p.titularNome.isNotEmpty && p.titularNome != p.nome) {
    bits.add(p.titularNome);
  }
  if (p.padrinhoLabel != null) bits.add(p.padrinhoLabel!);
  return bits.join(' · ');
}

class SalaoScreen extends StatefulWidget {
  const SalaoScreen({super.key});

  @override
  State<SalaoScreen> createState() => _SalaoScreenState();
}

class _SalaoScreenState extends State<SalaoScreen> {
  final _mesasCtrl = TextEditingController();
  final _cadeirasCtrl = TextEditingController();
  String _filtroPadrinho = 'todos';
  String _filtroLado = 'todos';
  String _filtroFamilia = 'todas';
  bool _agrupar = true;
  bool _busy = false;
  String _buscaLado = '';
  String? _planoAssinatura;
  List<AlocacaoMesa>? _override;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final plano = context.read<AppStore>().planoMesas;
    final assinatura = '${plano.id}:${plano.mesas}:${plano.cadeirasPorMesa}';
    if (_planoAssinatura == assinatura) return;
    _planoAssinatura = assinatura;
    _mesasCtrl.text = plano.mesas > 0 ? '${plano.mesas}' : '';
    _cadeirasCtrl.text =
        plano.cadeirasPorMesa > 0 ? '${plano.cadeirasPorMesa}' : '';
  }

  @override
  void dispose() {
    _mesasCtrl.dispose();
    _cadeirasCtrl.dispose();
    super.dispose();
  }

  List<AlocacaoMesa> _aloc(AppStore store) =>
      _override ?? store.planoMesas.alocacoes;

  List<_Pessoa> _pessoas(AppStore store) {
    final lugar = {for (final a in _aloc(store)) a.chave: a};
    final out = <_Pessoa>[];
    for (final c in store.convidados) {
      Padrinho? vinculo;
      for (final p in store.padrinhos) {
        if (p.convidadoId == c.id) {
          vinculo = p;
          break;
        }
      }
      final familiaNome = c.nomeComParceiro;
      final ehPadrinho = vinculo != null;
      final label = vinculo?.tipo.label;
      void add({
        required String chave,
        required String nome,
        required RsvpStatus rsvp,
        String? padrinhoLabel,
      }) {
        final seat = lugar[chave];
        out.add(
          _Pessoa(
            chave: chave,
            nome: nome,
            lado: c.lado,
            rsvp: rsvp,
            familiaId: c.id,
            familiaNome: familiaNome,
            titularNome: c.nome,
            familiaEhPadrinho: ehPadrinho,
            padrinhoLabel: padrinhoLabel,
            confirmado: rsvp == RsvpStatus.sim,
            mesa: seat?.mesa,
            cadeira: seat?.cadeira,
          ),
        );
      }

      add(
        chave: 'c:${c.id}',
        nome: c.nome,
        rsvp: c.rsvp,
        padrinhoLabel: label,
      );
      for (final a in c.acompanhantesLista) {
        add(
          chave: 'a:${c.id}:${a.id}',
          nome: a.nome,
          rsvp: a.rsvp,
        );
      }
    }
    return out;
  }

  List<_Pessoa> _filtrar(List<_Pessoa> pessoas) {
    return pessoas.where((p) {
      if (_filtroLado != 'todos' && p.lado.dbValue != _filtroLado) return false;
      if (_filtroFamilia != 'todas' && p.familiaId != _filtroFamilia) {
        return false;
      }
      if (_filtroPadrinho == 'sim' && !p.familiaEhPadrinho) return false;
      if (_filtroPadrinho == 'nao' && p.familiaEhPadrinho) return false;
      return true;
    }).toList();
  }

  String _descricao(List<_Pessoa> pessoas, String? familiaNome) {
    final partes = <String>[
      _filtroPadrinho == 'sim'
          ? 'Só padrinhos'
          : _filtroPadrinho == 'nao'
              ? 'Sem padrinhos'
              : 'Padrinhos e convidados',
      _filtroLado == 'todos'
          ? 'Todos os lados'
          : 'Lado ${ladoFromDb(_filtroLado).label}',
    ];
    if (familiaNome != null) partes.add('Família $familiaNome');
    if (_agrupar) partes.add('Agrupado por família');
    return '${partes.join(' · ')} · ${pessoas.length} pessoa(s)';
  }

  Future<void> _imprimir(AppStore store) async {
    final pessoas = _filtrar(_pessoas(store));
    String? familiaNome;
    if (_filtroFamilia != 'todas') {
      for (final p in _pessoas(store)) {
        if (p.familiaId == _filtroFamilia) {
          familiaNome = p.familiaNome;
          break;
        }
      }
    }
    final linhas = pessoas
        .map((p) => (nome: p.nome, meta: p.meta))
        .toList();
    List<GrupoRelatorio>? grupos;
    if (_agrupar) {
      final ordem = <String>[];
      final porId = <String, List<LinhaRelatorio>>{};
      final titulos = <String, String>{};
      for (final p in pessoas) {
        porId.putIfAbsent(p.familiaId, () {
          ordem.add(p.familiaId);
          titulos[p.familiaId] = p.familiaNome;
          return [];
        });
        porId[p.familiaId]!.add((nome: p.nome, meta: p.meta));
      }
      grupos = [
        for (final id in ordem)
          (titulo: titulos[id] ?? 'Família', items: porId[id]!),
      ];
    }
    await RelatorioPdf.imprimirLista(
      titulo: 'Lista de convidados',
      subtitulo: _descricao(pessoas, familiaNome),
      items: _agrupar ? const [] : linhas,
      grupos: grupos,
    );
  }

  Future<void> _imprimirMesas(AppStore store) async {
    final plano = store.planoMesas;
    if (plano.mesas < 1) {
      _aviso('Distribua as mesas antes de imprimir.');
      return;
    }
    final pessoas = _pessoas(store);
    final porChave = {for (final p in pessoas) p.chave: p};
    final grupos = <GrupoRelatorio>[];
    for (var numero = 1; numero <= plano.mesas; numero++) {
      final lado = numero <= plano.ladoMesas.length
          ? ladoFromDb(plano.ladoMesas[numero - 1]).label
          : 'Ambos';
      final daMesa = _aloc(store).where((a) => a.mesa == numero).toList()
        ..sort((a, b) => a.cadeira.compareTo(b.cadeira));
      if (daMesa.isEmpty) continue;
      grupos.add((
        titulo: 'Mesa $numero · $lado',
        items: [
          for (final a in daMesa)
            (
              nome: porChave[a.chave]?.nome ?? 'Convidado',
              meta: [
                'Cadeira ${a.cadeira}',
                if (porChave[a.chave] != null)
                  'Lado ${porChave[a.chave]!.lado.label}',
                if (porChave[a.chave] != null &&
                    porChave[a.chave]!.titularNome.isNotEmpty &&
                    porChave[a.chave]!.titularNome != porChave[a.chave]!.nome)
                  porChave[a.chave]!.titularNome,
                if (porChave[a.chave]?.padrinhoLabel != null)
                  porChave[a.chave]!.padrinhoLabel!,
              ].join(' · '),
            ),
        ],
      ));
    }
    final livres = pessoas.where((p) => p.confirmado && p.mesa == null);
    if (livres.isNotEmpty) {
      grupos.add((
        titulo: 'Sem mesa',
        items: [
          for (final p in livres)
            (
              nome: p.nome,
              meta: [
                'Lado ${p.lado.label}',
                if (p.padrinhoLabel != null) p.padrinhoLabel!,
                'Confirmou presença',
              ].join(' · '),
            ),
        ],
      ));
    }
    if (grupos.isEmpty) {
      _aviso('Ninguém está sentado ainda.');
      return;
    }
    await RelatorioPdf.imprimirLista(
      titulo: 'Repartição de mesas',
      subtitulo:
          '${plano.mesas} mesa(s) · ${plano.cadeirasPorMesa} cadeira(s) · ${_aloc(store).length} pessoa(s) sentada(s)',
      items: const [],
      grupos: grupos,
    );
  }

  List<AlocacaoMesa> _mover(
    List<AlocacaoMesa> lista,
    String chave,
    int? mesa,
    int? cadeira,
  ) {
    final origem = lista.cast<AlocacaoMesa?>().firstWhere(
          (a) => a!.chave == chave,
          orElse: () => null,
        );
    if (mesa != null &&
        cadeira != null &&
        origem != null &&
        origem.mesa == mesa &&
        origem.cadeira == cadeira) {
      return lista;
    }
    final next = lista.where((a) => a.chave != chave).toList();
    if (mesa == null || cadeira == null) return next;
    final ocupante = next.cast<AlocacaoMesa?>().firstWhere(
          (a) => a!.mesa == mesa && a.cadeira == cadeira,
          orElse: () => null,
        );
    if (ocupante != null) {
      next.removeWhere((a) => a.chave == ocupante.chave);
      if (origem != null) {
        next.add(
          AlocacaoMesa(
            chave: ocupante.chave,
            mesa: origem.mesa,
            cadeira: origem.cadeira,
          ),
        );
      }
    }
    next.add(AlocacaoMesa(chave: chave, mesa: mesa, cadeira: cadeira));
    return next;
  }

  Future<void> _soltar(String chave, int? mesa, int? cadeira) async {
    if (_busy) return;
    final store = context.read<AppStore>();
    final atual = _aloc(store);
    final next = _mover(atual, chave, mesa, cadeira);
    if (identical(next, atual)) return;
    final plano = store.planoMesas;
    setState(() {
      _override = next;
      _busy = true;
    });
    final err = await store.salvarPlanoMesas(
      PlanoMesas(
        id: plano.id,
        mesas: plano.mesas,
        cadeirasPorMesa: plano.cadeirasPorMesa,
        alocacoes: next,
        ladoMesas: plano.ladoMesas,
      ),
    );
    if (!mounted) return;
    setState(() {
      _override = null;
      _busy = false;
    });
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _distribuir() async {
    final store = context.read<AppStore>();
    final mesas = int.tryParse(_mesasCtrl.text.trim()) ?? 0;
    final cadeiras = int.tryParse(_cadeirasCtrl.text.trim()) ?? 0;
    if (mesas < 1 || mesas > 100) {
      _aviso('Informe de 1 a 100 mesas.');
      return;
    }
    if (cadeiras < 1 || cadeiras > 40) {
      _aviso('Informe de 1 a 40 cadeiras por mesa.');
      return;
    }
    if (_aloc(store).isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Redistribuir'),
          content: const Text(
            'Redistribuir substitui os lugares que você já ajustou.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _busy = true);
    final err = await store.distribuirMesas(mesas, cadeiras);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      _aviso(err);
    } else {
      _aviso('Lugares distribuídos.');
    }
  }

  Future<void> _limpar() async {
    final store = context.read<AppStore>();
    if (_aloc(store).isEmpty || _busy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar lugares'),
        content: const Text(
          'Isso tira todo mundo das cadeiras. As mesas continuam e você pode preencher de novo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final plano = store.planoMesas;
    setState(() {
      _override = const [];
      _busy = true;
    });
    final err = await store.salvarPlanoMesas(
      PlanoMesas(
        id: plano.id,
        mesas: plano.mesas,
        cadeirasPorMesa: plano.cadeirasPorMesa,
        alocacoes: const [],
        ladoMesas: plano.ladoMesas,
      ),
    );
    if (!mounted) return;
    setState(() {
      _override = null;
      _busy = false;
    });
    if (err != null) {
      _aviso(err);
    } else {
      _aviso('Lugares limpos.');
    }
  }

  Future<void> _escolherParaCadeira(
    int mesa,
    int cadeira,
    List<_Pessoa> semMesa,
  ) async {
    final chave = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _BuscaSemMesa(
        pessoas: semMesa,
        titulo: 'Mesa $mesa, cadeira $cadeira',
      ),
    );
    if (chave != null) await _soltar(chave, mesa, cadeira);
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pessoas = _pessoas(store);
    final familias = <String, String>{};
    for (final p in pessoas) {
      familias.putIfAbsent(p.familiaId, () => p.familiaNome);
    }
    final familiaIds = familias.keys.toList()
      ..sort(
        (a, b) => (familias[a] ?? '').compareTo(familias[b] ?? ''),
      );

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      'Salão',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Convidados'),
                Tab(text: 'Repartição'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _lista(store, pessoas, familias, familiaIds),
                  _reparticao(store, pessoas),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lista(
    AppStore store,
    List<_Pessoa> pessoas,
    Map<String, String> familias,
    List<String> familiaIds,
  ) {
    final filtradas = _filtrar(pessoas);
    final grupos = <String, List<_Pessoa>>{};
    for (final p in filtradas) {
      grupos.putIfAbsent(p.familiaId, () => []).add(p);
    }
    final ordem = grupos.keys.toList()
      ..sort(
        (a, b) => (familias[a] ?? '').compareTo(familias[b] ?? ''),
      );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        DropdownButtonFormField<String>(
          initialValue: _filtroPadrinho,
          decoration: const InputDecoration(labelText: 'Padrinhos'),
          items: const [
            DropdownMenuItem(value: 'todos', child: Text('Todos')),
            DropdownMenuItem(value: 'sim', child: Text('Só padrinhos')),
            DropdownMenuItem(value: 'nao', child: Text('Sem padrinhos')),
          ],
          onChanged: (v) => setState(() => _filtroPadrinho = v ?? 'todos'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _filtroLado,
          decoration: const InputDecoration(labelText: 'Lado'),
          items: const [
            DropdownMenuItem(value: 'todos', child: Text('Todos')),
            DropdownMenuItem(value: 'noivo', child: Text('Noivo')),
            DropdownMenuItem(value: 'noiva', child: Text('Noiva')),
            DropdownMenuItem(value: 'ambos', child: Text('Ambos')),
          ],
          onChanged: (v) => setState(() => _filtroLado = v ?? 'todos'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          key: ValueKey('familia-$_filtroFamilia-${familiaIds.length}'),
          initialValue: familiaIds.contains(_filtroFamilia) ||
                  _filtroFamilia == 'todas'
              ? _filtroFamilia
              : 'todas',
          decoration: const InputDecoration(labelText: 'Família'),
          items: [
            const DropdownMenuItem(value: 'todas', child: Text('Todas')),
            for (final id in familiaIds)
              DropdownMenuItem(value: id, child: Text(familias[id] ?? '')),
          ],
          onChanged: (v) => setState(() => _filtroFamilia = v ?? 'todas'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Agrupar por família'),
          value: _agrupar,
          onChanged: (v) => setState(() => _agrupar = v),
        ),
        FilledButton.icon(
          onPressed: () => _imprimir(store),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Imprimir / PDF'),
        ),
        const SizedBox(height: 8),
        Text(
          _descricao(
            filtradas,
            _filtroFamilia == 'todas' ? null : familias[_filtroFamilia],
          ),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        if (filtradas.isEmpty)
          const Text('Nenhuma pessoa nesta seleção.')
        else if (_agrupar)
          for (final id in ordem) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                familias[id] ?? 'Família',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final p in grupos[id]!) _tile(p),
          ]
        else
          for (final p in filtradas) _tile(p),
      ],
    );
  }

  Widget _tile(_Pessoa p) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(p.nome),
      subtitle: Text(p.meta),
    );
  }

  Widget _reparticao(AppStore store, List<_Pessoa> pessoas) {
    final plano = store.planoMesas;
    final confirmados = pessoas.where((p) => p.confirmado).toList();
    final semMesa = confirmados.where((p) => p.mesa == null).toList();
    final termo = _semAcento(_buscaLado.trim());
    final semMesaLado = semMesa
        .where((p) => termo.isEmpty || _semAcento(p.nome).contains(termo))
        .toList();
    final porChave = {for (final p in pessoas) p.chave: p};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Só quem confirmou presença ganha cadeira. A noiva fica nas primeiras mesas e o noivo nas seguintes.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mesasCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Mesas',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _cadeirasCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cadeiras',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _busy ? null : _distribuir,
                child: Text(
                  _aloc(store).isEmpty ? 'Distribuir' : 'Redistribuir',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy || _aloc(store).isEmpty ? null : _limpar,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Limpar lugares'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _imprimirMesas(store),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Imprimir mesas'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 188,
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (_) => !_busy,
                  onAcceptWithDetails: (d) => _soltar(d.data, null, null),
                  builder: (context, candidate, _) {
                    return ColoredBox(
                      color: candidate.isEmpty
                          ? Colors.transparent
                          : AppColors.primary.withValues(alpha: 0.08),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 0, 8, 16),
                        children: [
                          Text(
                            'Sem mesa',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quem já sentou sai da lista. Pesquise e arraste, ou solte aqui para tirar da mesa.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.muted),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: const InputDecoration(
                              hintText: 'Pesquisar nome',
                              isDense: true,
                            ),
                            onChanged: (v) => setState(() => _buscaLado = v),
                          ),
                          const SizedBox(height: 8),
                          if (confirmados.isEmpty)
                            const Text('Ninguém confirmou presença ainda.')
                          else if (semMesa.isEmpty)
                            const Text(
                              'Todas as pessoas confirmadas já têm lugar.',
                            )
                          else if (semMesaLado.isEmpty)
                            const Text('Nenhuma pessoa com esse nome.')
                          else
                            for (final p in semMesaLado)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Draggable<String>(
                                  data: p.chave,
                                  feedback: _feedback(p.nome),
                                  childWhenDragging: Opacity(
                                    opacity: 0.35,
                                    child: _chip(p),
                                  ),
                                  child: _chip(p),
                                ),
                              ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: plano.mesas < 1
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Informe as mesas e toque em Distribuir.',
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(12, 0, 16, 16),
                        children: [
                          for (var n = 1; n <= plano.mesas; n++)
                            _mesaCard(
                              numero: n,
                              lado: n - 1 < plano.ladoMesas.length
                                  ? plano.ladoMesas[n - 1]
                                  : 'ambos',
                              cadeiras: plano.cadeirasPorMesa,
                              alocacoes: _aloc(store),
                              porChave: porChave,
                              semMesa: semMesa,
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(_Pessoa p) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.nome,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              _detalhePessoa(p),
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedback(String nome) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(nome, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _mesaCard({
    required int numero,
    required String lado,
    required int cadeiras,
    required List<AlocacaoMesa> alocacoes,
    required Map<String, _Pessoa> porChave,
    required List<_Pessoa> semMesa,
  }) {
    final cor = switch (lado) {
      'noiva' => AppColors.warning,
      'noivo' => AppColors.success,
      _ => AppColors.primary,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Mesa $numero',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    ladoFromDb(lado).label,
                    style: TextStyle(
                      color: cor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var c = 1; c <= cadeiras; c++)
              _cadeira(
                numero: numero,
                cadeira: c,
                alocacoes: alocacoes,
                porChave: porChave,
                semMesa: semMesa,
              ),
          ],
        ),
      ),
    );
  }

  Widget _cadeira({
    required int numero,
    required int cadeira,
    required List<AlocacaoMesa> alocacoes,
    required Map<String, _Pessoa> porChave,
    required List<_Pessoa> semMesa,
  }) {
    AlocacaoMesa? aloc;
    for (final a in alocacoes) {
      if (a.mesa == numero && a.cadeira == cadeira) {
        aloc = a;
        break;
      }
    }
    final pessoa = aloc == null ? null : porChave[aloc.chave];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DragTarget<String>(
        onWillAcceptWithDetails: (_) => !_busy,
        onAcceptWithDetails: (d) => _soltar(d.data, numero, cadeira),
        builder: (context, candidate, _) {
          final nome = pessoa?.nome;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: candidate.isEmpty
                  ? AppColors.surface
                  : AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: nome == null
                ? InkWell(
                    onTap: _busy
                        ? null
                        : () => _escolherParaCadeira(numero, cadeira, semMesa),
                    child: Text(
                      'Cadeira $cadeira · Toque para escolher',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Draggable<String>(
                          data: pessoa!.chave,
                          feedback: _feedback(nome),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cadeira $cadeira · $nome',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _detalhePessoa(pessoa!),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _soltar(pessoa.chave, null, null),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Tirar'),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
