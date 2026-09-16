import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/brand_widgets.dart';
import '../../core/widgets/evento_info.dart';
import '../../data/app_store.dart';

class EventoScreen extends StatelessWidget {
  const EventoScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final body = SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            children: [
              if (!embedded)
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                ),
              Expanded(
                child: Text(
                  'Evento',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              if (embedded)
                IconButton(
                  onPressed: () async {
                    await store.logout();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const EventoInfoSection(),
        ],
      ),
    );

    if (embedded) return body;
    return Scaffold(body: SoftBackground(child: body));
  }
}
