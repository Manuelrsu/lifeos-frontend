import 'package:flutter/foundation.dart';

import '../models/evaluacion.dart';
import '../models/materia.dart';
import '../models/tarea.dart';
import '../services/api_service.dart';
import '../services/preferencias_service.dart';
import '../services/smartstudy_service.dart';
import '../utils/fechas.dart';
import 'estado_carga.dart';

/// Estado de SmartStudy: materias, tareas y evaluaciones del usuario.
class SmartStudyProvider extends ChangeNotifier {
  SmartStudyProvider({required this._servicio, required this._preferencias});

  final SmartStudyService _servicio;
  final PreferenciasService _preferencias;

  EstadoCarga estado = EstadoCarga.inicial;
  String? mensajeError;

  List<Materia> materias = [];
  List<Tarea> tareas = [];
  List<Evaluacion> evaluaciones = [];

  /// Color elegido para cada materia (índice de AppColors.paletaMaterias, guardado en el teléfono).
  Map<int, int> colores = {};

  /// Tareas que se están marcando ahora mismo.
  final Set<int> tareasOcupadas = {};

  // ---------- Listas derivadas ----------

  /// Pendientes: de la entrega más cercana (o más vencida) a la más lejana.
  List<Tarea> get pendientes => tareas.where((t) => !t.completada).toList()..sort((a, b) => a.fechaEntrega.compareTo(b.fechaEntrega));

  /// Completadas: las más recientes primero.
  List<Tarea> get completadas => tareas.where((t) => t.completada).toList()..sort((a, b) => b.fechaEntrega.compareTo(a.fechaEntrega));

  /// Evaluaciones desde hoy en adelante, por fecha.
  List<Evaluacion> get evaluacionesProximas {
    final hoy = Fechas.hoy();
    return evaluaciones.where((e) => Fechas.diasEntre(hoy, e.fecha) >= 0).toList()..sort((a, b) => a.fecha.compareTo(b.fecha));
  }

  /// Tareas con entrega hoy: cuántas hay y cuántas están completadas (para el chip del día).
  ({int total, int completadas}) get entregasDeHoy {
    final hoy = Fechas.hoy();
    final deHoy = tareas.where((t) => Fechas.diasEntre(hoy, t.fechaEntrega) == 0);
    return (total: deHoy.length, completadas: deHoy.where((t) => t.completada).length);
  }

  Materia? materia(int id) {
    for (final m in materias) {
      if (m.id == id) return m;
    }
    return null;
  }

  int colorDe(int idMateria) => colores[idMateria] ?? 0;

  // ---------- Carga ----------

  Future<void> cargar({bool silencioso = false}) async {
    if (!silencioso || estado != EstadoCarga.listo) {
      estado = EstadoCarga.cargando;
      notifyListeners();
    }
    try {
      final resultados = await Future.wait([
        _servicio.listarMaterias(),
        _servicio.listarTareas(),
        _servicio.listarEvaluaciones(),
      ]);
      materias = resultados[0] as List<Materia>;
      tareas = resultados[1] as List<Tarea>;
      evaluaciones = resultados[2] as List<Evaluacion>;
      colores = await _preferencias.coloresMaterias(materias.map((m) => m.id));
      estado = EstadoCarga.listo;
      mensajeError = null;
    } on ApiException catch (e) {
      mensajeError = e.mensaje;
      if (estado != EstadoCarga.listo || !silencioso) estado = EstadoCarga.error;
      notifyListeners();
      if (silencioso) rethrow;
      return;
    }
    notifyListeners();
  }

  // ---------- Tareas ----------

  /// Marca una tarea como completada o pendiente (PATCH) y usa lo que devuelve el servidor.
  Future<void> alternarTarea(Tarea tarea) async {
    tareasOcupadas.add(tarea.id);
    notifyListeners();
    try {
      final actualizada = await _servicio.cambiarEstado(tarea.id, completada: !tarea.completada);
      _reemplazarTarea(actualizada);
    } finally {
      tareasOcupadas.remove(tarea.id);
      notifyListeners();
    }
  }

  /// Crea (si id == 0) o actualiza una tarea.
  Future<void> guardarTarea(Tarea tarea) async {
    if (tarea.id == 0) {
      tareas = [...tareas, await _servicio.crearTarea(tarea)];
    } else {
      _reemplazarTarea(await _servicio.actualizarTarea(tarea));
    }
    notifyListeners();
  }

  Future<void> eliminarTarea(int id) async {
    await _servicio.eliminarTarea(id);
    tareas = tareas.where((t) => t.id != id).toList();
    notifyListeners();
  }

  void _reemplazarTarea(Tarea nueva) {
    tareas = [for (final t in tareas) t.id == nueva.id ? nueva : t];
  }

  // ---------- Materias ----------

  Future<Materia> guardarMateria({int? id, required String nombre, String? docente, required int color}) async {
    final materia = id == null
        ? await _servicio.crearMateria(nombre: nombre, docente: docente)
        : await _servicio.actualizarMateria(id, nombre: nombre, docente: docente);
    // El color solo se guarda en el teléfono (el backend no tiene ese campo)
    await _preferencias.guardarColorMateria(materia.id, color);
    colores = {...colores, materia.id: color};
    materias = id == null ? [...materias, materia] : [for (final m in materias) m.id == id ? materia : m];
    materias.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    notifyListeners();
    return materia;
  }

  /// Elimina la materia. El backend borra en cascada sus tareas y evaluaciones.
  Future<void> eliminarMateria(int id) async {
    await _servicio.eliminarMateria(id);
    await _preferencias.borrarColorMateria(id);
    materias = materias.where((m) => m.id != id).toList();
    tareas = tareas.where((t) => t.materiaId != id).toList();
    evaluaciones = evaluaciones.where((e) => e.materiaId != id).toList();
    notifyListeners();
  }

  // ---------- Evaluaciones ----------

  Future<void> guardarEvaluacion(Evaluacion evaluacion) async {
    if (evaluacion.id == 0) {
      evaluaciones = [...evaluaciones, await _servicio.crearEvaluacion(evaluacion)];
    } else {
      final nueva = await _servicio.actualizarEvaluacion(evaluacion);
      evaluaciones = [for (final e in evaluaciones) e.id == nueva.id ? nueva : e];
    }
    notifyListeners();
  }

  Future<void> eliminarEvaluacion(int id) async {
    await _servicio.eliminarEvaluacion(id);
    evaluaciones = evaluaciones.where((e) => e.id != id).toList();
    notifyListeners();
  }

  void limpiar() {
    estado = EstadoCarga.inicial;
    materias = [];
    tareas = [];
    evaluaciones = [];
    colores = {};
    notifyListeners();
  }
}
