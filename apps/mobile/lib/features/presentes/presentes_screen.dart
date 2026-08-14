import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/widgets/brand_widgets.dart';
import '../../data/app_store.dart';
import '../../models/models.dart';

class PresentesScreen extends StatelessWidget {
  const PresentesScreen({super.key, this.guestMode = false});

  final bool guestMode;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final list = store.presentes.where((p) => guestMode ? p.ativo : true).toList();
    final meuId = store.meuConvidado?.id;

    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(
                        'Presentes',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    if (!guestMode)
                      IconButton(
                        onPressed: () => _form(context),
                        icon: const Icon(Icons.add),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = list[i];
                    final minhaReserva = p.reservadoPorConvidadoId == meuId;
                    String statusLabel;
                    if (guestMode) {
                      if (!p.reservado) {
                        statusLabel = 'Disponível';
                      } else if (minhaReserva) {
                        statusLabel = 'Você reservou';
                      } else {
                        statusLabel = 'Reservado';
                      }
                    } else {
                      if (!p.reservado) {
                        statusLabel = 'Livre';
                      } else {
                        final nome = store
                                .convidadoById(p.reservadoPorConvidadoId!)
                                ?.nome ??
                            '—';
                        statusLabel = 'Reservado por $nome';
                      }
                    }

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(p.nome),
                      subtitle: Text(
                        [
                          if (p.valorEstimado != null)
                            formatMoney(p.valorEstimado!),
                          statusLabel,
                        ].join(' · '),
                      ),
                      trailing: guestMode
                          ? _guestActions(context, store, p, minhaReserva)
                          : IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _form(context, p),
                            ),
                      onTap: p.link == null
                          ? null
                          : () => launchUrl(Uri.parse(p.link!)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guestActions(
    BuildContext context,
    AppStore store,
    Presente p,
    bool minhaReserva,
  ) {
    if (!p.reservado) {
      return TextButton(
        onPressed: () async {
          final err = await store.reservarPresente(p.id);
          if (context.mounted && err != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(err)));
          }
        },
        child: const Text('Vou presentear'),
      );
    }
    if (minhaReserva) {
      return TextButton(
        onPressed: () async {
          final err = await store.cancelarReservaPresente(p.id);
          if (context.mounted && err != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(err)));
          }
        },
        child: const Text('Cancelar'),
      );
    }
    return const StatusChip(label: 'Reservado', color: AppColors.muted);
  }

  Future<void> _form(BuildContext context, [Presente? existing]) async {
    final store = context.read<AppStore>();
    final nome = TextEditingController(text: existing?.nome ?? '');
    final desc = TextEditingController(text: existing?.descricao ?? '');
    final link = TextEditingController(text: existing?.link ?? '');
    final valor = TextEditingController(
      text: existing?.valorEstimado?.toString() ?? '',
    );
    var ativo = existing?.ativo ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Novo presente' : 'Editar presente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nome,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: desc,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: link,
                  decoration: const InputDecoration(labelText: 'Link'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: valor,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Valor estimado'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ativo'),
                  value: ativo,
                  onChanged: (v) => setLocal(() => ativo = v),
                ),
              ],
            ),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () async {
                  await store.removerPresente(existing.id);
                  if (ctx.mounted) Navigator.pop(ctx, false);
                },
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            if (existing?.reservado == true)
              TextButton(
                onPressed: () async {
                  await store.cancelarReservaPresente(existing!.id);
                  if (ctx.mounted) Navigator.pop(ctx, false);
                },
                child: const Text('Liberar reserva'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    final p = Presente(
      id: existing?.id ?? store.novoId(),
      nome: nome.text.trim(),
      descricao: desc.text.trim().isEmpty ? null : desc.text.trim(),
      link: link.text.trim().isEmpty ? null : link.text.trim(),
      valorEstimado: double.tryParse(valor.text.replaceAll(',', '.')),
      ativo: ativo,
      reservadoPorConvidadoId: existing?.reservadoPorConvidadoId,
      reservadoEm: existing?.reservadoEm,
      imagemUrl: existing?.imagemUrl,
    );
    final err = await store.upsertPresente(p);
    if (context.mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }
}
