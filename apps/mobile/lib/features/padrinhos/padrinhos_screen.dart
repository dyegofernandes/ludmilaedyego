import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets/brand_widgets.dart';
import '../../data/app_store.dart';
import '../../models/models.dart';

class PadrinhosScreen extends StatelessWidget {
  const PadrinhosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
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
                        'Padrinhos',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _vincular(context),
                      icon: const Icon(Icons.person_add_alt),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: store.padrinhos.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = store.padrinhos[i];
                    final nome =
                        store.convidadoById(p.convidadoId)?.nome ?? '—';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(nome),
                      subtitle: Text(
                        [
                          p.tipo.label,
                          if (p.papel != null && p.papel!.isNotEmpty) p.papel!,
                        ].join(' · '),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.link_off, color: AppColors.danger),
                        onPressed: () => store.removerPadrinho(p.id),
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
  }

  Future<void> _vincular(BuildContext context) async {
    final store = context.read<AppStore>();
    final disponiveis = store.convidados
        .where((c) => !store.padrinhos.any((p) => p.convidadoId == c.id))
        .toList();
    if (disponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos os convidados já estão vinculados.')),
      );
      return;
    }

    String? convidadoId = disponiveis.first.id;
    var tipo = TipoPadrinho.padrinho;
    final papel = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Vincular padrinho'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: convidadoId,
                decoration: const InputDecoration(labelText: 'Convidado'),
                items: disponiveis
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.nome),
                        ))
                    .toList(),
                onChanged: (v) => setLocal(() => convidadoId = v),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<TipoPadrinho>(
                initialValue: tipo,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: TipoPadrinho.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        ))
                    .toList(),
                onChanged: (v) => setLocal(() => tipo = v!),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: papel,
                decoration:
                    const InputDecoration(labelText: 'Papel (ex.: alianças)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Vincular'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || convidadoId == null) return;
    final err = await store.vincularPadrinho(
      convidadoId: convidadoId!,
      tipo: tipo,
      papel: papel.text.trim().isEmpty ? null : papel.text.trim(),
    );
    if (context.mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }
}
