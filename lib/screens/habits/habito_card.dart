import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/habito.dart';
import '../../providers/habitos_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/fechas.dart';
import '../../utils/mensajes.dart';
import '../../widgets/life_card.dart';
import '../../widgets/progreso.dart';
import '../../widgets/week_check_row.dart';
import 'habito_form_screen.dart';

/// Tarjeta de un hábito (ref. 03): icono, nombre, barra «x % · n/7 esta semana»,
/// fila de la semana, insignia de racha y botón de estadísticas.
class HabitoCard extends StatelessWidget {
  const HabitoCard({super.key, required this.habito});

  final Habito habito;

  Future<void> _tocarDia(BuildContext context, int indice) async {
    final p = context.read<HabitosProvider>();
    final dia = p.lunes.add(Duration(days: indice));
    final estabaCumplido = p.cumplido(habito.id, dia);
    try {
      await p.alternarDia(habito, dia);
      if (!context.mounted) return;
      final esHoy = Fechas.diasEntre(Fechas.hoy(), dia) == 0;
      if (estabaCumplido) {
        mostrarMensaje(context, 'Marca quitada');
      } else if (esHoy && p.activos.isNotEmpty && p.completadosHoy == p.activos.length) {
        mostrarMensaje(context, '¡Completaste todos tus hábitos de hoy! 🎉');
      } else {
        mostrarMensaje(context, '¡${habito.nombre} cumplido!');
      }
    } on ApiException catch (e) {
      if (context.mounted) mostrarMensaje(context, e.mensaje, error: true);
    }
  }

  Future<void> _menu(BuildContext context, String opcion) async {
    final p = context.read<HabitosProvider>();
    try {
      switch (opcion) {
        case 'editar':
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => HabitoFormScreen(habito: habito)));
        case 'pausar':
          await p.actualizar(habito, activo: !habito.activo);
          if (context.mounted) {
            mostrarMensaje(context, habito.activo ? 'Hábito pausado: no aparecerá en Mi Día' : 'Hábito reactivado');
          }
        case 'eliminar':
          final ok = await confirmar(
            context,
            titulo: '¿Eliminar «${habito.nombre}»?',
            mensaje: 'Se borrará también todo su historial. Si solo quieres dejarlo por un tiempo, mejor páusalo.',
          );
          if (ok) {
            await p.eliminar(habito);
            if (context.mounted) mostrarMensaje(context, 'Hábito eliminado');
          }
      }
    } on ApiException catch (e) {
      if (context.mounted) mostrarMensaje(context, e.mensaje, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<HabitosProvider>();
    final hoy = Fechas.hoy();
    final lunes = p.lunes;
    final dias = List.generate(7, (i) => lunes.add(Duration(days: i)));
    final hechos = p.diasEstaSemana(habito.id);
    final stats = p.estadisticas[habito.id];
    final indiceHoy = hoy.weekday - 1;
    final tema = Theme.of(context).textTheme;

    return LifeCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
      child: Opacity(
        opacity: habito.activo ? 1 : 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: AppColors.suave(AppColors.menta), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.repeat_rounded, color: AppColors.menta, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habito.nombre, style: tema.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          MiniProgressBar(progreso: hechos / 7, ancho: 36),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${(hechos / 7 * 100).round()} % · $hechos/7 esta semana',
                              style: tema.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (stats != null && stats.rachaActual > 0) _InsigniaRacha(dias: stats.rachaActual),
                PopupMenuButton<String>(
                  tooltip: 'Opciones',
                  icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textoSecundario),
                  onSelected: (opcion) => _menu(context, opcion),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'editar', child: Text('Editar')),
                    PopupMenuItem(value: 'pausar', child: Text(habito.activo ? 'Pausar' : 'Reactivar')),
                    const PopupMenuItem(value: 'eliminar', child: Text('Eliminar', style: TextStyle(color: AppColors.error))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: WeekCheckRow(
                      cumplidos: [for (final d in dias) p.cumplido(habito.id, d)],
                      // Se puede marcar hoy y los días pasados (el backend no acepta días futuros)
                      habilitados: [for (final d in dias) Fechas.diasEntre(hoy, d) <= 0],
                      cargando: [for (final d in dias) p.estaOcupado(habito.id, d)],
                      indiceHoy: indiceHoy,
                      onTocarDia: habito.activo ? (i) => _tocarDia(context, i) : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.hueco,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => mostrarEstadisticas(context, habito),
                      child: const Tooltip(
                        message: 'Estadísticas',
                        child: SizedBox(width: 40, height: 40, child: Icon(Icons.bar_chart_rounded, size: 20)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Insignia «🔥 12 d» con la racha actual.
class _InsigniaRacha extends StatelessWidget {
  const _InsigniaRacha({required this.dias});

  final int dias;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.hueco, borderRadius: BorderRadius.circular(8)),
      child: Text('🔥 $dias d', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Hoja inferior con las estadísticas que calcula el backend a partir del historial.
Future<void> mostrarEstadisticas(BuildContext context, Habito habito) {
  final p = context.read<HabitosProvider>();
  final stats = p.estadisticas[habito.id];
  final semana = p.diasEstaSemana(habito.id);
  return showModalBottomSheet<void>(
    context: context,
    // isScrollControlled + SingleChildScrollView: en pantallas bajas se desplaza en vez de desbordarse
    isScrollControlled: true,
    builder: (contexto) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppMedidas.margenPantalla, 0, AppMedidas.margenPantalla, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(habito.nombre, style: Theme.of(contexto).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Calculado por el servidor a partir de tu historial', style: Theme.of(contexto).textTheme.bodySmall),
            const SizedBox(height: 20),
            if (stats == null)
              const Text('No se pudieron cargar las estadísticas.')
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.7,
                children: [
                  _Cifra(valor: '${stats.rachaActual} d', etiqueta: 'Racha actual', icono: Icons.local_fire_department_rounded),
                  _Cifra(valor: '${stats.mejorRacha} d', etiqueta: 'Mejor racha', icono: Icons.emoji_events_rounded),
                  _Cifra(valor: '$semana/7', etiqueta: 'Esta semana', icono: Icons.date_range_rounded),
                  _Cifra(
                    valor: '${stats.porcentajeCumplimiento.toStringAsFixed(1).replaceAll('.', ',')} %',
                    etiqueta: 'Últimos ${stats.diasVentana} días',
                    icono: Icons.percent_rounded,
                  ),
                ],
              ),
            if (stats != null) ...[
              const SizedBox(height: 16),
              Text(
                stats.ultimoCumplimiento == null
                    ? 'Aún no lo has marcado como cumplido.'
                    : 'Total: ${stats.totalCumplimientos} día(s) cumplido(s). Último: ${Fechas.conAnio(Fechas.desdeApi(stats.ultimoCumplimiento!))}.',
                style: Theme.of(contexto).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _Cifra extends StatelessWidget {
  const _Cifra({required this.valor, required this.etiqueta, required this.icono});

  final String valor;
  final String etiqueta;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.superficie, borderRadius: BorderRadius.circular(AppMedidas.radioItem)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icono, size: 18, color: AppColors.menta),
          FittedBox(fit: BoxFit.scaleDown, child: Text(valor, style: Theme.of(context).textTheme.titleLarge)),
          Text(etiqueta, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
