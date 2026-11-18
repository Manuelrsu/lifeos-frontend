import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/preferencias_provider.dart';
import '../../providers/salud_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/fechas.dart';
import '../../utils/mensajes.dart';
import '../../widgets/botella.dart';
import '../../widgets/botones.dart';
import '../../widgets/life_card.dart';
import '../../widgets/progreso.dart';

/// Hidratación: botella que se llena, vasos llevados y faltantes, +1 / −1 vaso e historial de 7 días.
class HidratacionTab extends StatelessWidget {
  const HidratacionTab({super.key});

  Future<void> _cambiar(BuildContext context, int diferencia) async {
    try {
      await context.read<SaludProvider>().cambiarAgua(diferencia);
      if (context.mounted) {
        mostrarMensaje(context, diferencia > 0 ? '+$diferencia ml registrados' : 'Se quitó un vaso');
      }
    } on ApiException catch (e) {
      if (context.mounted) mostrarMensaje(context, e.mensaje, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SaludProvider>();
    final vaso = context.watch<PreferenciasProvider>().vasoMl;
    final tema = Theme.of(context).textTheme;

    final ml = p.aguaHoyMl;
    final meta = p.metaMl;
    final progreso = meta == 0 ? 0.0 : ml / meta;
    final vasos = ml ~/ vaso;
    final vasosMeta = (meta / vaso).ceil();
    final faltanMl = (meta - ml).clamp(0, meta);
    final faltanVasos = (faltanMl / vaso).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LifeCard(
          child: Row(
            children: [
              BotellaAgua(progreso: progreso, ancho: 104, alto: 200),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hoy llevas', style: tema.bodySmall),
                    Text('${(progreso * 100).round()} %', style: tema.headlineLarge?.copyWith(color: AppColors.saludClaro)),
                    const SizedBox(height: 12),
                    Text('Llevas $vasos de $vasosMeta vasos', style: tema.titleMedium),
                    Text('$ml de $meta ml', style: tema.bodySmall),
                    const SizedBox(height: 12),
                    Text(
                      faltanMl == 0 ? '¡Meta del día cumplida!' : 'Te faltan $faltanVasos vaso${faltanVasos == 1 ? '' : 's'} ($faltanMl ml)',
                      style: tema.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PillButton(
          texto: '+1 vaso ($vaso ml)',
          icono: Icons.water_drop_rounded,
          degradadoSalud: true,
          cargando: p.aguaOcupada,
          onPressed: () => _cambiar(context, vaso),
        ),
        const SizedBox(height: 4),
        Center(
          child: PillButton(
            texto: 'Quitar un vaso',
            secundario: true,
            icono: Icons.remove_rounded,
            onPressed: ml > 0 && !p.aguaOcupada ? () => _cambiar(context, -vaso) : null,
          ),
        ),
        const SizedBox(height: 16),
        Text('Últimos 7 días', style: tema.titleMedium),
        const SizedBox(height: 8),
        LifeCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: List.generate(7, (i) {
              final dia = Fechas.hoy().subtract(Duration(days: i));
              final registro = p.aguaSemana.where((r) => r.fecha == dia).firstOrNull;
              final cantidad = registro?.cantidadMl;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(width: 64, child: Text(i == 0 ? 'Hoy' : Fechas.diaSemanaCorto(dia), style: tema.bodySmall)),
                    Expanded(
                      child: MiniProgressBar(
                        progreso: cantidad == null || meta == 0 ? 0 : cantidad / meta,
                        color: AppColors.saludClaro,
                        ancho: double.infinity,
                      ),
                    ),
                    SizedBox(
                      width: 76,
                      child: Text(cantidad == null ? 'Sin registro' : '$cantidad ml', textAlign: TextAlign.end, style: tema.bodySmall),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Meta diaria: $meta ml (definida por el servidor). Tamaño del vaso: $vaso ml (cámbialo en Perfil).',
          style: tema.bodySmall,
        ),
      ],
    );
  }
}
