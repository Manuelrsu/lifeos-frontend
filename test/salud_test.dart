import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lifeos/models/salud.dart';
import 'package:lifeos/providers/salud_provider.dart';
import 'package:lifeos/screens/health/salud_screen.dart';
import 'package:lifeos/services/salud_service.dart';
import 'package:lifeos/utils/fechas.dart';

import 'ayudantes.dart';

Map<String, dynamic> actividadJson(int id, String tipo, int minutos, String fecha, {String? descripcion}) => {
      'id': id,
      'fecha': fecha,
      'tipo': tipo,
      'duracion_minutos': minutos,
      'descripcion': descripcion,
      'fecha_creacion': '2026-11-18T12:00:00Z',
    };

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));

  final hoy = Fechas.hoy();
  final hoyApi = Fechas.aApi(hoy);
  String dia(int atras) => Fechas.aApi(hoy.subtract(Duration(days: atras)));

  group('Modelos y formatos', () {
    test('RegistroSueno acepta horas enteras o decimales', () {
      expect(RegistroSueno.fromJson({'id': 1, 'fecha': '2026-11-18', 'horas': 8, 'fecha_creacion': 'x'}).horas, 8.0);
      expect(RegistroSueno.fromJson({'id': 1, 'fecha': '2026-11-18', 'horas': 7.25, 'fecha_creacion': 'x'}).horas, 7.25);
    });

    test('EstadisticasSalud con promedios nulos (días sin registro)', () {
      final e = EstadisticasSalud.fromJson(estadisticasSaludJson(minutos: 90, sesiones: 2, diasActivos: 2));
      expect(e.promedioMl, isNull);
      expect(e.promedioHoras, isNull);
      expect(e.metaMl, 2000);
      expect(e.minutosTotales, 90);
      expect(e.totalActividades, 2);
    });

    test('formato de horas y minutos', () {
      expect(formatoHoras(7.2), '7 h 12 min');
      expect(formatoHoras(8), '8 h');
      expect(formatoMinutos(45), '45 min');
      expect(formatoMinutos(90), '1 h 30 min');
      expect(formatoMinutos(120), '2 h');
    });
  });

  group('SaludService', () {
    test('sueño: crea con POST y reemplaza con PUT', () async {
      final servidor = ServidorFalso({
        'POST /api/salud/sueno': (_) => exito({'id': 1, 'fecha': '2026-11-18', 'horas': 7.5, 'fecha_creacion': 'x'}, codigo: 201),
        'PUT /api/salud/sueno/2026-11-18': (_) => exito({'id': 1, 'fecha': '2026-11-18', 'horas': 8.0, 'fecha_creacion': 'x'}),
      });
      final servicio = SaludService(servidor.crearApi(token: 't'));
      await servicio.guardarSueno(DateTime(2026, 11, 18), 7.5, yaExiste: false);
      await servicio.guardarSueno(DateTime(2026, 11, 18), 8, yaExiste: true);
      expect(servidor.cuerpoDe('POST /api/salud/sueno'), {'horas': 7.5, 'fecha': '2026-11-18'});
      expect(servidor.cuerpoDe('PUT /api/salud/sueno/2026-11-18'), {'horas': 8.0});
    });

    test('actividad: notas vacías se envían como null', () async {
      final servidor = ServidorFalso({
        'POST /api/salud/actividades': (_) => exito(actividadJson(1, 'Pesas', 45, '2026-11-18'), codigo: 201),
      });
      await SaludService(servidor.crearApi(token: 't'))
          .crearActividad(tipo: ' Pesas ', duracionMinutos: 45, fecha: DateTime(2026, 11, 18), descripcion: '');
      expect(servidor.cuerpoDe('POST /api/salud/actividades'), {
        'tipo': 'Pesas',
        'duracion_minutos': 45,
        'fecha': '2026-11-18',
        'descripcion': null,
      });
    });

    test('fecha futura: el 422 del backend llega con el error por campo', () async {
      final servidor = ServidorFalso({
        'POST /api/salud/actividades': (_) => fallo(422, 'Datos de actividad inválidos', errores: {'fecha': 'La fecha no puede ser futura'}),
      });
      await expectLater(
        SaludService(servidor.crearApi(token: 't')).crearActividad(tipo: 'Correr', duracionMinutos: 30, fecha: DateTime(2030)),
        throwsA(predicate((e) => (e as dynamic).errores['fecha'] == 'La fecha no puede ser futura')),
      );
    });
  });

  group('SaludProvider', () {
    test('suma los minutos de actividad por día de la última semana', () async {
      final servidor = ServidorFalso({
        ...rutasBase(),
        'GET /api/salud/actividades': (_) => exito([
              actividadJson(1, 'Correr', 30, dia(0)),
              actividadJson(2, 'Pesas', 45, dia(0)),
              actividadJson(3, 'Yoga', 20, dia(2)),
              actividadJson(4, 'Natación', 60, dia(10)), // fuera de los 7 días
            ]),
      });
      final p = SaludProvider(SaludService(servidor.crearApi(token: 't')));
      await p.cargar();
      final minutos = p.minutosUltimos7Dias.map((b) => b.minutos).toList();
      expect(minutos, [0, 0, 0, 0, 20, 0, 75]);
      expect(p.aguaHoy, isNull); // 404 = sin registro hoy (no se inventa un 0 guardado)
      expect(p.aguaHoyMl, 0);
    });
  });

  group('Pantalla Salud', () {
    testWidgets('Hidratación: vasos llevados, faltantes y +1 vaso', (tester) async {
      final servidor = await abrirAppConSesion(tester, {
        'GET /api/salud/hidratacion/$hoyApi': (_) => exito({'id': 1, 'fecha': hoyApi, 'cantidad_ml': 1000, 'fecha_creacion': 'x'}),
        'PUT /api/salud/hidratacion/$hoyApi': (_) => exito({'id': 1, 'fecha': hoyApi, 'cantidad_ml': 1250, 'fecha_creacion': 'x'}),
      });
      await irAPestana(tester, 'Salud');

      expect(find.text('Llevas 4 de 8 vasos'), findsOneWidget);
      expect(find.text('Te faltan 4 vasos (1000 ml)'), findsOneWidget);
      expect(find.text('50 %'), findsOneWidget);

      await tester.tap(find.text('+1 vaso (250 ml)'));
      await tester.pumpAndSettle();
      expect(servidor.cuerpoDe('PUT /api/salud/hidratacion/$hoyApi'), {'cantidad_ml': 1250});
      expect(find.text('Llevas 5 de 8 vasos'), findsOneWidget);
    });

    testWidgets('Descanso: horas frente a la meta, sin evaluaciones de salud', (tester) async {
      await abrirAppConSesion(tester, {
        'GET /api/salud/hidratacion/$hoyApi': (_) => fallo(404, 'No hay registro'),
        'GET /api/salud/sueno': (_) => exito([{'id': 1, 'fecha': hoyApi, 'horas': 7.5, 'fecha_creacion': 'x'}]),
      });
      await irAPestana(tester, 'Salud');
      await tester.tap(find.text('Descanso'));
      await tester.pumpAndSettle();

      expect(find.text('7 h 30 min'), findsWidgets);
      expect(find.text('meta 8 h · 94 %'), findsOneWidget);
      expect(find.textContaining('Bueno'), findsNothing);
      expect(find.textContaining('Good'), findsNothing);
    });

    testWidgets('Actividad: cuadrícula 2×2 con las estadísticas del backend', (tester) async {
      await abrirAppConSesion(tester, {
        'GET /api/salud/hidratacion/$hoyApi': (_) => fallo(404, 'No hay registro'),
        'GET /api/salud/estadisticas': (_) => exito(estadisticasSaludJson(minutos: 150, sesiones: 3, diasActivos: 2)),
      });
      await irAPestana(tester, 'Salud');
      await tester.tap(find.text('Actividad'));
      await tester.pumpAndSettle();

      expect(find.text('2 h 30 min'), findsOneWidget); // minutos activos
      expect(find.text('3'), findsOneWidget); // sesiones
      expect(find.text('2/7'), findsOneWidget); // días activos
      expect(find.text('50 min'), findsOneWidget); // promedio por sesión
    });

    testWidgets('Entrenamiento: valida la duración y registra en el backend', (tester) async {
      final servidor = await abrirAppConSesion(tester, {
        'GET /api/salud/hidratacion/$hoyApi': (_) => fallo(404, 'No hay registro'),
        'POST /api/salud/actividades': (_) => exito(actividadJson(5, 'Pesas', 50, hoyApi), codigo: 201),
      });
      await irAPestana(tester, 'Salud');
      await tester.tap(find.text('Entrenamiento'));
      await tester.pumpAndSettle();
      expect(find.text('Sin entrenamientos registrados'), findsOneWidget);

      await tester.tap(find.text('Registrar entrenamiento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pesas')); // sugerencia
      await tester.enterText(find.widgetWithText(TextFormField, 'Duración'), '0');
      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();
      expect(find.text('Debe estar entre 1 y 1440'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Duración'), '50');
      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();

      expect(servidor.cuerpoDe('POST /api/salud/actividades')['tipo'], 'Pesas');
      expect(servidor.cuerpoDe('POST /api/salud/actividades')['duracion_minutos'], 50);
      expect(find.text('Actividad registrada'), findsOneWidget);
      expect(find.text('Pesas'), findsOneWidget); // ya aparece en el historial
    });
  });
}
