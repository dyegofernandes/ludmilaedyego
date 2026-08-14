import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/brand_widgets.dart';
import '../../core/widgets/cadastro_convidado.dart';
import '../../core/widgets/evento_info.dart';
import '../../core/widgets/rsvp_confirm.dart';
import '../../data/app_store.dart';
import '../../models/models.dart';

class ConvidadoHomeScreen extends StatelessWidget {
  const ConvidadoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    return Scaffold(
      body: SoftBackground(
        capaUrl: store.config.capaUrl,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              BrandBar(
                config: store.config,
                subtitle: 'Convidado',
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
                    final err = await store.atualizarRsvp(
                      s,
                      acompanhanteId: acompanhanteId,
                    );
                    if (context.mounted && err != null) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(err)));
                    }
                  },
                ),
              const SizedBox(height: 28),
              const CadastroConvidadoBlock(),
              const SizedBox(height: 28),
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
