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

class _NoivoHomeTab extends StatelessWidget {
  const _NoivoHomeTab();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pendentes = store.tarefas
        .where((t) => t.status == TarefaStatus.pendente)
        .length;
    final reservados =
        store.presentes.where((p) => p.reservado && p.ativo).length;
    final agendaHoje = store.compromissosDoDia(DateTime.now()).length;

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
              ),
              _MetricCard(
                label: 'Pago',
                value: formatMoney(store.totalPago),
              ),
              _MetricCard(
                label: 'Restante',
                value: formatMoney(store.totalRestante),
              ),
              _MetricCard(
                label: 'Confirmados',
                value: '${store.totalConfirmadosPessoas}',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SummaryTile(
            label: 'Pessoas confirmadas',
            value: '${store.totalConfirmadosPessoas}',
          ),
          _SummaryTile(
            label: 'Total de pessoas',
            value: '${store.totalConvidadosPessoas}',
          ),
          _SummaryTile(
            label: 'Adultos',
            value: '${store.totalAdultos}',
          ),
          _SummaryTile(
            label: 'Crianças',
            value: '${store.totalCriancas}',
          ),
          _SummaryTile(
            label: 'Tarefas pendentes',
            value: '$pendentes',
          ),
          _SummaryTile(
            label: 'Compromissos hoje',
            value: '$agendaHoje',
          ),
          _SummaryTile(
            label: 'Presentes reservados',
            value: '$reservados',
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 52) / 2;
    return Container(
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
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
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
