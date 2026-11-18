import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lifeos/services/api_service.dart';

/// Respuesta de éxito con el formato del backend: {"ok": true, "mensaje": ..., "datos": ...}.
http.Response exito(Object? datos, {int codigo = 200, String mensaje = 'OK'}) => http.Response.bytes(
      utf8.encode(jsonEncode({'ok': true, 'mensaje': mensaje, 'datos': datos})),
      codigo,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// Respuesta de error con el formato del backend: {"ok": false, "mensaje": ..., "errores": ...}.
http.Response fallo(int codigo, String mensaje, {Map<String, String>? errores}) => http.Response.bytes(
      utf8.encode(jsonEncode({'ok': false, 'mensaje': mensaje, 'errores': errores})),
      codigo,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// Servidor falso para las pruebas: responde según "MÉTODO /ruta" y anota cada petición.
///
/// Ejemplo: ServidorFalso({'GET /api/mi-dia': (p) => exito({...})})
class ServidorFalso {
  ServidorFalso(this.rutas);

  final Map<String, http.Response Function(http.Request peticion)> rutas;
  final List<http.Request> recibidas = [];

  /// "MÉTODO /ruta" de cada petición recibida, en orden.
  List<String> get llamadas => recibidas.map((p) => '${p.method} ${p.url.path}').toList();

  /// Cuerpo JSON de la última petición a esa ruta.
  Map<String, dynamic> cuerpoDe(String clave) =>
      jsonDecode(recibidas.lastWhere((p) => '${p.method} ${p.url.path}' == clave).body) as Map<String, dynamic>;

  ApiService crearApi({String? token}) {
    final api = ApiService(
      urlBase: 'http://servidor',
      cliente: MockClient((peticion) async {
        recibidas.add(peticion);
        final clave = '${peticion.method} ${peticion.url.path}';
        final respuesta = rutas[clave];
        if (respuesta == null) return fallo(404, 'La ruta solicitada no existe');
        return respuesta(peticion);
      }),
    );
    api.token = token;
    return api;
  }
}

/// JSON de ejemplo con la forma EXACTA de GET /api/mi-dia del backend.
Map<String, dynamic> miDiaJson({
  String fecha = '2026-11-18',
  List<Map<String, dynamic>> paraHoy = const [],
  List<Map<String, dynamic>> vencidas = const [],
  List<Map<String, dynamic>> proximas = const [],
  List<Map<String, dynamic>> habitos = const [],
  int? aguaMl,
  double? horas,
  List<Map<String, dynamic>> actividades = const [],
}) {
  final completados = habitos.where((h) => h['cumplido'] == true).length;
  final minutos = actividades.fold<int>(0, (suma, a) => suma + (a['duracion_minutos'] as int));
  return {
    'fecha': fecha,
    'tareas': {
      'total_pendientes': paraHoy.length + vencidas.length + proximas.length,
      'vencidas': vencidas,
      'para_hoy': paraHoy,
      'proximas': proximas,
    },
    'evaluaciones': {'proximas': <Map<String, dynamic>>[]},
    'habitos': {
      'total': habitos.length,
      'completados': completados,
      'porcentaje': habitos.isEmpty ? 0.0 : double.parse((completados / habitos.length * 100).toStringAsFixed(1)),
      'lista': habitos,
    },
    'salud': {
      'hidratacion': {
        'cantidad_ml': aguaMl,
        'meta_ml': 2000,
        'porcentaje': aguaMl == null ? 0.0 : aguaMl / 2000 * 100,
      },
      'sueno': {'horas': horas},
      'actividades': actividades,
      'minutos_actividad': minutos,
    },
  };
}

Map<String, dynamic> tareaJson(int id, String titulo, String fecha, {int materiaId = 1, String estado = 'pendiente'}) => {
      'id': id,
      'materia_id': materiaId,
      'titulo': titulo,
      'descripcion': null,
      'fecha_entrega': fecha,
      'prioridad': 'media',
      'estado': estado,
      'fecha_creacion': '2026-11-10T15:00:00Z',
    };

const usuarioJson = {'id': 7, 'nombre': 'Ana Pérez', 'correo': 'ana@correo.com', 'fecha_creacion': '2026-11-16T15:00:00Z'};
