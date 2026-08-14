import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/widgets/brand_widgets.dart';
import '../../data/app_store.dart';
import '../../models/models.dart';

class TokensAcessoScreen extends StatelessWidget {
  const TokensAcessoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final lista = [...store.convites];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cerimonialista'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Novo link cerimonialista',
            onPressed: () => _novoCerimonialista(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SoftBackground(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: lista.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final c = lista[i];
            final link = AppConstants.conviteUrl(c.token);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(c.nome),
              subtitle: Text('${c.role.label}\n$link'),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: link));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copiado')),
                    );
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _novoCerimonialista(BuildContext context) async {
    final store = context.read<AppStore>();
    final nome = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link para cerimonialista'),
        content: TextField(
          controller: nome,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gerar'),
          ),
        ],
      ),
    );
    if (ok != true || nome.text.trim().isEmpty) return;
    final err = await store.criarConviteCerimonialista(nome.text.trim());
    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    final token = store.convites.last.token;
    final link = AppConstants.conviteUrl(token);
    await Clipboard.setData(ClipboardData(text: link));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Link gerado e copiado')),
      );
    }
  }
}
