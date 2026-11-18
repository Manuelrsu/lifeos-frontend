import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lifeos/main.dart';
import 'package:lifeos/models/resumen_dia.dart';
import 'package:lifeos/services/almacen_sesion.dart';
import 'package:lifeos/services/habitos_service.dart';
import 'package:lifeos/services/mi_dia_service.dart';
import 'package:lifeos/services/salud_service.dart';
import 'package:lifeos/services/servicios.dart';
import 'package:lifeos/utils/fechas.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ayudantes.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));

  group('Modelo ResumenDia', () {
    test('lee la respuesta completa de /api/mi-dia', () {
      final resumen = ResumenDia.fromJson(miDiaJson(
        vencidas: [tareaJson(1, 'Informe', '2026-11-15')],
        paraHoy: [tareaJson(2, 'Taller', '2026-11-18')],
        proximas: [tareaJson(3, 'Quiz', '2026-11-20')],
        habitos: [
          {'id': 1, 'nombre': 'Leer', 'cumplido': true},
          {'id': 2, 'nombre': 'Meditar', 'cumplido': false},
        ],
        aguaMl: 1500,
        horas: 7.5,
        actividades: [
          {'id': 9, 'fecha': '2026-11-18', 'tipo': 'correr', 'duracion_minutos': 45, 'descripcion': null, 'fecha_creacion': '2026-11-18T12:00:00Z'},
        ],
      ));

      expect(resumen.fecha, DateTime(2026, 11, 18));
      expect(resumen.totalPendientes, 3);
      expect(resumen.entregas.map((t) => t.titulo), ['Informe', 'Taller', 'Quiz']);
      expect(resumen.habitosCompletados, 1);
      expect(resumen.habitosPorcentaje, 50.0);
      expect(resumen.aguaMl, 1500);
      expect(resumen.horasSueno, 7.5);
      expect(resumen.minutosActividad, 45);
      // Progreso: promedio de hábitos (50 %) y agua (75 %) = 62,5 %
      expect(resumen.progresoCombinado, closeTo(0.625, 0.0001));
    });

    test('usuario sin datos: nulos y ceros, sin inventar valores', () {
      final resumen = ResumenDia.fromJson(miDiaJson());
      expect(resumen.aguaMl, isNull);
      expect(resumen.horasSueno, isNull);
      expect(resumen.entregas, isEmpty);
      expect(resumen.habitosTotal, 0);
      // Sin hábitos solo cuenta el agua (0 %)
      expect(resumen.progresoCombinado, 0);
    });

    test('el agua por encima de la meta no pasa del 100 % en el anillo', () {
      final resumen = ResumenDia.fromJson(miDiaJson(aguaMl: 3000));
      expect(resumen.aguaPorcentaje, 150.0);
      expect(resumen.progresoCombinado, 1.0);
    });
  });

  group('MiDiaService', () {
    test('envía la fecha del teléfono y calcula la mejor racha actual', () async {
      final servidor = ServidorFalso({
        'GET /api/mi-dia': (_) => exito(miDiaJson()),
        'GET /api/habitos/1/estadisticas': (_) => exito({'habito_id': 1, 'total_cumplimientos': 6, 'dias_ventana': 10, 'porcentaje_cumplimiento': 60.0, 'racha_actual': 2, 'mejor_racha': 4, 'ultimo_cumplimiento': '2026-11-15'}),
        'GET /api/habitos/2/estadisticas': (_) => exito({'habito_id': 2, 'total_cumplimientos': 5, 'dias_ventana': 5, 'porcentaje_cumplimiento': 100.0, 'racha_actual': 5, 'mejor_racha': 5, 'ultimo_cumplimiento': '2026-11-18'}),
      });
      final api = servidor.crearApi(token: 't');
      final servicio = MiDiaService(api, HabitosService(api));

      await servicio.obtener(DateTime(2026, 11, 18));
      expect(servidor.recibidas.single.url.queryParameters['fecha'], '2026-11-18');

      expect(await servicio.mejorRachaActual([1, 2], DateTime(2026, 11, 18)), 5);
      expect(await servicio.mejorRachaActual([], DateTime(2026, 11, 18)), 0);
    });
  });

  group('SaludService.cambiarAgua (+1 vaso)', () {
    test('si el día no tiene registro, lo crea con POST', () async {
      final servidor = ServidorFalso({
        'GET /api/salud/hidratacion/2026-11-18': (_) => fallo(404, 'No hay registro de hidratación para ese día'),
        'POST /api/salud/hidratacion': (_) => exito({'id': 1, 'fecha': '2026-11-18', 'cantidad_ml': 250, 'fecha_creacion': '2026-11-18T12:00:00Z'}, codigo: 201),
      });
      final registro = await SaludService(servidor.crearApi(token: 't')).cambiarAgua(DateTime(2026, 11, 18), 250);
      expect(registro.cantidadMl, 250);
      expect(servidor.cuerpoDe('POST /api/salud/hidratacion'), {'cantidad_ml': 250, 'fecha': '2026-11-18'});
    });

    test('si ya existe, reemplaza el total con PUT (suma el vaso)', () async {
      final servidor = ServidorFalso({
        'GET /api/salud/hidratacion/2026-11-18': (_) => exito({'id': 1, 'fecha': '2026-11-18', 'cantidad_ml': 1000, 'fecha_creacion': 'x'}),
        'PUT /api/salud/hidratacion/2026-11-18': (p) => exito({'id': 1, 'fecha': '2026-11-18', 'cantidad_ml': 1250, 'fecha_creacion': 'x'}),
      });
      await SaludService(servidor.crearApi(token: 't')).cambiarAgua(DateTime(2026, 11, 18), 250);
      expect(servidor.cuerpoDe('PUT /api/salud/hidratacion/2026-11-18'), {'cantidad_ml': 1250});
    });

    test('quitar un vaso nunca baja de 0 ml', () async {
      final servidor = ServidorFalso({
        'GET /api/salud/hidratacion/2026-11-18': (_) => exito({'id': 1, 'fecha': '2026-11-18', 'cantidad_ml': 100, 'fecha_creacion': 'x'}),
        'PUT /api/salud/hidratacion/2026-11-18': (p) => exito({'id': 1, 'fecha': '2026-11-18', 'cantidad_ml': 0, 'fecha_creacion': 'x'}),
      });
      await SaludService(servidor.crearApi(token: 't')).cambiarAgua(DateTime(2026, 11, 18), -250);
      expect(servidor.cuerpoDe('PUT /api/salud/hidratacion/2026-11-18'), {'cantidad_ml': 0});
    });
  });

  group('Pantalla Mi Día (con sesión iniciada)', () {
    /// Abre la app completa con un token guardado y el servidor falso.
    Future<ServidorFalso> abrirApp(WidgetTester tester, Map<String, dynamic> resumen) async {
      FlutterSecureStorage.setMockInitialValues({'token_lifeos': 'tok'});
      SharedPreferences.setMockInitialValues({});
      final hoy = Fechas.aApi(Fechas.hoy());
      final servidor = ServidorFalso({
        'GET /api/usuarios/me': (_) => exito(usuarioJson),
        'GET /api/mi-dia': (_) => exito({...resumen, 'fecha': hoy}),
        'GET /api/smartstudy/materias': (_) => exito([
              {'id': 1, 'nombre': 'Bases de datos', 'docente': null, 'fecha_creacion': 'x'},
            ]),
        'GET /api/habitos/1/estadisticas': (_) => exito({'habito_id': 1, 'total_cumplimientos': 3, 'dias_ventana': 3, 'porcentaje_cumplimiento': 100.0, 'racha_actual': 3, 'mejor_racha': 3, 'ultimo_cumplimiento': hoy}),
        'GET /api/habitos/2/estadisticas': (_) => exito({'habito_id': 2, 'total_cumplimientos': 0, 'dias_ventana': 1, 'porcentaje_cumplimiento': 0.0, 'racha_actual': 0, 'mejor_racha': 0, 'ultimo_cumplimiento': null}),
        'POST /api/habitos/2/cumplimientos': (_) => exito({'habito_id': 2, 'fecha': hoy}, codigo: 201),
      });
      await tester.pumpWidget(LifeOSApp(servicios: Servicios(servidor.crearApi()), almacen: AlmacenSesion()));
      await tester.pumpAndSettle();
      return servidor;
    }

    testWidgets('muestra saludo, racha, progreso, entregas y hábitos reales', (tester) async {
      final hoy = Fechas.aApi(Fechas.hoy());
      await abrirApp(
        tester,
        miDiaJson(
          paraHoy: [tareaJson(5, 'Taller de bases de datos', hoy)],
          habitos: [
            {'id': 1, 'nombre': 'Leer', 'cumplido': true},
            {'id': 2, 'nombre': 'Meditar', 'cumplido': false},
          ],
          aguaMl: 1000,
        ),
      );

      expect(find.text('Ana'), findsOneWidget); // primer nombre en el chip de saludo
      expect(find.text('3'), findsWidgets); // racha 🔥 3
      expect(find.text('1 de 2 hábitos'), findsOneWidget);
      expect(find.text('Agua: 1000 de 2000 ml'), findsOneWidget);
      expect(find.text('Taller de bases de datos'), findsOneWidget);
      expect(find.text('Bases de datos'), findsOneWidget); // nombre de la materia cruzado por materia_id
      await tester.ensureVisible(find.text('Meditar'));
      await tester.pumpAndSettle();
      expect(find.text('Meditar'), findsOneWidget);
    });

    testWidgets('sin datos: estados vacíos con acciones reales', (tester) async {
      await abrirApp(tester, miDiaJson());
      expect(find.text('Sin entregas pendientes'), findsOneWidget);
      expect(find.text('Agua: sin registro (meta 2000 ml)'), findsOneWidget);
      await tester.ensureVisible(find.text('Aún no tienes hábitos activos'));
      expect(find.text('Crear hábito'), findsOneWidget);
    });

    testWidgets('marcar un hábito llama al backend con la fecha de hoy', (tester) async {
      final servidor = await abrirApp(tester, miDiaJson(habitos: [
        {'id': 2, 'nombre': 'Meditar', 'cumplido': false},
      ]));
      await tester.ensureVisible(find.text('Meditar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Meditar'));
      await tester.pumpAndSettle();
      expect(servidor.llamadas, contains('POST /api/habitos/2/cumplimientos'));
      expect(servidor.cuerpoDe('POST /api/habitos/2/cumplimientos'), {'fecha': Fechas.aApi(Fechas.hoy())});
    });

    testWidgets('el avatar abre el Perfil con los datos y la configuración', (tester) async {
      await abrirApp(tester, miDiaJson());
      await tester.tap(find.text('Ana'));
      await tester.pumpAndSettle();
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('ana@correo.com'), findsOneWidget);
      expect(find.text('250 ml'), findsOneWidget); // tamaño del vaso por defecto
      expect(find.text('2000 ml'), findsOneWidget); // meta que manda el servidor
    });
  });
}
