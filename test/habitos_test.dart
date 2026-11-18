import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lifeos/models/habito.dart';
import 'package:lifeos/providers/habitos_provider.dart';
import 'package:lifeos/services/habitos_service.dart';
import 'package:lifeos/utils/fechas.dart';

import 'ayudantes.dart';

/// Estadísticas con la forma de GET /api/habitos/id/estadisticas.
Map<String, dynamic> statsJson(int id, {int racha = 0, int mejor = 0, double porcentaje = 0, int total = 0, String? ultimo}) => {
      'habito_id': id,
      'total_cumplimientos': total,
      'dias_ventana': 10,
      'porcentaje_cumplimiento': porcentaje,
      'racha_actual': racha,
      'mejor_racha': mejor,
      'ultimo_cumplimiento': ultimo,
    };

Map<String, dynamic> habitoJson(int id, String nombre, {bool activo = true}) =>
    {'id': id, 'nombre': nombre, 'descripcion': null, 'activo': activo, 'fecha_creacion': '2026-11-07T15:00:00Z'};

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));

  final hoy = Fechas.hoy();
  final lunes = Fechas.lunesDe(hoy);
  final hoyApi = Fechas.aApi(hoy);

  group('Modelos', () {
    test('Habito.fromJson', () {
      final habito = Habito.fromJson(habitoJson(1, 'Leer', activo: false));
      expect(habito.nombre, 'Leer');
      expect(habito.activo, isFalse);
    });

    test('EstadisticasHabito con el ejemplo numérico del backend (sección 11.2)', () {
      final stats = EstadisticasHabito.fromJson({
        'habito_id': 1,
        'total_cumplimientos': 6,
        'dias_ventana': 10,
        'porcentaje_cumplimiento': 60.0,
        'racha_actual': 2,
        'mejor_racha': 4,
        'ultimo_cumplimiento': '2026-11-15',
      });
      expect(stats.totalCumplimientos, 6);
      expect(stats.porcentajeCumplimiento, 60.0);
      expect(stats.rachaActual, 2);
      expect(stats.mejorRacha, 4);
      expect(stats.ultimoCumplimiento, '2026-11-15');
    });
  });

  group('HabitosService', () {
    test('marcar envía la fecha; desmarcar usa la fecha en la ruta', () async {
      final servidor = ServidorFalso({
        'POST /api/habitos/3/cumplimientos': (_) => exito({'habito_id': 3, 'fecha': '2026-11-17'}, codigo: 201),
        'DELETE /api/habitos/3/cumplimientos/2026-11-17': (_) => exito(null),
      });
      final servicio = HabitosService(servidor.crearApi(token: 't'));
      await servicio.marcar(3, DateTime(2026, 11, 17));
      await servicio.desmarcar(3, DateTime(2026, 11, 17));
      expect(servidor.cuerpoDe('POST /api/habitos/3/cumplimientos'), {'fecha': '2026-11-17'});
      expect(servidor.llamadas.last, 'DELETE /api/habitos/3/cumplimientos/2026-11-17');
    });

    test('historial devuelve las fechas como conjunto y envía el rango', () async {
      final servidor = ServidorFalso({
        'GET /api/habitos/3/historial': (_) => exito({'habito_id': 3, 'desde': '2026-11-16', 'hasta': '2026-11-18', 'fechas': ['2026-11-18', '2026-11-16']}),
      });
      final fechas = await HabitosService(servidor.crearApi(token: 't'))
          .historial(3, desde: DateTime(2026, 11, 16), hasta: DateTime(2026, 11, 18));
      expect(fechas, {DateTime(2026, 11, 16), DateTime(2026, 11, 18)});
      expect(servidor.recibidas.single.url.queryParameters, {'desde': '2026-11-16', 'hasta': '2026-11-18'});
    });

    test('marcar un día ya marcado: 409 con el mensaje del backend', () async {
      final servidor = ServidorFalso({
        'POST /api/habitos/3/cumplimientos': (_) => fallo(409, 'El hábito ya estaba marcado como cumplido ese día'),
      });
      await expectLater(
        HabitosService(servidor.crearApi(token: 't')).marcar(3, hoy),
        throwsA(predicate((e) => e.toString().contains('ya estaba marcado'))),
      );
    });
  });

  group('HabitosProvider', () {
    test('carga la semana y las estadísticas; marcar hoy actualiza la racha', () async {
      var racha = 0;
      final servidor = ServidorFalso({
        'GET /api/habitos': (_) => exito([habitoJson(1, 'Leer'), habitoJson(2, 'Correr', activo: false)]),
        'GET /api/habitos/1/historial': (_) => exito({'habito_id': 1, 'desde': 'x', 'hasta': 'x', 'fechas': [Fechas.aApi(lunes)]}),
        'GET /api/habitos/2/historial': (_) => exito({'habito_id': 2, 'desde': 'x', 'hasta': 'x', 'fechas': []}),
        'GET /api/habitos/1/estadisticas': (_) => exito(statsJson(1, racha: racha)),
        'GET /api/habitos/2/estadisticas': (_) => exito(statsJson(2)),
        'POST /api/habitos/1/cumplimientos': (_) {
          racha = 1;
          return exito({'habito_id': 1, 'fecha': hoyApi}, codigo: 201);
        },
      });
      final p = HabitosProvider(HabitosService(servidor.crearApi(token: 't')));
      await p.cargar();

      expect(p.activos.map((h) => h.nombre), ['Leer']);
      expect(p.pausados.map((h) => h.nombre), ['Correr']);
      expect(p.cumplido(1, lunes), isTrue);
      expect(p.diasEstaSemana(1), 1);

      if (hoy != lunes) {
        expect(p.completadosHoy, 0);
        await p.alternarDia(p.activos.first, hoy);
        expect(p.cumplido(1, hoy), isTrue);
        expect(p.completadosHoy, 1);
        expect(p.estadisticas[1]!.rachaActual, 1);
      }
    });
  });

  group('Pantalla Hábitos', () {
    testWidgets('sin hábitos: estado vacío con «Crear hábito»', (tester) async {
      await abrirAppConSesion(tester, {});
      await irAPestana(tester, 'Hábitos');
      expect(find.text('Crea tu primer hábito'), findsOneWidget);
      expect(find.text('Crear hábito'), findsOneWidget);
    });

    testWidgets('tarjeta con progreso semanal, racha y marca de hoy', (tester) async {
      final servidor = await abrirAppConSesion(tester, {
        'GET /api/habitos': (_) => exito([habitoJson(1, 'Leer 20 minutos')]),
        'GET /api/habitos/1/historial': (_) => exito({'habito_id': 1, 'desde': 'x', 'hasta': 'x', 'fechas': []}),
        'GET /api/habitos/1/estadisticas': (_) => exito(statsJson(1, racha: 12, mejor: 15, porcentaje: 80, total: 24, ultimo: hoyApi)),
        'POST /api/habitos/1/cumplimientos': (_) => exito({'habito_id': 1, 'fecha': hoyApi}, codigo: 201),
      });
      await irAPestana(tester, 'Hábitos');

      expect(find.text('Leer 20 minutos'), findsOneWidget);
      expect(find.text('0 % · 0/7 esta semana'), findsOneWidget);
      expect(find.text('🔥 12 d'), findsOneWidget);
      expect(find.text('0 de 1 completados hoy'), findsOneWidget);

      // Tocar el cuadro de HOY marca el hábito
      await tester.tap(find.bySemanticsLabel(RegExp(r'\(hoy\): sin cumplir')));
      await tester.pumpAndSettle();
      expect(servidor.cuerpoDe('POST /api/habitos/1/cumplimientos'), {'fecha': hoyApi});
      expect(find.text('1 de 1 completados hoy'), findsNothing); // ahora están todos
      expect(find.text('¡Todo listo por hoy! Sigue así 💪'), findsOneWidget);
    });

    testWidgets('el botón de estadísticas muestra los datos del backend', (tester) async {
      await abrirAppConSesion(tester, {
        'GET /api/habitos': (_) => exito([habitoJson(1, 'Meditar')]),
        'GET /api/habitos/1/historial': (_) => exito({'habito_id': 1, 'desde': 'x', 'hasta': 'x', 'fechas': []}),
        'GET /api/habitos/1/estadisticas': (_) => exito(statsJson(1, racha: 2, mejor: 4, porcentaje: 60, total: 6, ultimo: '2026-11-15')),
      });
      await irAPestana(tester, 'Hábitos');
      await tester.tap(find.byTooltip('Estadísticas'));
      await tester.pumpAndSettle();
      expect(find.text('2 d'), findsOneWidget);
      expect(find.text('4 d'), findsOneWidget);
      expect(find.text('60,0 %'), findsOneWidget);
    });
  });
}
