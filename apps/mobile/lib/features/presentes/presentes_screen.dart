import 'dart:typed_data';

import 'package:flutter/material.dart';
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
    final meuId = store.meuConvidado?.id;
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
                      leading: _PresenteThumb(url: p.imagemUrl),
                      title: Text(p.nome),
                      subtitle: Text(
                        [
                          if (!guestMode) p.audiencia.label,
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
    var audiencia = existing?.audiencia ?? AudienciaPresente.convidados;
    String? imagemUrl = existing?.imagemUrl;
    Uint8List? imagemBytes;
    String? imagemNome;

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

    final p = Presente(
      id: existing?.id ?? store.novoId(),
      nome: nome.text.trim(),
      descricao: desc.text.trim().isEmpty ? null : desc.text.trim(),
      link: link.text.trim().isEmpty ? null : link.text.trim(),
      valorEstimado: double.tryParse(valor.text.replaceAll(',', '.')),
      ativo: ativo,
      audiencia: audiencia,
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
