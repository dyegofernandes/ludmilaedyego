import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/widgets/brand_widgets.dart';
import '../../data/app_store.dart';
import '../../models/models.dart';

class FotosScreen extends StatelessWidget {
  const FotosScreen({super.key, this.guestMode = false});

  final bool guestMode;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final list = guestMode ? store.fotosVisiveis : store.fotos;

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
                        'Fotos',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    if (!guestMode)
                      IconButton(
                        onPressed: () => _add(context),
                        icon: const Icon(Icons.add_a_photo_outlined),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text('Nenhuma foto ainda.'))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final f = list[i];
                          return GestureDetector(
                            onTap: () => _open(context, f),
                            onLongPress:
                                guestMode ? null : () => _edit(context, f),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    AppConstants.mediaUrl(f.url),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: AppColors.surfaceElevated,
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  ),
                                  if (!guestMode)
                                    Positioned(
                                      left: 8,
                                      bottom: 8,
                                      child: StatusChip(
                                        label: f.publico ? 'Pública' : 'Privada',
                                        color: f.publico
                                            ? AppColors.success
                                            : AppColors.muted,
                                      ),
                                    ),
                                ],
                              ),
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

  Future<void> _add(BuildContext context) async {
    final store = context.read<AppStore>();
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      imageQuality: 82,
      maxWidth: 1920,
    );
    if (picked.isEmpty) return;

    var tipo = FotoTipo.evento;
    var publico = true;
    final legenda = TextEditingController();

    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(
            picked.length == 1
                ? 'Nova foto'
                : 'Enviar ${picked.length} fotos',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<FotoTipo>(
                initialValue: tipo,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: FotoTipo.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        ))
                    .toList(),
                onChanged: (v) => setLocal(() => tipo = v!),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: legenda,
                decoration: const InputDecoration(labelText: 'Legenda'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pública'),
                value: publico,
                onChanged: (v) => setLocal(() => publico = v),
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
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final arquivos = <({Uint8List bytes, String name})>[];
    for (final file in picked) {
      arquivos.add((
        bytes: await file.readAsBytes(),
        name: file.name.isEmpty ? 'foto.jpg' : file.name,
      ));
    }
    final err = await store.adicionarFotos(
      arquivos: arquivos,
      tipo: tipo,
      legenda: legenda.text.trim().isEmpty ? null : legenda.text.trim(),
      publico: publico,
    );
    if (context.mounted) Navigator.of(context).pop();
    if (context.mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            picked.length > 1
                ? '${picked.length} fotos enviadas'
                : 'Foto enviada',
          ),
        ),
      );
    }
  }

  Future<void> _open(BuildContext context, Foto f) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FotoViewer(
          foto: f,
          onEdit: guestMode ? null : () => _edit(context, f),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, Foto f) async {
    final store = context.read<AppStore>();
    var publico = f.publico;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Pública'),
              value: publico,
              onChanged: (v) async {
                publico = v;
                f.publico = v;
                await store.atualizarFoto(f);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.danger),
              title: const Text('Excluir'),
              onTap: () async {
                await store.removerFoto(f.id);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  Navigator.of(context).maybePop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FotoViewer extends StatelessWidget {
  const _FotoViewer({
    required this.foto,
    this.onEdit,
  });

  final Foto foto;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        foregroundColor: Colors.white,
        title: Text(
          foto.legenda?.isNotEmpty == true ? foto.legenda! : 'Foto',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (onEdit != null)
            IconButton(
              tooltip: 'Opções',
              onPressed: onEdit,
              icon: const Icon(Icons.more_vert),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              panEnabled: true,
              child: Center(
                child: Image.network(
                  AppConstants.mediaUrl(foto.url),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image,
                    color: Colors.white70,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Text(
              'Use dois dedos para dar zoom',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
