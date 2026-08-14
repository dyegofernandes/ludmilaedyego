import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/widgets/brand_widgets.dart';
import '../../data/app_store.dart';
import '../../models/models.dart';

class TarefasScreen extends StatelessWidget {
  const TarefasScreen({
    super.key,
    this.embedded = false,
    this.padrinhoMode = false,
    this.gestaoMode = false,
  });

  final bool embedded;
  final bool padrinhoMode;
  final bool gestaoMode;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final list = padrinhoMode
        ? store.minhasTarefasPadrinho
        : gestaoMode
            ? store.tarefas
            : store.tarefas;
    final podeCriar = !padrinhoMode && store.isGestao;

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
                    padrinhoMode
                        ? 'Minhas tarefas'
                        : gestaoMode
                            ? 'Tarefas dos noivos'
                            : 'Tarefas',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                if (podeCriar)
                  IconButton(
                    onPressed: () => _form(context),
                    icon: const Icon(Icons.add),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final t = list[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.titulo),
                  subtitle: Text(
                    [
                      t.destino.label,
                      t.prioridade.label,
                      if (t.prazo != null) 'Prazo ${formatDate(t.prazo)}',
                    ].join(' · '),
                  ),
                  trailing: StatusChip(
                    label: t.status.label,
                    color: switch (t.status) {
                      TarefaStatus.feito => AppColors.success,
                      TarefaStatus.aprovado => AppColors.primary,
                      TarefaStatus.rejeitado ||
                      TarefaStatus.cancelado =>
                        AppColors.danger,
                      TarefaStatus.pendente => AppColors.warning,
                    },
                  ),
                  onTap: () {
                    if (padrinhoMode) {
                      _padrinhoActions(context, t);
                    } else if (store.isNoivo &&
                        t.destino == DestinoTarefa.noivos &&
                        !store.isCerimonialista) {
                      _noivoActions(context, t);
                    } else {
                      _form(context, t);
                    }
                  },
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

  Future<void> _noivoActions(BuildContext context, Tarefa t) async {
    final store = context.read<AppStore>();
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(t.titulo),
              subtitle: Text(t.descricao ?? t.status.label),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar / aprovar'),
              onTap: () {
                Navigator.pop(ctx);
                _form(context, t);
              },
            ),
            if (t.status != TarefaStatus.feito &&
                t.status != TarefaStatus.cancelado)
              ListTile(
                leading: const Icon(Icons.check),
                title: const Text('Marcar como feito'),
                onTap: () async {
                  final err = await store.marcarTarefaFeita(t.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted && err != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(err)));
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Fechar'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _padrinhoActions(BuildContext context, Tarefa t) async {
    final store = context.read<AppStore>();
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(t.titulo),
              subtitle: Text(t.descricao ?? t.status.label),
            ),
            if (t.status == TarefaStatus.aprovado)
              ListTile(
                leading: const Icon(Icons.check),
                title: const Text('Marcar como feito'),
                onTap: () async {
                  final err = await store.marcarTarefaFeita(t.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted && err != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(err)));
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Fechar'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _form(BuildContext context, [Tarefa? existing]) async {
    final store = context.read<AppStore>();
    final titulo = TextEditingController(text: existing?.titulo ?? '');
    final desc = TextEditingController(text: existing?.descricao ?? '');
    var status = existing?.status ?? TarefaStatus.pendente;
    var prioridade = existing?.prioridade ?? Prioridade.media;
    var destino = existing?.destino ?? DestinoTarefa.noivos;
    String? padrinhoId = existing?.padrinhoId;

    // Cerimonialista: padrão criar para noivos
    if (store.isCerimonialista && existing == null) {
      destino = DestinoTarefa.noivos;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Nova tarefa' : 'Editar tarefa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titulo,
                  decoration: InputDecoration(
                    labelText: 'Título',
                    hintText: store.isCerimonialista
                        ? 'Ex.: Experimentar o bolo'
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: desc,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<DestinoTarefa>(
                  initialValue: destino,
                  decoration: const InputDecoration(labelText: 'Para quem'),
                  items: DestinoTarefa.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() {
                    destino = v!;
                    if (destino == DestinoTarefa.noivos) padrinhoId = null;
                  }),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<TarefaStatus>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: TarefaStatus.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => status = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<Prioridade>(
                  initialValue: prioridade,
                  decoration: const InputDecoration(labelText: 'Prioridade'),
                  items: Prioridade.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => prioridade = v!),
                ),
                if (destino == DestinoTarefa.padrinho) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String?>(
                    initialValue: padrinhoId,
                    decoration: const InputDecoration(
                      labelText: 'Padrinho responsável',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Selecione'),
                      ),
                      ...store.padrinhos.map((p) {
                        final nome =
                            store.convidadoById(p.convidadoId)?.nome ?? p.id;
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text(nome),
                        );
                      }),
                    ],
                    onChanged: (v) => setLocal(() => padrinhoId = v),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () async {
                  await store.removerTarefa(existing.id);
                  if (ctx.mounted) Navigator.pop(ctx, false);
                },
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: AppColors.danger),
                ),
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
    final t = Tarefa(
      id: existing?.id ?? store.novoId(),
      titulo: titulo.text.trim(),
      descricao: desc.text.trim().isEmpty ? null : desc.text.trim(),
      status: status,
      prioridade: prioridade,
      destino: destino,
      padrinhoId: destino == DestinoTarefa.padrinho ? padrinhoId : null,
      criadoPor: existing?.criadoPor ?? store.currentUser?.id,
      prazo: existing?.prazo,
    );
    final err = await store.upsertTarefa(t);
    if (context.mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }
}
