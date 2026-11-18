import 'package:flutter/material.dart';

import '../../models/tarea.dart';
import '../../theme/app_theme.dart';
import '../../utils/fechas.dart';
import '../../widgets/campos.dart';
import '../../widgets/life_card.dart';

/// Una tarea en la lista: icono con el color de la materia, título, materia,
/// fecha (ámbar si es próxima, rojo si está vencida) y casilla para completarla.
class TareaTile extends StatelessWidget {
  const TareaTile({
    super.key,
    required this.tarea,
    required this.nombreMateria,
    required this.colorMateria,
    required this.onAlternar,
    required this.onTap,
    this.ocupada = false,
  });

  final Tarea tarea;
  final String nombreMateria;
  final Color colorMateria;
  final VoidCallback onAlternar;
  final VoidCallback onTap;
  final bool ocupada;

  @override
  Widget build(BuildContext context) {
    final hoy = Fechas.hoy();
    final vencida = tarea.vencidaEn(hoy);
    final proxima = tarea.proximaEn(hoy);
    final colorFecha = vencida ? AppColors.error : (proxima ? AppColors.advertencia : AppColors.textoSecundario);
    final textoFecha = vencida
        ? 'Vencida · ${Fechas.corto(tarea.fechaEntrega)}'
        : (tarea.completada ? Fechas.conAnio(tarea.fechaEntrega) : Fechas.relativo(tarea.fechaEntrega));

    return LifeCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      radio: AppMedidas.radioItem + 4,
      onTap: onTap,
      child: Row(
        children: [
          IconoMateria(color: colorMateria),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tarea.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    decoration: tarea.completada ? TextDecoration.lineThrough : null,
                    color: tarea.completada ? AppColors.textoSecundario : AppColors.texto,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        nombreMateria,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario),
                      ),
                    ),
                    const Text('  ·  ', style: TextStyle(fontSize: 12, color: AppColors.textoSecundario)),
                    Icon(Icons.schedule_rounded, size: 13, color: colorFecha),
                    const SizedBox(width: 3),
                    Text(textoFecha, style: TextStyle(fontSize: 12, color: colorFecha, fontWeight: FontWeight.w500)),
                  ],
                ),
                if (tarea.prioridad == 'alta' && !tarea.completada) ...[
                  const SizedBox(height: 4),
                  const Text('Prioridad alta', style: TextStyle(fontSize: 11, color: AppColors.advertencia)),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 48,
            child: ocupada
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : Checkbox(
                    value: tarea.completada,
                    onChanged: (_) => onAlternar(),
                    semanticLabel: tarea.completada ? 'Marcar como pendiente' : 'Marcar como completada',
                  ),
          ),
        ],
      ),
    );
  }
}
