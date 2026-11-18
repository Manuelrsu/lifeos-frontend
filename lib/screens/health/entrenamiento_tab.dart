import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/salud_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/fechas.dart';
import '../../widgets/botones.dart';
import '../../widgets/estados.dart';
import '../../widgets/life_card.dart';
import 'actividad_form_screen.dart';
import 'salud_screen.dart';

/// Entrenamiento: registrar entrenamientos y ver el historial sencillo del último mes.
/// Actividad y entrenamiento usan el mismo registro del backend (actividades físicas).
class EntrenamientoTab extends StatelessWidget {
  const EntrenamientoTab({super.key});

  static const sugerencias = ['Pesas', 'Funcional', 'Yoga', 'Cardio', 'Calistenia', 'Estiramiento'];

  void _abrirFormulario(BuildContext context, {Widget? pantalla}) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => pantalla ?? const ActividadFormScreen(titulo: 'Nuevo entrenamiento', sugerencias: sugerencias),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SaludProvider>();
    final tema = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PillButton(
          texto: 'Registrar entrenamiento',
          icono: Icons.fitness_center_rounded,
          degradadoSalud: true,
          onPressed: () => _abrirFormulario(context),
        ),
        const SizedBox(height: 20),
        Text('Historial (últimos ${SaludProvider.diasActividades} días)', style: tema.titleMedium),
        const SizedBox(height: 8),
        if (p.actividades.isEmpty)
          const LifeCard(
            child: EmptyState(
              icono: Icons.fitness_center_rounded,
              titulo: 'Sin entrenamientos registrados',
              mensaje: 'Registra tu primera sesión con el botón de arriba.',
            ),
          )
        else
          for (final a in p.actividades) ...[
            LifeCard(
              padding: const EdgeInsets.all(16),
              radio: AppMedidas.radioItem + 4,
              onTap: () => _abrirFormulario(
                context,
                pantalla: ActividadFormScreen(actividad: a, sugerencias: sugerencias),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.suave(AppColors.saludClaro), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.fitness_center_rounded, color: AppColors.saludClaro, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.tipo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        Text(
                          [Fechas.relativo(a.fecha), if (a.descripcion != null) a.descripcion!].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tema.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(formatoMinutos(a.duracionMinutos), style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}
