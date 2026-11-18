import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Error de la API ya traducido a un mensaje amable en español.
/// Las pantallas solo muestran [mensaje] (y [errores] junto a cada campo).
class ApiException implements Exception {
  ApiException(this.mensaje, {this.codigo, this.errores = const {}});

  final String mensaje;

  /// Código HTTP (null si ni siquiera hubo respuesta, por ejemplo sin conexión).
  final int? codigo;

  /// Errores por campo que manda el backend en 422: {"correo": "El correo..."}.
  final Map<String, String> errores;

  bool get sinConexion => codigo == null;

  @override
  String toString() => mensaje;
}

/// Cliente HTTP único de la app. Todas las peticiones pasan por aquí:
/// agrega el token, pone un tiempo máximo y convierte cualquier fallo en ApiException.
///
/// El backend siempre responde así:
///   éxito → {"ok": true,  "mensaje": "...", "datos": ...}
///   error → {"ok": false, "mensaje": "...", "errores": {...} | null}
class ApiService {
  ApiService({http.Client? cliente, this.urlBase = ApiConfig.urlBase, this.tiempoEspera = ApiConfig.tiempoEspera})
      : _cliente = cliente ?? http.Client();

  final http.Client _cliente;
  final String urlBase;
  final Duration tiempoEspera;

  /// Token JWT de la sesión actual (null si no hay sesión).
  String? token;

  /// Se llama cuando una ruta privada responde 401: la sesión ya no sirve.
  /// AuthProvider lo usa para borrar el token y volver al login.
  void Function(String mensaje)? alExpirarSesion;

  Future<dynamic> get(String ruta, {Map<String, String>? parametros}) => _enviar('GET', ruta, parametros: parametros);

  Future<dynamic> post(String ruta, [Map<String, dynamic>? cuerpo]) => _enviar('POST', ruta, cuerpo: cuerpo);

  Future<dynamic> put(String ruta, Map<String, dynamic> cuerpo) => _enviar('PUT', ruta, cuerpo: cuerpo);

  Future<dynamic> patch(String ruta, Map<String, dynamic> cuerpo) => _enviar('PATCH', ruta, cuerpo: cuerpo);

  Future<dynamic> delete(String ruta) => _enviar('DELETE', ruta);

  /// Hace la petición y devuelve `datos` si todo salió bien.
  Future<dynamic> _enviar(
    String metodo,
    String ruta, {
    Map<String, dynamic>? cuerpo,
    Map<String, String>? parametros,
  }) async {
    final url = Uri.parse('$urlBase$ruta').replace(queryParameters: parametros);
    final peticion = http.Request(metodo, url);
    peticion.headers['Accept'] = 'application/json';
    if (token != null) peticion.headers['Authorization'] = 'Bearer $token';
    if (cuerpo != null) {
      peticion.headers['Content-Type'] = 'application/json; charset=utf-8';
      peticion.body = jsonEncode(cuerpo);
    }

    final http.Response respuesta;
    try {
      final enviada = await _cliente.send(peticion).timeout(tiempoEspera);
      respuesta = await http.Response.fromStream(enviada).timeout(tiempoEspera);
    } on TimeoutException {
      throw ApiException('El servidor tardó demasiado en responder. Revisa que el backend esté encendido e intenta de nuevo.');
    } on SocketException {
      throw ApiException('No se pudo conectar con el servidor. Revisa tu conexión y que el backend esté encendido.');
    } on http.ClientException {
      throw ApiException('No se pudo conectar con el servidor. Revisa tu conexión y que el backend esté encendido.');
    }

    return _procesar(respuesta, rutaPrivada: token != null);
  }

  dynamic _procesar(http.Response respuesta, {required bool rutaPrivada}) {
    final codigo = respuesta.statusCode;
    Map<String, dynamic>? json;
    try {
      // utf8.decode para que las tildes y la ñ lleguen bien
      final decodificado = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (decodificado is Map<String, dynamic>) json = decodificado;
    } on FormatException {
      json = null; // la respuesta no era JSON (por ejemplo, una página de error)
    }

    if (codigo >= 200 && codigo < 300 && json != null && json['ok'] == true) {
      return json['datos'];
    }

    final mensaje = _mensajeDeError(codigo, json?['mensaje'] as String?);
    final errores = <String, String>{};
    final erroresJson = json?['errores'];
    if (erroresJson is Map) {
      erroresJson.forEach((campo, detalle) => errores['$campo'] = '$detalle');
    }

    // 401 en una ruta privada: la sesión expiró o fue cerrada
    if (codigo == 401 && rutaPrivada) {
      token = null;
      alExpirarSesion?.call(mensaje);
    }
    throw ApiException(mensaje, codigo: codigo, errores: errores);
  }

  /// Mensaje amable para cada código. Si el backend ya manda uno claro, se usa ese.
  String _mensajeDeError(int codigo, String? delServidor) {
    if (codigo >= 500 && codigo != 503) {
      return 'Ocurrió un error en el servidor. Intenta de nuevo en unos minutos.';
    }
    if (delServidor != null && delServidor.isNotEmpty) return delServidor;
    return switch (codigo) {
      400 => 'La petición no es válida.',
      401 => 'Tu sesión expiró. Inicia sesión de nuevo.',
      404 => 'No se encontró lo que buscabas.',
      409 => 'Ya existe un registro con esos datos.',
      413 => 'Los datos enviados son demasiado grandes.',
      422 => 'Revisa los datos del formulario.',
      503 => 'El servidor no puede conectarse a la base de datos en este momento.',
      _ => 'Ocurrió un error inesperado ($codigo).',
    };
  }
}
