import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/estado_carga.dart';
import '../../providers/habitos_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/mensajes.dart';
import '../../widgets/avatar.dart';
import '../../widgets/botones.dart';
import '../../widgets/chips.dart';
import '../../widgets/estados.dart';
import 'habito_card.dart';
import 'habito_form_screen.dart';

/// Hábitos (ref. 03): «Mis hábitos», una tarjeta por hábito y los pausados al final.
class HabitosScreen extends StatefulWidget {
  const HabitosScreen({super.key});

  @override
  State<HabitosScreen> createState() => _HabitosScreenState();
}

class _HabitosScreenState extends State<HabitosScreen> {
  bool _verPausados = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<HabitosProvider>().cargar());
  }

  void _nuevo() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HabitoFormScreen()));

  Future<void> _recargar() async {
    try {
      await context.read<HabitosProvider>().cargar(silencioso: true);
    } on ApiException catch (e) {
      if (mounted) mostrarMensaje(context, e.mensaje, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<HabitosProvider>();

    Widget contenido;
    if (p.estado == EstadoCarga.error) {
      contenido = ErrorState(mensaje: p.mensajeError ?? 'No se pudieron cargar tus hábitos.', onReintentar: p.cargar);
    } else if (p.estado != EstadoCarga.listo) {
      contenido = const LoadingState(mensaje: 'Cargando tus hábitos…');
    } else if (p.habitos.isEmpty) {
      contenido = EmptyState(
        icono: Icons.repeat_rounded,
        titulo: 'Crea tu primer hábito',
        mensaje: 'Pequeñas acciones diarias, grandes resultados. Marca cada día y construye tu racha.',
        textoAccion: 'Crear hábito',
        onAccion: _nuevo,
      );
    } else {
      final activos = p.activos;
      final todosHoy = activos.isNotEmpty && p.completadosHoy == activos.length;
      contenido = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: StatusChip(
              texto: todosHoy
                  ? '¡Todo listo por hoy! Sigue así 💪'
                  : '${p.completadosHoy} de ${activos.length} completados hoy',
              tipo: todosHoy ? TipoEstado.exito : TipoEstado.neutro,
              icono: todosHoy ? Icons.celebration_rounded : Icons.today_rounded,
            ),
          ),
          const SizedBox(height: 16),
          if (activos.isEmpty)
            const EmptyState(icono: Icons.pause_circle_outline_rounded, titulo: 'Todos tus hábitos están pausados'),
          for (final habito in activos) ...[HabitoCard(habito: habito), const SizedBox(height: 12)],
          if (p.pausados.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _verPausados = !_verPausados),
              icon: Icon(_verPausados ? Icons.expand_less_rounded : Icons.expand_more_rounded),
              label: Text('Pausados (${p.pausados.length})'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textoSecundario, alignment: Alignment.centerLeft),
            ),
            if (_verPausados)
              for (final habito in p.pausados) ...[HabitoCard(habito: habito), const SizedBox(height: 12)],
          ],
        ],
      );
    }

    return SafeArea(
      child: Column(
        children: [
          EncabezadoModulo(
            titulo: 'Mis hábitos',
            acciones: [IconCircleButton(icono: Icons.add_rounded, tooltip: 'Nuevo hábito', onPressed: _nuevo)],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _recargar,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppMedidas.margenPantalla, 8, AppMedidas.margenPantalla, 24),
                children: [contenido],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
