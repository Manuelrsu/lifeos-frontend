import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/salud_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/fechas.dart';
import '../../widgets/botones.dart';
import '../../widgets/life_card.dart';
import 'actividad_form_screen.dart';
import 'salud_screen.dart';

/// Actividad: resumen de los últimos 7 días en una cuadrícula 2×2 y barras por día.
class ActividadTab extends StatelessWidget {
  const ActividadTab({super.key});

  static const sugerencias = ['Caminar', 'Correr', 'Bicicleta', 'Fútbol', 'Baile', 'Natación'];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SaludProvider>();
    final e = p.estadisticas!;
    final tema = Theme.of(context).textTheme;
    final promedio = e.totalActividades == 0 ? 0 : (e.minutosTotales / e.totalActividades).round();
    final barras = p.minutosUltimos7Dias;
    final maximo = barras.fold<int>(0, (m, b) => b.minutos > m ? b.minutos : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Últimos 7 días', style: tema.titleMedium),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            _Indicador(icono: Icons.timer_rounded, valor: formatoMinutos(e.minutosTotales), etiqueta: 'Minutos activos'),
            _Indicador(icono: Icons.repeat_rounded, valor: '${e.totalActividades}', etiqueta: 'Sesiones'),
            _Indicador(icono: Icons.calendar_month_rounded, valor: '${e.diasActivos}/7', etiqueta: 'Días activos'),
            _Indicador(icono: Icons.speed_rounded, valor: e.totalActividades == 0 ? '—' : formatoMinutos(promedio), etiqueta: 'Promedio por sesión'),
          ],
        ),
        const SizedBox(height: 16),
        LifeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Minutos por día', style: tema.bodySmall),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final b in barras)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (b.minutos > 0) Text('${b.minutos}', style: const TextStyle(fontSize: 10, color: AppColors.textoSecundario)),
                              const SizedBox(height: 4),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: maximo == 0 ? 4 : 4 + 76 * b.minutos / maximo,
                                decoration: BoxDecoration(
                                  gradient: b.minutos > 0 ? AppColors.degradadoSalud : null,
                                  color: b.minutos > 0 ? null : AppColors.superficie,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(Fechas.diaSemanaCorto(b.dia), style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PillButton(
          texto: 'Registrar actividad',
          icono: Icons.directions_run_rounded,
          degradadoSalud: true,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ActividadFormScreen(titulo: 'Nueva actividad', sugerencias: sugerencias)),
          ),
        ),
        const SizedBox(height: 8),
        Text('El historial completo está en la pestaña Entrenamiento.', style: tema.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }
}

/// Cuadro de la cuadrícula 2×2 (ref. 04).
class _Indicador extends StatelessWidget {
  const _Indicador({required this.icono, required this.valor, required this.etiqueta});

  final IconData icono;
  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return LifeCard(
      padding: const EdgeInsets.all(14),
      radio: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icono, size: 20, color: AppColors.saludClaro),
          FittedBox(fit: BoxFit.scaleDown, child: Text(valor, style: Theme.of(context).textTheme.titleLarge)),
          Text(etiqueta, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
