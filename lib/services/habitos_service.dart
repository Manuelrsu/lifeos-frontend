import '../models/habito.dart';
import '../utils/fechas.dart';
import 'api_service.dart';

/// Rutas de /api/habitos.
class HabitosService {
  HabitosService(this._api);

  final ApiService _api;

  Future<List<Habito>> listar() async {
    final datos = await _api.get('/api/habitos') as List;
    return datos.map((h) => Habito.fromJson(h as Map<String, dynamic>)).toList();
  }

  Future<Habito> crear({required String nombre, String? descripcion}) async {
    final datos = await _api.post('/api/habitos', {'nombre': nombre.trim(), 'descripcion': descripcion?.trim()});
    return Habito.fromJson(datos as Map<String, dynamic>);
  }

  /// PUT: solo se envían los campos que cambian.
  Future<Habito> actualizar(int id, {String? nombre, String? descripcion, bool? activo}) async {
    final cuerpo = <String, dynamic>{
      if (nombre != null) 'nombre': nombre.trim(),
      if (descripcion != null) 'descripcion': descripcion.trim(),
      'activo': ?activo, // `?` = solo se incluye si no es null
    };
    return Habito.fromJson(await _api.put('/api/habitos/$id', cuerpo) as Map<String, dynamic>);
  }

  /// Elimina el hábito y todo su historial.
  Future<void> eliminar(int id) => _api.delete('/api/habitos/$id');

  /// Marca el hábito como cumplido en [fecha] (no puede ser futura; ya marcado → 409).
  Future<void> marcar(int id, DateTime fecha) => _api.post('/api/habitos/$id/cumplimientos', {'fecha': Fechas.aApi(fecha)});

  /// Quita la marca de ese día (si no estaba marcado → 404).
  Future<void> desmarcar(int id, DateTime fecha) => _api.delete('/api/habitos/$id/cumplimientos/${Fechas.aApi(fecha)}');

  /// Fechas cumplidas entre [desde] y [hasta].
  Future<Set<DateTime>> historial(int id, {required DateTime desde, required DateTime hasta}) async {
    final datos = await _api.get(
      '/api/habitos/$id/historial',
      parametros: {'desde': Fechas.aApi(desde), 'hasta': Fechas.aApi(hasta)},
    ) as Map<String, dynamic>;
    return (datos['fechas'] as List).map((f) => Fechas.desdeApi(f as String)).toSet();
  }

  /// Rachas y porcentaje, calculados por el backend al día [fecha].
  Future<EstadisticasHabito> estadisticas(int id, DateTime fecha) async {
    final datos = await _api.get('/api/habitos/$id/estadisticas', parametros: {'fecha': Fechas.aApi(fecha)});
    return EstadisticasHabito.fromJson(datos as Map<String, dynamic>);
  }
}
