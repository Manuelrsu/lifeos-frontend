import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/evaluacion.dart';
import '../../models/tarea.dart';
import '../../providers/estado_carga.dart';
import '../../providers/smartstudy_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/fechas.dart';
import '../../utils/mensajes.dart';
import '../../widgets/avatar.dart';
import '../../widgets/botones.dart';
import '../../widgets/campos.dart';
import '../../widgets/chips.dart';
import '../../widgets/estados.dart';
import '../../widgets/life_card.dart';
import 'evaluacion_form_screen.dart';
import 'materia_form_screen.dart';
import 'materias_screen.dart';
import 'tarea_form_screen.dart';
import 'tarea_tile.dart';

/// SmartStudy: tareas pendientes y completadas, y evaluaciones (refs. 02 y 01).
class SmartStudyScreen extends StatefulWidget {
  const SmartStudyScreen({super.key});

  @override
  State<SmartStudyScreen> createState() => _SmartStudyScreenState();
}

class _SmartStudyScreenState extends State<SmartStudyScreen> with SingleTickerProviderStateMixin {
  late final TabController _pestanas = TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
    // Redibuja para cambiar el botón «+» según la pestaña
    _pestanas.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<SmartStudyProvider>().cargar());
  }

  @override
  void dispose() {
    _pestanas.dispose();
    super.dispose();
  }

  void _abrir(Widget pantalla) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));

  Future<void> _alternar(Tarea tarea) async {
    try {
      await context.read<SmartStudyProvider>().alternarTarea(tarea);
      if (mounted) mostrarMensaje(context, tarea.completada ? 'Tarea marcada como pendiente' : '¡Tarea completada!');
    } on ApiException catch (e) {
      if (mounted) mostrarMensaje(context, e.mensaje, error: true);
    }
  }

  Future<void> _recargar() async {
    try {
      await context.read<SmartStudyProvider>().cargar(silencioso: true);
    } on ApiException catch (e) {
      if (mounted) mostrarMensaje(context, e.mensaje, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SmartStudyProvider>();
    final sinMaterias = p.estado == EstadoCarga.listo && p.materias.isEmpty;

    Widget cuerpo;
    if (p.estado == EstadoCarga.error) {
      cuerpo = Center(child: ErrorState(mensaje: p.mensajeError ?? 'No se pudo cargar SmartStudy.', onReintentar: p.cargar));
    } else if (p.estado != EstadoCarga.listo) {
      cuerpo = const LoadingState(mensaje: 'Cargando tus materias…');
    } else if (sinMaterias) {
      cuerpo = Center(
        child: SingleChildScrollView(
          child: EmptyState(
            icono: Icons.school_rounded,
            titulo: 'Empieza creando una materia',
            mensaje: 'Las tareas y evaluaciones se organizan por materia.',
            textoAccion: 'Crear materia',
            onAccion: () => _abrir(const MateriaFormScreen()),
          ),
        ),
      );
    } else {
      cuerpo = TabBarView(
        controller: _pestanas,
        children: [
          _ListaTareas(
            tareas: p.pendientes,
            vacio: const EmptyState(
              icono: Icons.task_alt_rounded,
              titulo: '¡Nada pendiente!',
              mensaje: 'Toca + para agregar una tarea.',
            ),
            onAlternar: _alternar,
            onRecargar: _recargar,
          ),
          _ListaTareas(
            tareas: p.completadas,
            vacio: const EmptyState(
              icono: Icons.inventory_2_outlined,
              titulo: 'Aún no completas tareas',
              mensaje: 'Marca la casilla de una tarea cuando la termines.',
            ),
            onAlternar: _alternar,
            onRecargar: _recargar,
          ),
          _ListaEvaluaciones(evaluaciones: p.evaluacionesProximas, onRecargar: _recargar),
        ],
      );
    }

    final hoy = p.entregasDeHoy;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: p.estado == EstadoCarga.listo && !sinMaterias
          ? FloatingActionButton(
              tooltip: _pestanas.index == 2 ? 'Nueva evaluación' : 'Nueva tarea',
              onPressed: () => _abrir(_pestanas.index == 2 ? const EvaluacionFormScreen() : const TareaFormScreen()),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EncabezadoModulo(
              titulo: 'SmartStudy',
              acciones: [
                IconCircleButton(icono: Icons.folder_copy_rounded, tooltip: 'Materias', onPressed: () => _abrir(const MateriasScreen())),
              ],
            ),
            if (p.estado == EstadoCarga.listo && !sinMaterias) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppMedidas.margenPantalla),
                child: StatusChip(
                  texto: hoy.total == 0 ? 'Nada para entregar hoy' : '${hoy.completadas} de ${hoy.total} entregas de hoy completadas',
                  tipo: hoy.total > 0 && hoy.completadas == hoy.total ? TipoEstado.exito : TipoEstado.neutro,
                  icono: Icons.today_rounded,
                ),
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _pestanas,
                tabs: [
                  _PestanaConContador(texto: 'Pendientes', cantidad: p.pendientes.length),
                  _PestanaConContador(texto: 'Completadas', cantidad: p.completadas.length),
                  _PestanaConContador(texto: 'Evaluaciones', cantidad: p.evaluacionesProximas.length),
                ],
              ),
            ],
            Expanded(child: cuerpo),
          ],
        ),
      ),
    );
  }
}

/// Pestaña con el número de elementos al lado (ref. 02: «Exams 0»).
class _PestanaConContador extends StatelessWidget {
  const _PestanaConContador({required this.texto, required this.cantidad});

  final String texto;
  final int cantidad;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(texto),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(color: AppColors.superficie, borderRadius: BorderRadius.circular(6)),
              child: Text('$cantidad', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaTareas extends StatelessWidget {
  const _ListaTareas({required this.tareas, required this.vacio, required this.onAlternar, required this.onRecargar});

  final List<Tarea> tareas;
  final Widget vacio;
  final ValueChanged<Tarea> onAlternar;
  final Future<void> Function() onRecargar;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SmartStudyProvider>();
    return RefreshIndicator(
      onRefresh: onRecargar,
      child: tareas.isEmpty
          ? ListView(children: [const SizedBox(height: 40), vacio])
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppMedidas.margenPantalla, 16, AppMedidas.margenPantalla, 96),
              itemCount: tareas.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final tarea = tareas[i];
                return TareaTile(
                  tarea: tarea,
                  nombreMateria: p.materia(tarea.materiaId)?.nombre ?? 'Materia',
                  colorMateria: AppColors.paletaMaterias[p.colorDe(tarea.materiaId)],
                  ocupada: p.tareasOcupadas.contains(tarea.id),
                  onAlternar: () => onAlternar(tarea),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TareaFormScreen(tarea: tarea))),
                );
              },
            ),
    );
  }
}

class _ListaEvaluaciones extends StatelessWidget {
  const _ListaEvaluaciones({required this.evaluaciones, required this.onRecargar});

  final List<Evaluacion> evaluaciones;
  final Future<void> Function() onRecargar;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SmartStudyProvider>();
    return RefreshIndicator(
      onRefresh: onRecargar,
      child: evaluaciones.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 40),
                EmptyState(
                  icono: Icons.assignment_outlined,
                  titulo: 'Sin evaluaciones próximas',
                  mensaje: 'Registra parciales y quices para no olvidarlos. Toca +.',
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppMedidas.margenPantalla, 16, AppMedidas.margenPantalla, 96),
              itemCount: evaluaciones.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final evaluacion = evaluaciones[i];
                final dias = Fechas.diasEntre(Fechas.hoy(), evaluacion.fecha);
                final color = AppColors.paletaMaterias[p.colorDe(evaluacion.materiaId)];
                return LifeCard(
                  padding: const EdgeInsets.all(16),
                  radio: AppMedidas.radioItem + 4,
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => EvaluacionFormScreen(evaluacion: evaluacion))),
                  child: Row(
                    children: [
                      IconoMateria(color: color, icono: Icons.assignment_rounded),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(evaluacion.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(
                              '${p.materia(evaluacion.materiaId)?.nombre ?? 'Materia'} · ${Fechas.conAnio(evaluacion.fecha)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(
                        texto: Fechas.relativo(evaluacion.fecha),
                        tipo: dias <= 3 ? TipoEstado.advertencia : TipoEstado.neutro,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
