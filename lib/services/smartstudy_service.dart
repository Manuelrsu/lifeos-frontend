import '../models/evaluacion.dart';
import '../models/materia.dart';
import '../models/tarea.dart';
import 'api_service.dart';

/// Rutas de /api/smartstudy: materias, tareas y evaluaciones.
class SmartStudyService {
  SmartStudyService(this._api);

  final ApiService _api;
  static const _base = '/api/smartstudy';

  // ---------- Materias ----------

  Future<List<Materia>> listarMaterias() async {
    final datos = await _api.get('$_base/materias') as List;
    return datos.map((m) => Materia.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<Materia> crearMateria({required String nombre, String? docente}) async {
    final datos = await _api.post('$_base/materias', {'nombre': nombre.trim(), 'docente': _vacioANulo(docente)});
    return Materia.fromJson(datos as Map<String, dynamic>);
  }

  Future<Materia> actualizarMateria(int id, {required String nombre, String? docente}) async {
    // docente "" en el backend significa «sin docente»
    final datos = await _api.put('$_base/materias/$id', {'nombre': nombre.trim(), 'docente': docente?.trim() ?? ''});
    return Materia.fromJson(datos as Map<String, dynamic>);
  }

  /// Elimina la materia y, en cascada, sus tareas y evaluaciones.
  Future<void> eliminarMateria(int id) => _api.delete('$_base/materias/$id');

  // ---------- Tareas ----------

  /// Todas las tareas (pendientes y completadas), ordenadas por fecha de entrega.
  Future<List<Tarea>> listarTareas() async {
    final datos = await _api.get('$_base/tareas') as List;
    return datos.map((t) => Tarea.fromJson(t as Map<String, dynamic>)).toList();
  }

  Future<Tarea> crearTarea(Tarea tarea) async {
    final cuerpo = tarea.toJson()..['descripcion'] = _vacioANulo(tarea.descripcion);
    return Tarea.fromJson(await _api.post('$_base/tareas', cuerpo) as Map<String, dynamic>);
  }

  Future<Tarea> actualizarTarea(Tarea tarea) async {
    final cuerpo = tarea.toJson()..['descripcion'] = tarea.descripcion?.trim() ?? '';
    return Tarea.fromJson(await _api.put('$_base/tareas/${tarea.id}', cuerpo) as Map<String, dynamic>);
  }

  /// PATCH del estado: «pendiente» o «completada».
  Future<Tarea> cambiarEstado(int id, {required bool completada}) async {
    final datos = await _api.patch('$_base/tareas/$id/estado', {'estado': completada ? 'completada' : 'pendiente'});
    return Tarea.fromJson(datos as Map<String, dynamic>);
  }

  Future<void> eliminarTarea(int id) => _api.delete('$_base/tareas/$id');

  // ---------- Evaluaciones ----------

  Future<List<Evaluacion>> listarEvaluaciones() async {
    final datos = await _api.get('$_base/evaluaciones') as List;
    return datos.map((e) => Evaluacion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Evaluacion> crearEvaluacion(Evaluacion evaluacion) async {
    final cuerpo = evaluacion.toJson()..['descripcion'] = _vacioANulo(evaluacion.descripcion);
    return Evaluacion.fromJson(await _api.post('$_base/evaluaciones', cuerpo) as Map<String, dynamic>);
  }

  Future<Evaluacion> actualizarEvaluacion(Evaluacion evaluacion) async {
    final cuerpo = evaluacion.toJson()..['descripcion'] = evaluacion.descripcion?.trim() ?? '';
    return Evaluacion.fromJson(await _api.put('$_base/evaluaciones/${evaluacion.id}', cuerpo) as Map<String, dynamic>);
  }

  Future<void> eliminarEvaluacion(int id) => _api.delete('$_base/evaluaciones/$id');

  String? _vacioANulo(String? texto) => (texto == null || texto.trim().isEmpty) ? null : texto.trim();
}
