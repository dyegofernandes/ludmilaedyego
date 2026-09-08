import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/widgets/brand_widgets.dart';
import '../../data/app_store.dart';
import '../../models/models.dart';

class PresentesScreen extends StatefulWidget {
  const PresentesScreen({super.key, this.guestMode = false});

  final bool guestMode;

  @override
  State<PresentesScreen> createState() => _PresentesScreenState();
}

class _PresentesScreenState extends State<PresentesScreen> {
  AudienciaPresente? _filtroGestao;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final guestMode = widget.guestMode;
    var list = store.presentes.where((p) => guestMode ? p.ativo : true).toList();
    if (!guestMode && _filtroGestao != null) {
      list = list.where((p) => p.audiencia == _filtroGestao).toList();
    }
    final titulo = guestMode
        ? (store.isPadrinho
            ? 'Presentes dos padrinhos'
            : 'Lista de presentes')
        : 'Presentes';

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
                        titulo,
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
              if (!guestMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: SegmentedButton<AudienciaPresente?>(
                    segments: const [
                      ButtonSegment(value: null, label: Text('Todos')),
                      ButtonSegment(
                        value: AudienciaPresente.convidados,
                        label: Text('Convidados'),
                      ),
                      ButtonSegment(
                        value: AudienciaPresente.padrinhos,
                        label: Text('Padrinhos'),
                      ),
                    ],
                    selected: {_filtroGestao},
                    onSelectionChanged: (s) =>
                        setState(() => _filtroGestao = s.first),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = list[i];
                    String? statusLabel;
                    if (!guestMode) {
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
                      leading: _PresenteThumb(url: p.imagemUrl),
                      title: Text(p.nome),
                      subtitle: Text(
                        [
                          if (!guestMode) p.audiencia.label,
                          if (p.valorEstimado != null)
                            formatMoney(p.valorEstimado!),
                          if (statusLabel != null) statusLabel,
                          if (p.temPix) 'Pix',
                        ].join(' · '),
                      ),
                      trailing: guestMode
                          ? (p.temPix
                              ? const Icon(Icons.qr_code_2)
                              : null)
                          : IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _form(context, p),
                            ),
                      onTap: () {
                        if (guestMode) {
                          _mostrarDetalhe(context, p);
                          return;
                        }
                        if (p.link != null) {
                          launchUrl(Uri.parse(p.link!));
                        }
                      },
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

  Future<void> _mostrarDetalhe(BuildContext context, Presente p) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final chave = p.pixChave?.trim();
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(p.nome, style: Theme.of(ctx).textTheme.headlineSmall),
              if (p.valorEstimado != null) ...[
                const SizedBox(height: 4),
                Text(formatMoney(p.valorEstimado!)),
              ],
              if (p.descricao != null && p.descricao!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(p.descricao!),
              ],
              if (p.pixQrCodeUrl != null && p.pixQrCodeUrl!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      AppConstants.mediaUrl(p.pixQrCodeUrl!),
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.qr_code_2,
                        size: 80,
                      ),
                    ),
                  ),
                ),
              ],
              if (chave != null && chave.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Chave Pix'),
                const SizedBox(height: 4),
                SelectableText(
                  chave,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: chave));
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Chave Pix copiada')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar chave'),
                  ),
                ),
              ],
              if (p.link != null && p.link!.isNotEmpty)
                TextButton(
                  onPressed: () => launchUrl(Uri.parse(p.link!)),
                  child: const Text('Abrir link do presente'),
                ),
            ],
          ),
        );
      },
    );
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
    var audiencia = existing?.audiencia ?? AudienciaPresente.convidados;
    final pixChave = TextEditingController(text: existing?.pixChave ?? '');
    String? imagemUrl = existing?.imagemUrl;
    Uint8List? imagemBytes;
    String? imagemNome;
    String? pixQrUrl = existing?.pixQrCodeUrl;
    Uint8List? pixQrBytes;
    String? pixQrNome;

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
                const SizedBox(height: 10),
                DropdownButtonFormField<AudienciaPresente>(
                  initialValue: audiencia,
                  decoration: const InputDecoration(labelText: 'Para'),
                  items: AudienciaPresente.values
                      .map(
                        (a) => DropdownMenuItem(
                          value: a,
                          child: Text(a.label),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setLocal(() => audiencia = v!),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Foto ilustrativa',
                    style: Theme.of(ctx).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 8),
                if (imagemBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      imagemBytes!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else if (imagemUrl != null && imagemUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      AppConstants.mediaUrl(imagemUrl!),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 120,
                        color: AppColors.surfaceElevated,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 85,
                          maxWidth: 1200,
                        );
                        if (picked == null) return;
                        final bytes = await picked.readAsBytes();
                        setLocal(() {
                          imagemBytes = bytes;
                          imagemNome = picked.name;
                        });
                      },
                      icon: const Icon(Icons.photo_outlined),
                      label: Text(
                        imagemBytes != null || (imagemUrl?.isNotEmpty ?? false)
                            ? 'Trocar foto'
                            : 'Escolher foto',
                      ),
                    ),
                    if (imagemBytes != null ||
                        (imagemUrl != null && imagemUrl!.isNotEmpty))
                      TextButton(
                        onPressed: () => setLocal(() {
                          imagemBytes = null;
                          imagemNome = null;
                          imagemUrl = null;
                        }),
                        child: const Text('Remover'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pixChave,
                  decoration: const InputDecoration(
                    labelText: 'Chave Pix',
                    hintText: 'CPF, e-mail, telefone ou aleatória',
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'QR Code do Pix',
                    style: Theme.of(ctx).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 8),
                if (pixQrBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      pixQrBytes!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  )
                else if (pixQrUrl != null && pixQrUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      AppConstants.mediaUrl(pixQrUrl!),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Container(
                        height: 120,
                        color: AppColors.surfaceElevated,
                        alignment: Alignment.center,
                        child: const Icon(Icons.qr_code_2),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 90,
                          maxWidth: 1200,
                        );
                        if (picked == null) return;
                        final bytes = await picked.readAsBytes();
                        setLocal(() {
                          pixQrBytes = bytes;
                          pixQrNome = picked.name;
                        });
                      },
                      icon: const Icon(Icons.qr_code_2),
                      label: Text(
                        pixQrBytes != null || (pixQrUrl?.isNotEmpty ?? false)
                            ? 'Trocar QR Code'
                            : 'Adicionar QR Code',
                      ),
                    ),
                    if (pixQrBytes != null ||
                        (pixQrUrl != null && pixQrUrl!.isNotEmpty))
                      TextButton(
                        onPressed: () => setLocal(() {
                          pixQrBytes = null;
                          pixQrNome = null;
                          pixQrUrl = null;
                        }),
                        child: const Text('Remover'),
                      ),
                  ],
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

    var finalImagemUrl = imagemUrl;
    var finalPixQrUrl = pixQrUrl;
    if (imagemBytes != null) {
      try {
        finalImagemUrl = await store.uploadPresenteImagem(
          imagemBytes!,
          imagemNome ?? 'presente.jpg',
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
        return;
      }
    }
    if (pixQrBytes != null) {
      try {
        finalPixQrUrl = await store.uploadPresenteImagem(
          pixQrBytes!,
          pixQrNome ?? 'pix-qrcode.jpg',
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
        return;
      }
    }

    final p = Presente(
      id: existing?.id ?? store.novoId(),
      nome: nome.text.trim(),
      descricao: desc.text.trim().isEmpty ? null : desc.text.trim(),
      link: link.text.trim().isEmpty ? null : link.text.trim(),
      valorEstimado: double.tryParse(valor.text.replaceAll(',', '.')),
      ativo: ativo,
      audiencia: audiencia,
      pixChave: pixChave.text.trim().isEmpty ? null : pixChave.text.trim(),
      pixQrCodeUrl: finalPixQrUrl,
      reservadoPorConvidadoId: existing?.reservadoPorConvidadoId,
      reservadoEm: existing?.reservadoEm,
      imagemUrl: finalImagemUrl,
    );
    final err = await store.upsertPresente(p);
    if (context.mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }
}

class _PresenteThumb extends StatelessWidget {
  const _PresenteThumb({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final src = url;
    if (src == null || src.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.card_giftcard_outlined, color: AppColors.muted),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        AppConstants.mediaUrl(src),
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 56,
          height: 56,
          color: AppColors.surfaceElevated,
          child: const Icon(Icons.broken_image, color: AppColors.muted),
        ),
      ),
    );
  }
}
