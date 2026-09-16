import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets/brand_widgets.dart';
import '../../data/app_store.dart';
import '../../models/models.dart';

class FornecedoresScreen extends StatelessWidget {
  const FornecedoresScreen({super.key, this.embedded = false});

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
                    'Fornecedores',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                if (store.isGestao)
                  IconButton(
                    onPressed: () => _form(context),
                    icon: const Icon(Icons.add),
                  ),
              ],
            ),
          ),
          Expanded(
            child: store.fornecedores.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum fornecedor cadastrado.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.muted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: store.fornecedores.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final f = store.fornecedores[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(f.nome),
                        subtitle: Text(
                          [
                            if (f.funcao.isNotEmpty) f.funcao,
                            if (f.telefone.isNotEmpty) f.telefone,
                            if (f.descricao?.isNotEmpty == true) f.descricao!,
                          ].join(' · '),
                        ),
                        onTap: store.isGestao ? () => _form(context, f) : null,
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

  Future<void> _form(BuildContext context, [Fornecedor? existing]) async {
    final store = context.read<AppStore>();
    final nome = TextEditingController(text: existing?.nome ?? '');
    final funcao = TextEditingController(text: existing?.funcao ?? '');
    final telefone = TextEditingController(text: existing?.telefone ?? '');
    final descricao = TextEditingController(text: existing?.descricao ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existing == null ? 'Novo fornecedor' : 'Editar fornecedor',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nome,
                decoration: const InputDecoration(labelText: 'Nome'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: funcao,
                decoration: const InputDecoration(
                  labelText: 'Função',
                  hintText: 'Ex.: buffet, decoração, DJ',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: telefone,
                decoration: const InputDecoration(labelText: 'Telefone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descricao,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () async {
                await store.removerFornecedor(existing.id);
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
    );

    if (ok != true) return;
    final f = Fornecedor(
      id: existing?.id ?? store.novoId(),
      nome: nome.text.trim(),
      funcao: funcao.text.trim(),
      telefone: telefone.text.trim(),
      descricao: descricao.text.trim().isEmpty ? null : descricao.text.trim(),
    );
    final err = await store.upsertFornecedor(f);
    if (context.mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }
}
