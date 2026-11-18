import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lifeos/models/evaluacion.dart';
import 'package:lifeos/models/materia.dart';
import 'package:lifeos/models/tarea.dart';
import 'package:lifeos/providers/smartstudy_provider.dart';
import 'package:lifeos/services/preferencias_service.dart';
import 'package:lifeos/services/smartstudy_service.dart';
import 'package:lifeos/utils/fechas.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ayudantes.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));

  final hoy = Fechas.hoy();
  String dia(int desplazamiento) => Fechas.aApi(hoy.add(Duration(days: desplazamiento)));

  group('Modelos', () {
    test('Tarea.fromJson / toJson con los nombres de campo del backend', () {
      final tarea = Tarea.fromJson(tareaJson(4, 'Taller', '2026-11-20', materiaId: 2));
      expect(tarea.id, 4);
      expect(tarea.materiaId, 2);
      expect(tarea.fechaEntrega, DateTime(2026, 11, 20));
      expect(tarea.completada, isFalse);
      expect(tarea.toJson(), {
        'materia_id': 2,
        'titulo': 'Taller',
        'descripcion': null,
        'fecha_entrega': '2026-11-20',
        'prioridad': 'media',
        'estado': 'pendiente',
      });
    });

    test('vencida y próxima se calculan contra hoy', () {
      final referencia = DateTime(2026, 11, 18);
      Tarea conFecha(String f, {String estado = 'pendiente'}) => Tarea.fromJson(tareaJson(1, 'x', f, estado: estado));
      expect(conFecha('2026-11-17').vencidaEn(referencia), isTrue);
      expect(conFecha('2026-11-17', estado: 'completada').vencidaEn(referencia), isFalse);
      expect(conFecha('2026-11-18').proximaEn(referencia), isTrue);
      expect(conFecha('2026-11-21').proximaEn(referencia), isTrue);
      expect(conFecha('2026-11-22').proximaEn(referencia), isFalse);
    });

    test('Materia y Evaluación', () {
      final materia = Materia.fromJson({'id': 1, 'nombre': 'Cálculo', 'docente': null, 'fecha_creacion': 'x'});
      expect(materia.docente, isNull);
      final evaluacion = Evaluacion.fromJson({
        'id': 3, 'materia_id': 1, 'nombre': 'Parcial', 'fecha': '2026-11-25', 'descripcion': null, 'fecha_creacion': 'x',
      });
      expect(evaluacion.fecha, DateTime(2026, 11, 25));
      expect(evaluacion.toJson()['fecha'], '2026-11-25');
    });
  });

  group('SmartStudyService', () {
    test('crear tarea: la descripción vacía se envía como null', () async {
      final servidor = ServidorFalso({
        'POST /api/smartstudy/tareas': (_) => exito(tareaJson(9, 'Informe', '2026-11-20'), codigo: 201),
      });
      await SmartStudyService(servidor.crearApi(token: 't'))
          .crearTarea(Tarea(id: 0, materiaId: 1, titulo: 'Informe', descripcion: '  ', fechaEntrega: DateTime(2026, 11, 20)));
      expect(servidor.cuerpoDe('POST /api/smartstudy/tareas')['descripcion'], isNull);
      expect(servidor.cuerpoDe('POST /api/smartstudy/tareas')['fecha_entrega'], '2026-11-20');
    });

    test('completar tarea usa PATCH /estado', () async {
      final servidor = ServidorFalso({
        'PATCH /api/smartstudy/tareas/9/estado': (_) => exito(tareaJson(9, 'Informe', '2026-11-20', estado: 'completada')),
      });
      final tarea = await SmartStudyService(servidor.crearApi(token: 't')).cambiarEstado(9, completada: true);
      expect(tarea.completada, isTrue);
      expect(servidor.cuerpoDe('PATCH /api/smartstudy/tareas/9/estado'), {'estado': 'completada'});
    });

    test('nombre de materia duplicado: 409 con el mensaje del backend', () async {
      final servidor = ServidorFalso({
        'POST /api/smartstudy/materias': (_) => fallo(409, 'Ya tienes una materia con ese nombre'),
      });
      await expectLater(
        SmartStudyService(servidor.crearApi(token: 't')).crearMateria(nombre: 'Cálculo'),
        throwsA(predicate((e) => e.toString() == 'Ya tienes una materia con ese nombre')),
      );
    });
  });

  group('SmartStudyProvider', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    SmartStudyProvider crear(ServidorFalso servidor) =>
        SmartStudyProvider(servicio: SmartStudyService(servidor.crearApi(token: 't')), preferencias: PreferenciasService());

    test('separa pendientes y completadas, y cuenta las entregas de hoy', () async {
      final servidor = ServidorFalso({
        'GET /api/smartstudy/materias': (_) => exito([{'id': 1, 'nombre': 'Cálculo', 'docente': null, 'fecha_creacion': 'x'}]),
        'GET /api/smartstudy/tareas': (_) => exito([
              tareaJson(1, 'Hoy pendiente', dia(0)),
              tareaJson(2, 'Hoy hecha', dia(0), estado: 'completada'),
              tareaJson(3, 'Vencida', dia(-2)),
              tareaJson(4, 'Futura', dia(10)),
            ]),
        'GET /api/smartstudy/evaluaciones': (_) => exito([
              {'id': 1, 'materia_id': 1, 'nombre': 'Pasada', 'fecha': dia(-1), 'descripcion': null, 'fecha_creacion': 'x'},
              {'id': 2, 'materia_id': 1, 'nombre': 'Próxima', 'fecha': dia(3), 'descripcion': null, 'fecha_creacion': 'x'},
            ]),
      });
      final p = crear(servidor);
      await p.cargar();

      expect(p.pendientes.map((t) => t.titulo), ['Vencida', 'Hoy pendiente', 'Futura']);
      expect(p.completadas.map((t) => t.titulo), ['Hoy hecha']);
      expect(p.entregasDeHoy, (total: 2, completadas: 1));
      expect(p.evaluacionesProximas.map((e) => e.nombre), ['Próxima']);
    });

    test('eliminar una materia quita sus tareas y evaluaciones (cascada del backend)', () async {
      final servidor = ServidorFalso({
        'GET /api/smartstudy/materias': (_) => exito([
              {'id': 1, 'nombre': 'A', 'docente': null, 'fecha_creacion': 'x'},
              {'id': 2, 'nombre': 'B', 'docente': null, 'fecha_creacion': 'x'},
            ]),
        'GET /api/smartstudy/tareas': (_) => exito([tareaJson(1, 'De A', dia(1), materiaId: 1), tareaJson(2, 'De B', dia(1), materiaId: 2)]),
        'GET /api/smartstudy/evaluaciones': (_) => exito([]),
        'DELETE /api/smartstudy/materias/1': (_) => exito(null),
      });
      final p = crear(servidor);
      await p.cargar();
      await p.eliminarMateria(1);
      expect(p.materias.map((m) => m.nombre), ['B']);
      expect(p.tareas.map((t) => t.titulo), ['De B']);
    });

    test('el color de la materia se guarda en el teléfono', () async {
      final servidor = ServidorFalso({
        'POST /api/smartstudy/materias': (_) => exito({'id': 5, 'nombre': 'Física', 'docente': null, 'fecha_creacion': 'x'}, codigo: 201),
      });
      final p = crear(servidor);
      await p.guardarMateria(nombre: 'Física', color: 3);
      expect(p.colorDe(5), 3);
      expect((await PreferenciasService().coloresMaterias([5]))[5], 3);
      // El color NO viaja al backend
      expect(servidor.cuerpoDe('POST /api/smartstudy/materias').containsKey('color'), isFalse);
    });
  });

  group('Pantalla SmartStudy', () {
    final materias = [
      {'id': 1, 'nombre': 'Bases de datos', 'docente': 'Laura', 'fecha_creacion': 'x'},
    ];

    testWidgets('sin materias pide crear una primero', (tester) async {
      await abrirAppConSesion(tester, {});
      await irAPestana(tester, 'SmartStudy');
      expect(find.text('Empieza creando una materia'), findsOneWidget);
      expect(find.text('Crear materia'), findsOneWidget);
    });

    testWidgets('muestra pestañas con contadores y completa una tarea', (tester) async {
      final servidor = await abrirAppConSesion(tester, {
        'GET /api/smartstudy/materias': (_) => exito(materias),
        'GET /api/smartstudy/tareas': (_) => exito([tareaJson(7, 'Modelo entidad-relación', dia(1))]),
        'PATCH /api/smartstudy/tareas/7/estado': (_) => exito(tareaJson(7, 'Modelo entidad-relación', dia(1), estado: 'completada')),
      });
      await irAPestana(tester, 'SmartStudy');

      expect(find.text('Modelo entidad-relación'), findsOneWidget);
      expect(find.text('Mañana'), findsOneWidget);
      expect(find.text('Nada para entregar hoy'), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(servidor.cuerpoDe('PATCH /api/smartstudy/tareas/7/estado'), {'estado': 'completada'});
      expect(find.text('¡Tarea completada!'), findsOneWidget);
    });

    testWidgets('crear tarea: valida el título y envía los datos al backend', (tester) async {
      final servidor = await abrirAppConSesion(tester, {
        'GET /api/smartstudy/materias': (_) => exito(materias),
        'POST /api/smartstudy/tareas': (_) => exito(tareaJson(8, 'Leer capítulo 3', dia(1)), codigo: 201),
      });
      await irAPestana(tester, 'SmartStudy');
      await tester.tap(find.byTooltip('Nueva tarea'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Crear tarea'));
      await tester.pumpAndSettle();
      expect(find.text('El título es obligatorio'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Título'), 'Leer capítulo 3');
      await tester.tap(find.text('Alta'));
      await tester.tap(find.text('Crear tarea'));
      await tester.pumpAndSettle();

      final cuerpo = servidor.cuerpoDe('POST /api/smartstudy/tareas');
      expect(cuerpo['titulo'], 'Leer capítulo 3');
      expect(cuerpo['materia_id'], 1);
      expect(cuerpo['prioridad'], 'alta');
      expect(cuerpo['fecha_entrega'], dia(1));
      expect(find.text('Tarea creada'), findsOneWidget);
    });
  });
}
