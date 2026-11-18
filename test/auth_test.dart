import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lifeos/models/usuario.dart';
import 'package:lifeos/providers/auth_provider.dart';
import 'package:lifeos/screens/auth/login_screen.dart';
import 'package:lifeos/screens/auth/registro_screen.dart';
import 'package:lifeos/services/almacen_sesion.dart';
import 'package:lifeos/services/api_service.dart';
import 'package:lifeos/services/auth_service.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/utils/validadores.dart';
import 'package:provider/provider.dart';

http.Response jsonResp(Object cuerpo, int codigo) =>
    http.Response.bytes(utf8.encode(jsonEncode(cuerpo)), codigo, headers: {'content-type': 'application/json'});

const usuarioJson = {'id': 7, 'nombre': 'Ana María Pérez', 'correo': 'ana@correo.com', 'fecha_creacion': '2026-11-16T15:00:00Z'};

/// Crea un AuthProvider con un servidor falso (MockClient).
AuthProvider crearProvider(Future<http.Response> Function(http.Request) servidor) {
  final api = ApiService(urlBase: 'http://servidor', cliente: MockClient(servidor));
  return AuthProvider(api: api, servicio: AuthService(api), almacen: AlmacenSesion());
}

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('Modelo Usuario', () {
    test('fromJson lee los campos del backend', () {
      final usuario = Usuario.fromJson(usuarioJson);
      expect(usuario.id, 7);
      expect(usuario.nombre, 'Ana María Pérez');
      expect(usuario.correo, 'ana@correo.com');
      expect(usuario.fechaCreacion, DateTime.utc(2026, 11, 16, 15));
      expect(usuario.fechaCreacion!.isUtc, isTrue);
    });

    test('iniciales y primer nombre', () {
      final usuario = Usuario.fromJson(usuarioJson);
      expect(usuario.iniciales, 'AP');
      expect(usuario.primerNombre, 'Ana');
      expect(const Usuario(id: 1, nombre: 'luis', correo: 'l@x.co').iniciales, 'L');
    });
  });

  group('Validadores (mismas reglas que el backend)', () {
    test('nombre', () {
      expect(Validadores.nombre(''), 'El nombre es obligatorio');
      expect(Validadores.nombre('A'), contains('entre 2 y 100'));
      expect(Validadores.nombre('Ana'), isNull);
    });

    test('correo', () {
      expect(Validadores.correo(''), 'El correo es obligatorio');
      expect(Validadores.correo('ana@correo'), 'El correo no tiene un formato válido');
      expect(Validadores.correo('ana correo@x.co'), 'El correo no tiene un formato válido');
      expect(Validadores.correo(' ana@correo.com '), isNull);
    });

    test('contraseña nueva', () {
      expect(Validadores.contrasenaNueva('abc12'), contains('al menos 8'));
      expect(Validadores.contrasenaNueva('solamenteletras'), contains('letras y números'));
      expect(Validadores.contrasenaNueva('12345678'), contains('letras y números'));
      expect(Validadores.contrasenaNueva('a' * 129 + '1'), contains('como máximo 128'));
      expect(Validadores.contrasenaNueva('clave1234'), isNull);
    });

    test('confirmación', () {
      expect(Validadores.confirmacion('clave1234', 'clave12345'), 'Las contraseñas no coinciden');
      expect(Validadores.confirmacion('clave1234', 'clave1234'), isNull);
    });

    test('horas de sueño y enteros', () {
      expect(Validadores.horasSueno('7,5'), isNull);
      expect(Validadores.horasSueno('0'), contains('mayor que 0'));
      expect(Validadores.horasSueno('25'), contains('como máximo 24'));
      expect(Validadores.horasSueno('7.123'), contains('2 decimales'));
      expect(Validadores.entero('0', minimo: 1, maximo: 1440), contains('entre 1 y 1440'));
      expect(Validadores.entero('45', minimo: 1, maximo: 1440), isNull);
    });
  });

  group('AuthProvider', () {
    test('sin token guardado → sinSesion', () async {
      final auth = crearProvider((_) async => throw StateError('no debería llamar al servidor'));
      await auth.cargarSesionGuardada();
      expect(auth.estado, EstadoSesion.sinSesion);
    });

    test('login guarda el token y deja la sesión abierta', () async {
      final auth = crearProvider((peticion) async {
        expect(peticion.url.path, '/api/auth/login');
        return jsonResp({
          'ok': true,
          'mensaje': 'Inicio de sesión exitoso',
          'datos': {'token': 'tok-1', 'tipo': 'Bearer', 'expira_en_segundos': 86400, 'usuario': usuarioJson},
        }, 200);
      });

      await auth.iniciarSesion(correo: 'ana@correo.com', contrasena: 'clave1234');

      expect(auth.estado, EstadoSesion.conSesion);
      expect(auth.usuario!.nombre, 'Ana María Pérez');
      expect(await AlmacenSesion().leerToken(), 'tok-1');
    });

    test('token guardado válido → conSesion (pide el perfil con el token)', () async {
      FlutterSecureStorage.setMockInitialValues({'token_lifeos': 'tok-guardado'});
      final auth = crearProvider((peticion) async {
        expect(peticion.headers['Authorization'], 'Bearer tok-guardado');
        return jsonResp({'ok': true, 'mensaje': 'Perfil del usuario', 'datos': usuarioJson}, 200);
      });
      await auth.cargarSesionGuardada();
      expect(auth.estado, EstadoSesion.conSesion);
    });

    test('token guardado vencido (401) → se borra y queda sinSesion con aviso', () async {
      FlutterSecureStorage.setMockInitialValues({'token_lifeos': 'tok-viejo'});
      final auth = crearProvider(
        (_) async => jsonResp({'ok': false, 'mensaje': 'El token ha expirado, inicia sesión de nuevo', 'errores': null}, 401),
      );
      await auth.cargarSesionGuardada();
      await Future<void>.delayed(Duration.zero);
      expect(auth.estado, EstadoSesion.sinSesion);
      expect(auth.avisoPendiente, contains('expirado'));
      expect(await AlmacenSesion().leerToken(), isNull);
    });

    test('servidor apagado con token guardado → errorConexion (no borra el token)', () async {
      FlutterSecureStorage.setMockInitialValues({'token_lifeos': 'tok-guardado'});
      final auth = crearProvider((_) async => throw http.ClientException('Connection refused'));
      await auth.cargarSesionGuardada();
      expect(auth.estado, EstadoSesion.errorConexion);
      expect(await AlmacenSesion().leerToken(), 'tok-guardado');
    });

    test('cerrar sesión llama al logout y borra el token aunque el servidor falle', () async {
      FlutterSecureStorage.setMockInitialValues({'token_lifeos': 'tok'});
      final rutas = <String>[];
      final auth = crearProvider((peticion) async {
        rutas.add(peticion.url.path);
        if (peticion.url.path == '/api/usuarios/me') return jsonResp({'ok': true, 'mensaje': 'OK', 'datos': usuarioJson}, 200);
        throw http.ClientException('sin red');
      });
      await auth.cargarSesionGuardada();
      await auth.cerrarSesion();
      expect(rutas, contains('/api/auth/logout'));
      expect(auth.estado, EstadoSesion.sinSesion);
      expect(await AlmacenSesion().leerToken(), isNull);
    });
  });

  group('Formularios', () {
    Widget pantalla(Widget hijo, AuthProvider auth) => ChangeNotifierProvider.value(
          value: auth,
          child: MaterialApp(theme: crearTemaOscuro(), home: hijo),
        );

    testWidgets('login: valida campos vacíos sin llamar al servidor', (tester) async {
      var llamadas = 0;
      final auth = crearProvider((_) async {
        llamadas++;
        return jsonResp({}, 500);
      });
      await tester.pumpWidget(pantalla(const LoginScreen(), auth));
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pump();
      expect(find.text('El correo es obligatorio'), findsOneWidget);
      expect(find.text('La contraseña es obligatoria'), findsOneWidget);
      expect(llamadas, 0);
    });

    testWidgets('login: muestra el mensaje del servidor si las credenciales fallan', (tester) async {
      final auth = crearProvider(
        (_) async => jsonResp({'ok': false, 'mensaje': 'Correo o contraseña incorrectos', 'errores': null}, 401),
      );
      await tester.pumpWidget(pantalla(const LoginScreen(), auth));
      await tester.enterText(find.widgetWithText(TextFormField, 'Correo'), 'ana@correo.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), 'mala1234');
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
    });

    testWidgets('registro: contraseñas distintas y correo duplicado (409)', (tester) async {
      final auth = crearProvider((_) async => jsonResp({'ok': false, 'mensaje': 'El correo ya está registrado', 'errores': null}, 409));
      await tester.pumpWidget(pantalla(const RegistroScreen(), auth));

      await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), 'Ana');
      await tester.enterText(find.widgetWithText(TextFormField, 'Correo'), 'ana@correo.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), 'clave1234');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirmar contraseña'), 'otra1234');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pump();
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Confirmar contraseña'), 'clave1234');
      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('El correo ya está registrado'), findsOneWidget);
    });
  });
}
