import 'package:flutter/material.dart';

import '../theme.dart';
import '../../models/models.dart';

/// Botões de confirmação de presença com contraste alto (legíveis).
class RsvpConfirmBlock extends StatelessWidget {
  const RsvpConfirmBlock({
    super.key,
    required this.atual,
    required this.onSelect,
    this.titulo,
    this.subtitulo,
  });

  final RsvpStatus atual;
  final String? titulo;
  final String? subtitulo;
  final Future<void> Function(RsvpStatus status) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo ?? 'Confirmar presença',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
        ),
        if (subtitulo != null && subtitulo!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitulo!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Sua resposta: ${atual.label}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final s in [
              RsvpStatus.sim,
              RsvpStatus.nao,
              RsvpStatus.talvez,
            ])
              _RsvpChip(
                label: s.label,
                selected: atual == s,
                color: switch (s) {
                  RsvpStatus.sim => AppColors.success,
                  RsvpStatus.nao => AppColors.danger,
                  RsvpStatus.talvez => AppColors.warning,
                  RsvpStatus.pendente => AppColors.primary,
                },
                onTap: () => onSelect(s),
              ),
          ],
        ),
      ],
    );
  }
}

class _RsvpChip extends StatelessWidget {
  const _RsvpChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : Colors.white,
      elevation: selected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color,
          width: selected ? 0 : 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class RsvpGrupoBlock extends StatelessWidget {
  const RsvpGrupoBlock({
    super.key,
    required this.convidado,
    required this.onSelect,
  });

  final Convidado convidado;
  final Future<void> Function(RsvpStatus status, {String? acompanhanteId})
      onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RsvpConfirmBlock(
          titulo: 'Você · ${convidado.nome}',
          subtitulo: 'Confirme sua presença',
          atual: convidado.rsvp,
          onSelect: (s) => onSelect(s),
        ),
        for (final a in convidado.acompanhantesLista) ...[
          const SizedBox(height: 22),
          RsvpConfirmBlock(
            titulo: a.nome,
            subtitulo:
                'Acompanhante · ${a.tipo.label} — confirme a presença desta pessoa',
            atual: a.rsvp,
            onSelect: (s) => onSelect(s, acompanhanteId: a.id),
          ),
        ],
      ],
    );
  }
}
