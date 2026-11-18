import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/estado_carga.dart';
import '../../providers/navegacion_provider.dart';
import '../../providers/salud_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/mensajes.dart';
import '../../widgets/avatar.dart';
import '../../widgets/estados.dart';
import '../../widgets/segmented_tabs.dart';
import 'actividad_tab.dart';
import 'descanso_tab.dart';
import 'entrenamiento_tab.dart';
import 'hidratacion_tab.dart';

/// Salud (ref. 04): Hidratación · Descanso · Actividad · Entrenamiento.
/// Es el único módulo con el acento turquesa. Sin recomendaciones médicas ni diagnósticos.
class SaludScreen extends StatefulWidget {
  const SaludScreen({super.key});

  @override
  State<SaludScreen> createState() => _SaludScreenState();
}

class _SaludScreenState extends State<SaludScreen> {
  static const _pestanas = ['Hidratación', 'Descanso', 'Actividad', 'Entrenamiento'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<SaludProvider>().cargar());
  }

  Future<void> _recargar() async {
    try {
      await context.read<SaludProvider>().cargar(silencioso: true);
    } on ApiException catch (e) {
      if (mounted) mostrarMensaje(context, e.mensaje, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SaludProvider>();
    final navegacion = context.watch<NavegacionProvider>();
    final pestana = navegacion.pestanaSalud;

    Widget contenido;
    if (p.estado == EstadoCarga.error) {
      contenido = ErrorState(mensaje: p.mensajeError ?? 'No se pudieron cargar tus datos de salud.', onReintentar: p.cargar);
    } else if (p.estado != EstadoCarga.listo) {
      contenido = const LoadingState(mensaje: 'Cargando tus datos de salud…');
    } else {
      contenido = switch (pestana) {
        0 => const HidratacionTab(),
        1 => const DescansoTab(),
        2 => const ActividadTab(),
        _ => const EntrenamientoTab(),
      };
    }

    return DecoratedBox(
      // Brillo turquesa sutil arriba: identidad visual exclusiva de Salud
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -1.1),
          radius: 1.1,
          colors: [AppColors.saludOscuro.withValues(alpha: 0.28), AppColors.fondo],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const EncabezadoModulo(titulo: 'Salud'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppMedidas.margenPantalla),
              child: SegmentedTabs(
                opciones: _pestanas,
                seleccionada: pestana,
                degradadoSalud: true,
                onCambio: (i) => context.read<NavegacionProvider>().cambiarPestanaSalud(i),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _recargar,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppMedidas.margenPantalla, 12, AppMedidas.margenPantalla, 32),
                  children: [
                    AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: KeyedSubtree(key: ValueKey(pestana), child: contenido)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «7 h 12 min» a partir de 7.2 horas.
String formatoHoras(double horas) {
  final totalMinutos = (horas * 60).round();
  final h = totalMinutos ~/ 60;
  final m = totalMinutos % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}

/// «1 h 30 min» a partir de 90 minutos.
String formatoMinutos(int minutos) {
  if (minutos < 60) return '$minutos min';
  final h = minutos ~/ 60;
  final m = minutos % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}
