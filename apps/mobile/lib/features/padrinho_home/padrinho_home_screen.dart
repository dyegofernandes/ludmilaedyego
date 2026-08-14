import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets/brand_widgets.dart';
import '../../core/widgets/cadastro_convidado.dart';
import '../../core/widgets/evento_info.dart';
import '../../core/widgets/rsvp_confirm.dart';
import '../../data/app_store.dart';
import '../../models/models.dart';

class PadrinhoHomeScreen extends StatelessWidget {
  const PadrinhoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final minhas = store.minhasTarefasPadrinho;

    return Scaffold(
      body: SoftBackground(
        capaUrl: store.config.capaUrl,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              BrandBar(
                config: store.config,
                subtitle: 'Padrinho',
                trailing: IconButton(
                  onPressed: () async {
                    await store.logout();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout),
                ),
              ),
              const SizedBox(height: 24),
              const EventoInfoSection(),
              const SizedBox(height: 28),
              if (store.meuConvidado != null)
                RsvpGrupoBlock(
                  convidado: store.meuConvidado!,
                  onSelect: (s, {acompanhanteId}) async {
                    await store.atualizarRsvp(
                      s,
                      acompanhanteId: acompanhanteId,
                    );
                  },
                ),
              const SizedBox(height: 28),
              const CadastroConvidadoBlock(),
              const SizedBox(height: 28),
              Text(
                'Solicitações dos noivos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (minhas.isEmpty)
                Text(
                  'Nenhuma tarefa atribuída a você.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.muted),
                )
              else
                ...minhas.take(3).map(
                      (t) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.titulo),
                        subtitle: Text(t.status.label),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/minhas-tarefas'),
                      ),
                    ),
              const SizedBox(height: 8),
              GlassMenuTile(
                icon: Icons.task_alt,
                label: 'Ver todas as tarefas',
                onTap: () => context.push('/minhas-tarefas'),
              ),
              GlassMenuTile(
                icon: Icons.card_giftcard_outlined,
                label: 'Lista de presentes',
                onTap: () => context.push('/presentes-guest'),
              ),
              GlassMenuTile(
                icon: Icons.photo_library_outlined,
                label: 'Fotos',
                onTap: () => context.push('/fotos-guest'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
