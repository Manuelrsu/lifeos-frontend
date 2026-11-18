import '../models/resumen_dia.dart';
import '../utils/fechas.dart';
import 'api_service.dart';
import 'habitos_service.dart';

/// Mi Día: el backend arma el resumen leyendo los demás módulos (sin tablas propias).
class MiDiaService {
  MiDiaService(this._api, this._habitos);

  final ApiService _api;
  final HabitosService _habitos;

  /// GET /api/mi-dia?fecha=YYYY-MM-DD (se envía la fecha del teléfono).
  Future<ResumenDia> obtener(DateTime fecha) async {
    final datos = await _api.get('/api/mi-dia', parametros: {'fecha': Fechas.aApi(fecha)});
    return ResumenDia.fromJson(datos as Map<String, dynamic>);
  }

  /// La mejor racha ACTUAL entre los hábitos indicados (para el chip 🔥).
  /// El resumen de Mi Día no la trae, así que se piden las estadísticas de cada hábito
  /// (ver docs/PENDIENTES_BACKEND.md, punto 3).
  Future<int> mejorRachaActual(List<int> idsHabitos, DateTime fecha) async {
    if (idsHabitos.isEmpty) return 0;
    final estadisticas = await Future.wait(idsHabitos.map((id) => _habitos.estadisticas(id, fecha)));
    return estadisticas.map((e) => e.rachaActual).fold<int>(0, (mayor, racha) => racha > mayor ? racha : mayor);
  }
}
