import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/widgets/brand_widgets.dart';
import '../../data/app_store.dart';
import '../../models/models.dart';

class GastosScreen extends StatelessWidget {
  const GastosScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final body = SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                if (!embedded)
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                Expanded(
                  child: Text(
                    'Gastos',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => _form(context),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _TotalRow('Previsto', formatMoney(store.totalPrevisto)),
                _TotalRow('Pago', formatMoney(store.totalPago)),
                _TotalRow('Restante', formatMoney(store.totalRestante)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: store.gastos.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final g = store.gastos[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(g.descricao),
                  subtitle: Text(
                    '${g.categoria} · ${formatMoney(g.valorPrevisto)}',
                  ),
                  trailing: StatusChip(
                    label: g.status.label,
                    color: switch (g.status) {
                      GastoStatus.pago => AppColors.success,
                      GastoStatus.cancelado => AppColors.danger,
                      GastoStatus.pendente => AppColors.warning,
                    },
                  ),
                  onTap: () => _form(context, g),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (embedded) return body;
    return Scaffold(body: SoftBackground(child: body));
  }

  Future<void> _form(BuildContext context, [Gasto? existing]) async {
    final store = context.read<AppStore>();
    final desc = TextEditingController(text: existing?.descricao ?? '');
    final cat = TextEditingController(text: existing?.categoria ?? 'outros');
    final previsto =
        TextEditingController(text: existing?.valorPrevisto.toString() ?? '');
    final real = TextEditingController(
      text: existing?.valorReal?.toString() ?? '',
    );
    var status = existing?.status ?? GastoStatus.pendente;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Novo gasto' : 'Editar gasto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: desc,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cat,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: previsto,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Valor previsto'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: real,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Valor real'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<GastoStatus>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: GastoStatus.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => status = v!),
                ),
              ],
            ),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () async {
                  await store.removerGasto(existing.id);
                  if (ctx.mounted) Navigator.pop(ctx, false);
                },
                child: const Text('Excluir', style: TextStyle(color: AppColors.danger)),
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
    final g = Gasto(
      id: existing?.id ?? store.novoId(),
      descricao: desc.text.trim(),
      categoria: cat.text.trim().isEmpty ? 'outros' : cat.text.trim(),
      valorPrevisto: double.tryParse(previsto.text.replaceAll(',', '.')) ?? 0,
      valorReal: double.tryParse(real.text.replaceAll(',', '.')),
      status: status,
    );
    final err = await store.upsertGasto(g);
    if (context.mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
