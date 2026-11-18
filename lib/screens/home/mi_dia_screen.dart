import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/resumen_dia.dart';
import '../../models/tarea.dart';
import '../../providers/estado_carga.dart';
import '../../providers/mi_dia_provider.dart';
import '../../providers/navegacion_provider.dart';
import '../../providers/preferencias_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/fechas.dart';
import '../../utils/mensajes.dart';
import '../../widgets/avatar.dart';
import '../../widgets/chips.dart';
import '../../widgets/estados.dart';
import '../../widgets/life_card.dart';
import '../../widgets/progreso.dart';
import '../../widgets/section_header.dart';

/// Mi Día: resumen del día con datos REALES de todos los módulos (GET /api/mi-dia).
class MiDiaScreen extends StatefulWidget {
  const MiDiaScreen({super.key});

  @override
  State<MiDiaScreen> createState() => _MiDiaScreenState();
}

class _MiDiaScreenState extends State<MiDiaScreen> {
  @override
  void initState() {
    super.initState();
    // Se pide el resumen después del primer dibujo
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<MiDiaProvider>().cargar());
  }

  /// Ejecuta una acción y muestra el error (si lo hay) como mensaje.
  Future<void> _accion(Future<void> Function() accion, {String? exito}) async {
    try {
      await accion();
      if (exito != null && mounted) mostrarMensaje(context, exito);
    } on ApiException catch (e) {
      if (mounted) mostrarMensaje(context, e.mensaje, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MiDiaProvider>();
    final resumen = p.resumen;

    Widget contenido;
    if (p.estado == EstadoCarga.error && resumen == null) {
      contenido = ErrorState(mensaje: p.mensajeError ?? 'No se pudo cargar tu día.', onReintentar: p.cargar);
    } else if (resumen == null) {
      contenido = const LoadingState(mensaje: 'Preparando tu día…');
    } else {
      contenido = _Contenido(resumen: resumen, accion: _accion);
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _accion(() => p.cargar(silencioso: true)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppMedidas.margenPantalla, 12, AppMedidas.margenPantalla, 24),
          children: [
            Row(
              children: [
                const Flexible(child: SaludoChip()),
                const Spacer(),
                if (p.racha != null && p.racha! > 0) StreakChip(dias: p.racha!),
              ],
            ),
            const SizedBox(height: 20),
            Text(Fechas.largo(resumen?.fecha ?? Fechas.hoy()), style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 20),
            contenido,
          ],
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.resumen, required this.accion});

  final ResumenDia resumen;
  final Future<void> Function(Future<void> Function() accion, {String? exito}) accion;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MiDiaProvider>();
    final vasoMl = context.watch<PreferenciasProvider>().vasoMl;
    final navegacion = context.read<NavegacionProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TarjetaProgreso(resumen: resumen),
        const SizedBox(height: 20),
        _AccesosRapidos(
          vasoMl: vasoMl,
          aguaOcupada: p.aguaOcupada,
          onSmartStudy: () => navegacion.irA(NavegacionProvider.smartStudy),
          onHabitos: () => navegacion.irA(NavegacionProvider.habitos),
          onAgua: () => accion(() => p.sumarVaso(vasoMl), exito: '+$vasoMl ml de agua registrados'),
          onEntrenamiento: () => navegacion.irA(NavegacionProvider.salud, subPestanaSalud: 3),
        ),
        const SizedBox(height: 24),
        SectionHeader(titulo: 'Próximas entregas', onVerTodo: () => navegacion.irA(NavegacionProvider.smartStudy)),
        const SizedBox(height: 8),
        if (resumen.entregas.isEmpty)
          const LifeCard(
            child: EmptyState(
              icono: Icons.event_available_rounded,
              titulo: 'Sin entregas pendientes',
              mensaje: 'No tienes tareas vencidas ni para los próximos 7 días.',
            ),
          )
        else
          for (final tarea in resumen.entregas.take(3)) ...[
            _TarjetaEntrega(tarea: tarea, referencia: resumen.fecha),
            const SizedBox(height: 12),
          ],
        if (resumen.evaluacionesProximas.isNotEmpty) ...[
          const SizedBox(height: 12),
          const SectionHeader(titulo: 'Evaluaciones próximas'),
          const SizedBox(height: 8),
          LifeCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                for (final evaluacion in resumen.evaluacionesProximas)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.assignment_rounded, color: AppColors.advertencia),
                    title: Text(evaluacion.nombre),
                    subtitle: Text(p.materias[evaluacion.materiaId]?.nombre ?? 'Materia'),
                    trailing: Text(Fechas.relativo(evaluacion.fecha, referencia: resumen.fecha)),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        SectionHeader(titulo: 'Hábitos de hoy', onVerTodo: () => navegacion.irA(NavegacionProvider.habitos)),
        const SizedBox(height: 8),
        _HabitosDeHoy(resumen: resumen, accion: accion),
      ],
    );
  }
}

/// Tarjeta con el anillo de progreso del día (hábitos + agua) y los números clave.
class _TarjetaProgreso extends StatelessWidget {
  const _TarjetaProgreso({required this.resumen});

  final ResumenDia resumen;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final porcentaje = (resumen.progresoCombinado * 100).round();
    final todosHabitos = resumen.habitosTotal > 0 && resumen.habitosCompletados == resumen.habitosTotal;
    final horas = resumen.horasSueno;

    return LifeCard(
      child: Column(
        children: [
          Row(
            children: [
              ProgressRing(
                progreso: resumen.progresoCombinado,
                tamano: 112,
                centro: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$porcentaje %', style: tema.titleLarge),
                    Text('del día', style: tema.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Progreso del día', style: tema.titleMedium),
                    const SizedBox(height: 8),
                    StatusChip(
                      texto: resumen.habitosTotal == 0
                          ? 'Sin hábitos activos'
                          : '${resumen.habitosCompletados} de ${resumen.habitosTotal} hábitos',
                      tipo: todosHabitos ? TipoEstado.exito : TipoEstado.neutro,
                      icono: todosHabitos ? Icons.check_rounded : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      resumen.aguaMl == null
                          ? 'Agua: sin registro (meta ${resumen.metaAguaMl} ml)'
                          : 'Agua: ${resumen.aguaMl} de ${resumen.metaAguaMl} ml',
                      style: tema.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Resumen de actividad: tareas, sueño y minutos de actividad
          Row(
            children: [
              _Dato(icono: Icons.task_alt_rounded, valor: '${resumen.totalPendientes}', etiqueta: 'pendientes'),
              _Dato(
                icono: Icons.bedtime_rounded,
                valor: horas == null ? '—' : '${_formatoHoras(horas)} h',
                etiqueta: 'sueño',
              ),
              _Dato(icono: Icons.directions_run_rounded, valor: '${resumen.minutosActividad}', etiqueta: 'min activo'),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatoHoras(double horas) =>
      horas == horas.roundToDouble() ? horas.toStringAsFixed(0) : horas.toStringAsFixed(1).replaceAll('.', ',');
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.valor, required this.etiqueta});

  final IconData icono;
  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icono, size: 20, color: AppColors.menta),
          const SizedBox(height: 4),
          Text(valor, style: Theme.of(context).textTheme.titleMedium),
          Text(etiqueta, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Fila horizontal de accesos rápidos (tarjetas cuadradas con icono).
class _AccesosRapidos extends StatelessWidget {
  const _AccesosRapidos({
    required this.vasoMl,
    required this.aguaOcupada,
    required this.onSmartStudy,
    required this.onHabitos,
    required this.onAgua,
    required this.onEntrenamiento,
  });

  final int vasoMl;
  final bool aguaOcupada;
  final VoidCallback onSmartStudy;
  final VoidCallback onHabitos;
  final VoidCallback onAgua;
  final VoidCallback onEntrenamiento;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _Acceso(icono: Icons.school_rounded, texto: 'SmartStudy', onTap: onSmartStudy),
          _Acceso(icono: Icons.check_circle_rounded, texto: 'Hábitos', onTap: onHabitos),
          _Acceso(
            icono: Icons.water_drop_rounded,
            texto: '+1 vaso',
            detalle: '$vasoMl ml',
            onTap: aguaOcupada ? null : onAgua,
            ocupado: aguaOcupada,
          ),
          _Acceso(icono: Icons.fitness_center_rounded, texto: 'Entrenamiento', onTap: onEntrenamiento),
        ],
      ),
    );
  }
}

class _Acceso extends StatelessWidget {
  const _Acceso({required this.icono, required this.texto, required this.onTap, this.detalle, this.ocupado = false});

  final IconData icono;
  final String texto;
  final String? detalle;
  final VoidCallback? onTap;
  final bool ocupado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 112,
        child: LifeCard(
          padding: const EdgeInsets.all(14),
          radio: 20,
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: AppColors.hueco, shape: BoxShape.circle),
                child: ocupado
                    ? const Padding(padding: EdgeInsets.all(9), child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(icono, size: 18, color: AppColors.menta),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(texto, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  if (detalle != null) Text(detalle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de una entrega: fecha, materia y título (ref. 01, «My Tasks»).
class _TarjetaEntrega extends StatelessWidget {
  const _TarjetaEntrega({required this.tarea, required this.referencia});

  final Tarea tarea;
  final DateTime referencia;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MiDiaProvider>();
    final materia = p.materias[tarea.materiaId];
    final color = AppColors.paletaMaterias[p.coloresMaterias[tarea.materiaId] ?? 0];
    final vencida = tarea.vencidaEn(referencia);
    final proxima = tarea.proximaEn(referencia);

    return LifeCard(
      onTap: () => context.read<NavegacionProvider>().irA(NavegacionProvider.smartStudy),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: AppColors.suave(color), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.menu_book_rounded, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(Fechas.conAnio(tarea.fechaEntrega), style: Theme.of(context).textTheme.bodySmall),
              ),
              StatusChip(
                texto: vencida ? 'Vencida' : Fechas.relativo(tarea.fechaEntrega, referencia: referencia),
                tipo: vencida ? TipoEstado.error : (proxima ? TipoEstado.advertencia : TipoEstado.neutro),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(tarea.titulo, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(materia?.nombre ?? 'Materia', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Lista de hábitos activos con una casilla para marcarlos hoy.
class _HabitosDeHoy extends StatelessWidget {
  const _HabitosDeHoy({required this.resumen, required this.accion});

  final ResumenDia resumen;
  final Future<void> Function(Future<void> Function() accion, {String? exito}) accion;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MiDiaProvider>();
    if (resumen.habitos.isEmpty) {
      return LifeCard(
        child: EmptyState(
          icono: Icons.check_circle_outline_rounded,
          titulo: 'Aún no tienes hábitos activos',
          mensaje: 'Crea uno en la pestaña Hábitos para verlo aquí cada día.',
          textoAccion: 'Crear hábito',
          onAccion: () => context.read<NavegacionProvider>().irA(NavegacionProvider.habitos),
        ),
      );
    }

    final todos = resumen.habitosCompletados == resumen.habitosTotal;
    return LifeCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          if (todos)
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: StatusChip(texto: '¡Completaste todos tus hábitos de hoy!', tipo: TipoEstado.exito, icono: Icons.celebration_rounded),
            ),
          for (final habito in resumen.habitos)
            CheckboxListTile(
              value: habito.cumplido,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(
                habito.nombre,
                style: TextStyle(
                  decoration: habito.cumplido ? TextDecoration.lineThrough : null,
                  color: habito.cumplido ? AppColors.textoSecundario : AppColors.texto,
                ),
              ),
              secondary: p.habitosOcupados.contains(habito.id)
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
              onChanged: p.habitosOcupados.contains(habito.id)
                  ? null
                  : (_) => accion(
                        () => p.alternarHabito(habito),
                        exito: habito.cumplido ? 'Marca quitada' : '¡${habito.nombre} cumplido hoy!',
                      ),
            ),
        ],
      ),
    );
  }
}
