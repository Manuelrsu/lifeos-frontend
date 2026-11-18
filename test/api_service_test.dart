import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lifeos/services/api_service.dart';

/// Respuesta JSON como la manda Flask (con tildes en UTF-8).
http.Response jsonResp(Map<String, dynamic> cuerpo, int codigo) => http.Response.bytes(
      utf8.encode(jsonEncode(cuerpo)),
      codigo,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  group('ApiService', () {
    test('éxito: devuelve "datos" y envía el token y el JSON', () async {
      late http.Request recibida;
      final api = ApiService(
        urlBase: 'http://servidor',
        cliente: MockClient((peticion) async {
          recibida = peticion;
          return jsonResp({'ok': true, 'mensaje': 'Materia creada correctamente', 'datos': {'id': 1, 'nombre': 'Cálculo'}}, 201);
        }),
      );
      api.token = 'abc123';

      final datos = await api.post('/api/smartstudy/materias', {'nombre': 'Cálculo'});

      expect(datos, {'id': 1, 'nombre': 'Cálculo'});
      expect(recibida.method, 'POST');
      expect(recibida.url.toString(), 'http://servidor/api/smartstudy/materias');
      expect(recibida.headers['Authorization'], 'Bearer abc123');
      expect(recibida.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(recibida.body), {'nombre': 'Cálculo'});
    });

    test('agrega los parámetros de la URL', () async {
      late Uri url;
      final api = ApiService(
        urlBase: 'http://servidor',
        cliente: MockClient((peticion) async {
          url = peticion.url;
          return jsonResp({'ok': true, 'mensaje': 'OK', 'datos': []}, 200);
        }),
      );
      await api.get('/api/mi-dia', parametros: {'fecha': '2026-11-18'});
      expect(url.queryParameters, {'fecha': '2026-11-18'});
    });

    test('401 en ruta privada: borra el token y avisa que la sesión expiró', () async {
      String? aviso;
      final api = ApiService(
        urlBase: 'http://servidor',
        cliente: MockClient(
          (_) async => jsonResp({'ok': false, 'mensaje': 'El token ha expirado, inicia sesión de nuevo', 'errores': null}, 401),
        ),
      );
      api.token = 'viejo';
      api.alExpirarSesion = (mensaje) => aviso = mensaje;

      await expectLater(
        api.get('/api/usuarios/me'),
        throwsA(isA<ApiException>().having((e) => e.codigo, 'codigo', 401)),
      );
      expect(api.token, isNull);
      expect(aviso, 'El token ha expirado, inicia sesión de nuevo');
    });

    test('401 en el login (sin token) NO dispara el cierre de sesión', () async {
      var llamado = false;
      final api = ApiService(
        urlBase: 'http://servidor',
        cliente: MockClient((_) async => jsonResp({'ok': false, 'mensaje': 'Correo o contraseña incorrectos', 'errores': null}, 401)),
      );
      api.alExpirarSesion = (_) => llamado = true;

      await expectLater(
        api.post('/api/auth/login', {'correo': 'a@b.co', 'contrasena': 'x'}),
        throwsA(isA<ApiException>().having((e) => e.mensaje, 'mensaje', 'Correo o contraseña incorrectos')),
      );
      expect(llamado, isFalse);
    });

    test('400: usa el mensaje del backend', () async {
      final api = ApiService(
        urlBase: 'http://servidor',
        cliente: MockClient((_) async => jsonResp({'ok': false, 'mensaje': 'Se esperaba un cuerpo JSON válido', 'errores': null}, 400)),
      );
      await expectLater(
        api.post('/api/auth/registro', {}),
        throwsA(isA<ApiException>()
            .having((e) => e.codigo, 'codigo', 400)
            .having((e) => e.mensaje, 'mensaje', 'Se esperaba un cuerpo JSON válido')),
      );
    });

    test('422: entrega los errores por campo', () async {
      final api = ApiService(
        urlBase: 'http://servidor',
        cliente: MockClient((_) async => jsonResp({
              'ok': false,
              'mensaje': 'Datos de registro inválidos',
              'errores': {'correo': 'El correo no tiene un formato válido'},
            }, 422)),
      );
      await expectLater(
        api.post('/api/auth/registro', {'correo': 'malo'}),
        throwsA(isA<ApiException>().having((e) => e.errores['correo'], 'error de correo', 'El correo no tiene un formato válido')),
      );
    });

    test('500: mensaje amable, sin detalles técnicos', () async {
      final api = ApiService(urlBase: 'http://servidor', cliente: MockClient((_) async => http.Response('<html>Traceback...</html>', 500)));
      await expectLater(
        api.get('/api/estado'),
        throwsA(isA<ApiException>().having((e) => e.mensaje, 'mensaje', allOf(contains('error en el servidor'), isNot(contains('Traceback'))))),
      );
    });

    test('sin conexión: error claro y sin código HTTP', () async {
      final api = ApiService(
        urlBase: 'http://servidor',
        cliente: MockClient((_) async => throw const SocketException('Connection refused')),
      );
      await expectLater(
        api.get('/api/estado'),
        throwsA(isA<ApiException>()
            .having((e) => e.sinConexion, 'sinConexion', isTrue)
            .having((e) => e.mensaje, 'mensaje', contains('No se pudo conectar'))),
      );
    });

    test('tiempo de espera agotado: error claro', () async {
      final api = ApiService(
        urlBase: 'http://servidor',
        tiempoEspera: const Duration(milliseconds: 50),
        cliente: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          return jsonResp({'ok': true, 'mensaje': 'OK', 'datos': null}, 200);
        }),
      );
      await expectLater(
        api.get('/api/estado'),
        throwsA(isA<ApiException>().having((e) => e.mensaje, 'mensaje', contains('tardó demasiado'))),
      );
    });
  });
}
