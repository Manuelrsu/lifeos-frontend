import '../models/salud.dart';
import '../utils/fechas.dart';
import 'api_service.dart';

/// Rutas de /api/salud: hidratación, sueño, actividades y estadísticas.
class SaludService {
  SaludService(this._api);

  final ApiService _api;

  static const int maximoAguaMl = 10000; // límite del backend

  // ---------- Hidratación ----------

  /// Registro de agua de un día, o null si ese día no tiene registro (404).
  Future<RegistroHidratacion?> aguaDelDia(DateTime fecha) async {
    try {
      final datos = await _api.get('/api/salud/hidratacion/${Fechas.aApi(fecha)}');
      return RegistroHidratacion.fromJson(datos as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.codigo == 404) return null;
      rethrow;
    }
  }

  Future<List<RegistroHidratacion>> historialAgua({required DateTime desde, required DateTime hasta}) async {
    final datos = await _api.get('/api/salud/hidratacion', parametros: _rango(desde, hasta)) as List;
    return datos.map((r) => RegistroHidratacion.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Suma (o resta) agua al total del día.
  /// El backend guarda UN total por día: si no existe se crea con POST; si existe se reemplaza con PUT.
  Future<RegistroHidratacion> cambiarAgua(DateTime fecha, int diferenciaMl) async {
    final actual = await aguaDelDia(fecha);
    if (actual == null) {
      final inicial = diferenciaMl.clamp(0, maximoAguaMl);
      final datos = await _api.post('/api/salud/hidratacion', {'cantidad_ml': inicial, 'fecha': Fechas.aApi(fecha)});
      return RegistroHidratacion.fromJson(datos as Map<String, dynamic>);
    }
    final nuevo = (actual.cantidadMl + diferenciaMl).clamp(0, maximoAguaMl);
    final datos = await _api.put('/api/salud/hidratacion/${Fechas.aApi(fecha)}', {'cantidad_ml': nuevo});
    return RegistroHidratacion.fromJson(datos as Map<String, dynamic>);
  }

  // ---------- Sueño ----------

  Future<List<RegistroSueno>> historialSueno({required DateTime desde, required DateTime hasta}) async {
    final datos = await _api.get('/api/salud/sueno', parametros: _rango(desde, hasta)) as List;
    return datos.map((r) => RegistroSueno.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Crea o reemplaza las horas de sueño de un día (POST; si ya existe → PUT).
  Future<RegistroSueno> guardarSueno(DateTime fecha, double horas, {required bool yaExiste}) async {
    final dynamic datos;
    if (yaExiste) {
      datos = await _api.put('/api/salud/sueno/${Fechas.aApi(fecha)}', {'horas': horas});
    } else {
      datos = await _api.post('/api/salud/sueno', {'horas': horas, 'fecha': Fechas.aApi(fecha)});
    }
    return RegistroSueno.fromJson(datos as Map<String, dynamic>);
  }

  Future<void> eliminarSueno(DateTime fecha) => _api.delete('/api/salud/sueno/${Fechas.aApi(fecha)}');

  // ---------- Actividades y entrenamientos ----------

  Future<List<Actividad>> historialActividades({required DateTime desde, required DateTime hasta}) async {
    final datos = await _api.get('/api/salud/actividades', parametros: _rango(desde, hasta)) as List;
    return datos.map((a) => Actividad.fromJson(a as Map<String, dynamic>)).toList();
  }

  Future<Actividad> crearActividad({
    required String tipo,
    required int duracionMinutos,
    required DateTime fecha,
    String? descripcion,
  }) async {
    final datos = await _api.post('/api/salud/actividades', {
      'tipo': tipo.trim(),
      'duracion_minutos': duracionMinutos,
      'fecha': Fechas.aApi(fecha),
      'descripcion': (descripcion?.trim().isEmpty ?? true) ? null : descripcion!.trim(),
    });
    return Actividad.fromJson(datos as Map<String, dynamic>);
  }

  Future<Actividad> actualizarActividad(
    int id, {
    required String tipo,
    required int duracionMinutos,
    required DateTime fecha,
    String? descripcion,
  }) async {
    final datos = await _api.put('/api/salud/actividades/$id', {
      'tipo': tipo.trim(),
      'duracion_minutos': duracionMinutos,
      'fecha': Fechas.aApi(fecha),
      'descripcion': descripcion?.trim() ?? '',
    });
    return Actividad.fromJson(datos as Map<String, dynamic>);
  }

  Future<void> eliminarActividad(int id) => _api.delete('/api/salud/actividades/$id');

  // ---------- Estadísticas ----------

  /// Estadísticas de los últimos [dias] días terminando en [fecha].
  Future<EstadisticasSalud> estadisticas({required DateTime fecha, int dias = 7}) async {
    final datos = await _api.get('/api/salud/estadisticas', parametros: {'dias': '$dias', 'fecha': Fechas.aApi(fecha)});
    return EstadisticasSalud.fromJson(datos as Map<String, dynamic>);
  }

  Map<String, String> _rango(DateTime desde, DateTime hasta) => {'desde': Fechas.aApi(desde), 'hasta': Fechas.aApi(hasta)};
}
