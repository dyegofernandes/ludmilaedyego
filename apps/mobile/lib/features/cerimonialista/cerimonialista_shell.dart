import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets/brand_widgets.dart';
import '../../data/app_store.dart';
import '../convidados/convidados_screen.dart';
import '../fornecedores/fornecedores_screen.dart';
import '../padrinhos/padrinhos_screen.dart';
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
      const FornecedoresScreen(embedded: true),
      const TarefasScreen(embedded: true, gestaoMode: true),
      const ConvidadosScreen(embedded: true),
      const PadrinhosScreen(embedded: true),
      const _MaisTab(),
    ];

    return Scaffold(
      body: SoftBackground(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Fornecedores',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Tarefas',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Convidados',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Padrinhos',
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

class _MaisTab extends StatelessWidget {
  const _MaisTab();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final items = [
      ('Salão', Icons.table_restaurant_outlined, '/salao'),
      ('Evento', Icons.celebration_outlined, '/evento'),
      ('Fotos', Icons.photo_library_outlined, '/fotos'),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          BrandBar(
            config: store.config,
            subtitle: 'Olá, ${store.currentUser?.nome ?? 'cerimonialista'}',
            trailing: IconButton(
              onPressed: () async {
                await store.logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout),
            ),
          ),
          const SizedBox(height: 20),
          Text('Mais', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Salão, evento e fotos do casamento.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.muted),
          ),
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
