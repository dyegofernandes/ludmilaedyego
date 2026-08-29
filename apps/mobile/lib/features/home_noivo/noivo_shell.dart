import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/widgets/brand_widgets.dart';
import '../../data/app_store.dart';
import '../../models/models.dart';
import '../agenda/agenda_screen.dart';
import '../gastos/gastos_screen.dart';
import '../tarefas/tarefas_screen.dart';

class NoivoShell extends StatefulWidget {
  const NoivoShell({super.key});

  @override
  State<NoivoShell> createState() => _NoivoShellState();
}

class _NoivoShellState extends State<NoivoShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _NoivoHomeTab(),
      const GastosScreen(embedded: true),
      const TarefasScreen(embedded: true),
      const AgendaScreen(embedded: true),
      const _MaisTab(),
    ];

    return Scaffold(
      body: SoftBackground(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Gastos',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Tarefas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Mais',
          ),
        ],
      ),
    );
  }
}

class _NomeItem {
  const _NomeItem(this.nome, [this.meta]);
  final String nome;
  final String? meta;
}

class _ResumoFiltro {
  const _ResumoFiltro(this.key, this.label, this.items);
  final String key;
  final String label;
  final List<_NomeItem> items;
}

List<_ResumoFiltro> _buildResumoFiltros(AppStore store) {
  final pessoas = <({String nome, RsvpStatus rsvp, bool crianca, String detalhe})>[];
  for (final c in store.convidados) {
    pessoas.add((
      nome: c.nome,
      rsvp: c.rsvp,
      crianca: c.ehCrianca,
      detalhe: c.ehCrianca ? 'Criança' : 'Titular',
    ));
    for (final a in c.acompanhantesLista) {
      final kid = a.tipo.isCrianca;
      pessoas.add((
        nome: a.nome,
        rsvp: a.rsvp,
        crianca: kid,
        detalhe:
            'Acompanhante de ${c.nome}${kid ? ' · criança' : a.tipo == TipoAcompanhante.esposa ? ' · esposo(a)' : ''}',
      ));
    }
  }

  List<_NomeItem> pessoasWhere(bool Function(({String nome, RsvpStatus rsvp, bool crianca, String detalhe}) p) pred) =>
      pessoas
          .where(pred)
          .map((p) => _NomeItem(p.nome, '${p.rsvp.label} · ${p.detalhe}'))
          .toList();

  final gastosAtivos =
      store.gastos.where((g) => g.status != GastoStatus.cancelado).toList();
  final hoje = store.compromissosDoDia(DateTime.now());

  return [
    _ResumoFiltro(
      'previsto',
      'Gastos previstos',
      gastosAtivos
          .map((g) => _NomeItem(g.descricao, '${formatMoney(g.valorPrevisto)} · ${g.categoria}'))
          .toList(),
    ),
    _ResumoFiltro(
      'pago',
      'Gastos pagos',
      gastosAtivos
          .where((g) => g.status == GastoStatus.pago)
          .map((g) => _NomeItem(g.descricao, formatMoney(g.valorReal ?? g.valorPrevisto)))
          .toList(),
    ),
    _ResumoFiltro(
      'restante',
      'Gastos pendentes',
      gastosAtivos
          .where((g) => g.status == GastoStatus.pendente)
          .map((g) => _NomeItem(g.descricao, formatMoney(g.valorPrevisto)))
          .toList(),
    ),
    _ResumoFiltro(
      'confirmados',
      'Pessoas confirmadas (RSVP Sim)',
      pessoasWhere((p) => p.rsvp == RsvpStatus.sim),
    ),
    _ResumoFiltro(
      'total',
      'Todas as pessoas',
      pessoasWhere((_) => true),
    ),
    _ResumoFiltro(
      'adultos',
      'Adultos',
      pessoasWhere((p) => !p.crianca),
    ),
    _ResumoFiltro(
      'criancas',
      'Crianças',
      pessoasWhere((p) => p.crianca),
    ),
    _ResumoFiltro(
      'confAdultos',
      'Confirmados · adultos',
      pessoasWhere((p) => p.rsvp == RsvpStatus.sim && !p.crianca),
    ),
    _ResumoFiltro(
      'confCriancas',
      'Confirmados · crianças',
      pessoasWhere((p) => p.rsvp == RsvpStatus.sim && p.crianca),
    ),
    _ResumoFiltro(
      'rsvpNao',
      'RSVP · Não',
      pessoasWhere((p) => p.rsvp == RsvpStatus.nao),
    ),
    _ResumoFiltro(
      'rsvpTalvez',
      'RSVP · Talvez',
      pessoasWhere((p) => p.rsvp == RsvpStatus.talvez),
    ),
    _ResumoFiltro(
      'rsvpPend',
      'RSVP · Pendente',
      pessoasWhere((p) => p.rsvp == RsvpStatus.pendente),
    ),
    _ResumoFiltro(
      'tarefas',
      'Tarefas pendentes',
      store.tarefas
          .where((t) => t.status == TarefaStatus.pendente)
          .map((t) => _NomeItem(t.titulo, t.descricao))
          .toList(),
    ),
    _ResumoFiltro(
      'agendaHoje',
      'Compromissos hoje',
      hoje.map((c) => _NomeItem(c.titulo, c.local)).toList(),
    ),
    _ResumoFiltro(
      'presentes',
      'Presentes reservados',
      store.presentes
          .where((p) => p.reservado && p.ativo)
          .map((p) {
            final quem = store.convidadoById(p.reservadoPorConvidadoId);
            return _NomeItem(
              p.nome,
              quem != null ? 'Reservado por ${quem.nome}' : 'Reservado',
            );
          })
          .toList(),
    ),
  ];
}

Future<void> _openResumoGrid(
  BuildContext context,
  List<_ResumoFiltro> filtros,
  String initialKey,
) async {
  var key = initialKey;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final atual = filtros.firstWhere(
            (f) => f.key == key,
            orElse: () => filtros.first,
          );
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(ctx).height * 0.78,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      atual.label,
                      style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                            color: AppColors.primaryDark,
                          ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: key,
                      decoration: const InputDecoration(labelText: 'Filtrar'),
                      items: [
                        for (final f in filtros)
                          DropdownMenuItem(
                            value: f.key,
                            child: Text('${f.label} (${f.items.length})'),
                          ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setLocal(() => key = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      atual.items.isEmpty
                          ? 'Nenhum item nesta seleção.'
                          : '${atual.items.length} item(ns)',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.55,
                        ),
                        itemCount: atual.items.length,
                        itemBuilder: (_, i) {
                          final item = atual.items[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.nome,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                if (item.meta != null && item.meta!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.meta!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(ctx)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppColors.muted),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _NoivoHomeTab extends StatelessWidget {
  const _NoivoHomeTab();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final filtros = _buildResumoFiltros(store);
    final count = (String k) =>
        filtros.firstWhere((f) => f.key == k, orElse: () => filtros.first).items.length;

    final rsvpNao = store.convidados.fold<int>(0, (a, c) {
      var n = c.rsvp == RsvpStatus.nao ? 1 : 0;
      n += c.acompanhantesLista.where((x) => x.rsvp == RsvpStatus.nao).length;
      return a + n;
    });
    final rsvpTalvez = store.convidados.fold<int>(0, (a, c) {
      var n = c.rsvp == RsvpStatus.talvez ? 1 : 0;
      n += c.acompanhantesLista.where((x) => x.rsvp == RsvpStatus.talvez).length;
      return a + n;
    });
    final rsvpPend = store.convidados.fold<int>(0, (a, c) {
      var n = c.rsvp == RsvpStatus.pendente ? 1 : 0;
      n += c.acompanhantesLista.where((x) => x.rsvp == RsvpStatus.pendente).length;
      return a + n;
    });

    void open(String key) => _openResumoGrid(context, filtros, key);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          BrandBar(
            config: store.config,
            subtitle: store.config.dataCerimonia != null
                ? formatDateTime(store.config.dataCerimonia)
                : 'Acesso total',
            trailing: IconButton(
              onPressed: () async {
                await store.logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout),
            ),
          ),
          const SizedBox(height: 22),
          Text('Resumo', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricCard(
                label: 'Previsto',
                value: formatMoney(store.totalPrevisto),
                onTap: () => open('previsto'),
              ),
              _MetricCard(
                label: 'Pago',
                value: formatMoney(store.totalPago),
                onTap: () => open('pago'),
              ),
              _MetricCard(
                label: 'Restante',
                value: formatMoney(store.totalRestante),
                onTap: () => open('restante'),
              ),
              _MetricCard(
                label: 'Confirmados',
                value: '${store.totalConfirmadosPessoas}',
                onTap: () => open('confirmados'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SummaryTile(
            label: 'Pessoas confirmadas',
            value: '${store.totalConfirmadosPessoas}',
            onTap: () => open('confirmados'),
          ),
          _SummaryTile(
            label: 'Total de pessoas',
            value: '${store.totalConvidadosPessoas}',
            onTap: () => open('total'),
          ),
          _SummaryTile(
            label: 'Adultos',
            value: '${store.totalAdultos}',
            onTap: () => open('adultos'),
          ),
          _SummaryTile(
            label: 'Crianças',
            value: '${store.totalCriancas}',
            onTap: () => open('criancas'),
          ),
          _SummaryTile(
            label: 'Confirmados · adultos',
            value: '${store.totalConfirmadosAdultos}',
            onTap: () => open('confAdultos'),
          ),
          _SummaryTile(
            label: 'Confirmados · crianças',
            value: '${store.totalConfirmadosCriancas}',
            onTap: () => open('confCriancas'),
          ),
          _SummaryTile(
            label: 'RSVP · Não',
            value: '$rsvpNao',
            onTap: () => open('rsvpNao'),
          ),
          _SummaryTile(
            label: 'RSVP · Talvez',
            value: '$rsvpTalvez',
            onTap: () => open('rsvpTalvez'),
          ),
          _SummaryTile(
            label: 'RSVP · Pendente',
            value: '$rsvpPend',
            onTap: () => open('rsvpPend'),
          ),
          _SummaryTile(
            label: 'Tarefas pendentes',
            value: '${count('tarefas')}',
            onTap: () => open('tarefas'),
          ),
          _SummaryTile(
            label: 'Compromissos hoje',
            value: '${count('agendaHoje')}',
            onTap: () => open('agendaHoje'),
          ),
          _SummaryTile(
            label: 'Presentes reservados',
            value: '${count('presentes')}',
            onTap: () => open('presentes'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 52) / 2;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: width.clamp(140, 220),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.primary.withValues(alpha: 0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MaisTab extends StatelessWidget {
  const _MaisTab();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Convidados', Icons.people_outline, '/convidados'),
      ('Despedida de solteiro', Icons.celebration_outlined, '/despedida'),
      ('Cerimonialista', Icons.key_outlined, '/tokens'),
      ('Presentes', Icons.card_giftcard_outlined, '/presentes'),
      ('Fotos', Icons.photo_library_outlined, '/fotos'),
      ('Padrinhos', Icons.favorite_outline, '/padrinhos'),
      ('Configurações', Icons.settings_outlined, '/configuracoes'),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text('Mais', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          ...items.map(
            (e) => GlassMenuTile(
              icon: e.$2,
              label: e.$1,
              onTap: () => context.push(e.$3),
            ),
          ),
        ],
      ),
    );
  }
}
