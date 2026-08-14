import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/widgets/brand_widgets.dart';
import '../../core/widgets/evento_info.dart';
import '../../data/app_store.dart';
import '../../models/models.dart';
import '../agenda/agenda_screen.dart';
import '../tarefas/tarefas_screen.dart';

class CerimonialistaShell extends StatefulWidget {
  const CerimonialistaShell({super.key});

  @override
  State<CerimonialistaShell> createState() => _CerimonialistaShellState();
}

class _CerimonialistaShellState extends State<CerimonialistaShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _CerimonialHomeTab(),
      const TarefasScreen(embedded: true, gestaoMode: true),
      const AgendaScreen(embedded: true),
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
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Tarefas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
        ],
      ),
    );
  }
}

class _CerimonialHomeTab extends StatelessWidget {
  const _CerimonialHomeTab();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final paraNoivos = store.tarefas
        .where((t) =>
            t.destino == DestinoTarefa.noivos &&
            t.status != TarefaStatus.feito &&
            t.status != TarefaStatus.cancelado)
        .length;
    final proximos = store.compromissosProximos();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          BrandBar(
            config: store.config,
            subtitle:
                'Olá, ${store.currentUser?.nome ?? 'cerimonialista'}',
            trailing: IconButton(
              onPressed: () async {
                await store.logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Crie tarefas para os noivos e marque compromissos na agenda.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          const EventoInfoSection(),
          const SizedBox(height: 24),
          _StatRow(
            label: 'Tarefas abertas para os noivos',
            value: '$paraNoivos',
          ),
          _StatRow(
            label: 'Compromissos nos próximos 14 dias',
            value: '${proximos.length}',
          ),
          const SizedBox(height: 28),
          Text(
            'Próximos compromissos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (proximos.isEmpty)
            Text(
              'Nenhum compromisso marcado.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.muted),
            )
          else
            ...proximos.take(5).map(
                  (c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(c.titulo),
                    subtitle: Text(
                      [
                        formatDateTime(c.inicio),
                        if (c.local != null) c.local!,
                      ].join(' · '),
                    ),
                  ),
                ),
          const SizedBox(height: 16),
          Text(
            'Tarefas sugeridas para os noivos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...store.tarefas
              .where((t) => t.destino == DestinoTarefa.noivos)
              .take(5)
              .map(
                (t) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.titulo),
                  subtitle: Text(t.status.label),
                  trailing: StatusChip(
                    label: t.prioridade.label,
                    color: t.prioridade == Prioridade.alta
                        ? AppColors.accent
                        : AppColors.primary,
                  ),
                ),
              ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.celebration_outlined),
            title: const Text('Despedida de solteiro'),
            subtitle: const Text('Participantes do noivo e da noiva'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/despedida'),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
