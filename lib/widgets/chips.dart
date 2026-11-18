import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum TipoEstado { exito, advertencia, error, neutro }

/// Chip de estado con fondo suave del color (ej.: «3 de 5 completadas»).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.texto, this.tipo = TipoEstado.neutro, this.icono});

  final String texto;
  final TipoEstado tipo;
  final IconData? icono;

  Color get _color => switch (tipo) {
        TipoEstado.exito => AppColors.exito,
        TipoEstado.advertencia => AppColors.advertencia,
        TipoEstado.error => AppColors.error,
        TipoEstado.neutro => AppColors.textoSecundario,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tipo == TipoEstado.neutro ? AppColors.superficie : AppColors.suave(color),
        borderRadius: BorderRadius.circular(AppMedidas.radioPildora),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[Icon(icono, size: 14, color: color), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              texto,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de racha: 🔥 y el número de días (ref. 02).
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.dias});

  final int dias;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Racha de $dias días',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(AppMedidas.radioPildora),
          border: Border.all(color: AppColors.borde),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text('$dias', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
