// Prueba de humo contra el backend REAL (Flask + MySQL).
//
// Uso (con el backend encendido en la PC):
//   dart run tool/smoke_test.dart                      → usa http://127.0.0.1:5000
//   dart run tool/smoke_test.dart http://otra-url:5000
//
// Registra un usuario ÚNICO (smoke_<timestamp>@lifeos.test), inicia sesión y crea,
// consulta y actualiza al menos un registro de cada módulo usando los MISMOS servicios
// y modelos de la app. Imprime OK o FALLO por paso. Ese usuario queda en lifeos_db.
import 'dart:io';

import 'package:lifeos/models/evaluacion.dart';
import 'package:lifeos/models/tarea.dart';
import 'package:lifeos/services/api_service.dart';
import 'package:lifeos/services/auth_service.dart';
import 'package:lifeos/services/habitos_service.dart';
import 'package:lifeos/services/mi_dia_service.dart';
import 'package:lifeos/services/salud_service.dart';
import 'package:lifeos/services/smartstudy_service.dart';
import 'package:lifeos/utils/fechas.dart';

int _ok = 0;
int _fallos = 0;

/// Ejecuta un paso, imprime OK o FALLO y devuelve su resultado (o null si falló).
Future<T?> paso<T>(String nombre, Future<T> Function() accion, {bool Function(T resultado)? comprobar}) async {
  try {
    final resultado = await accion();
    if (comprobar != null && !comprobar(resultado)) {
      _fallos++;
      stdout.writeln('FALLO  $nombre  (resultado inesperado: $resultado)');
      return null;
    }
    _ok++;
    stdout.writeln('OK     $nombre');
    return resultado;
  } catch (e) {
    _fallos++;
    stdout.writeln('FALLO  $nombre  ($e)');
    return null;
  }
}

Future<void> main(List<String> argumentos) async {
  final url = argumentos.isNotEmpty ? argumentos.first : 'http://127.0.0.1:5000';
  final api = ApiService(urlBase: url);
  final auth = AuthService(api);
  final estudio = SmartStudyService(api);
  final habitos = HabitosService(api);
  final salud = SaludService(api);
  final miDia = MiDiaService(api, habitos);

  final marca = DateTime.now().millisecondsSinceEpoch;
  final correo = 'smoke_$marca@lifeos.test';
  const contrasena = 'Smoke12345';
  final hoy = Fechas.hoy();

  stdout.writeln('Prueba de humo contra $url');
  stdout.writeln('Usuario de prueba: $correo\n');

  // ---------- Estado y autenticación ----------
  final estado = await paso('GET /api/estado (servidor y base de datos)', () => api.get('/api/estado'));
  if (estado == null) {
    stdout.writeln('\nEl backend no responde: no tiene sentido seguir.');
    exit(1);
  }
  await paso('Registro de usuario', () => auth.registrar(nombre: 'Smoke Test', correo: correo, contrasena: contrasena),
      comprobar: (u) => u.correo == correo);
  await paso('Registro duplicado responde 409', () async {
    try {
      await auth.registrar(nombre: 'Smoke Test', correo: correo, contrasena: contrasena);
      return -1;
    } on ApiException catch (e) {
      return e.codigo;
    }
  }, comprobar: (codigo) => codigo == 409);
  final sesion = await paso('Inicio de sesión', () => auth.iniciarSesion(correo: correo, contrasena: contrasena));
  if (sesion == null) exit(1);
  api.token = sesion.token;
  await paso('Perfil (GET /usuarios/me)', auth.obtenerPerfil, comprobar: (u) => u.id == sesion.usuario.id);
  await paso('Actualizar perfil (PUT /usuarios/me)', () => auth.actualizarPerfil(nombre: 'Smoke Actualizado'),
      comprobar: (u) => u.nombre == 'Smoke Actualizado');

  // ---------- SmartStudy ----------
  final materia = await paso('Crear materia', () => estudio.crearMateria(nombre: 'Materia Smoke', docente: 'Docente'));
  await paso('Listar materias', estudio.listarMaterias, comprobar: (lista) => lista.any((m) => m.id == materia?.id));
  await paso('Actualizar materia', () => estudio.actualizarMateria(materia!.id, nombre: 'Materia Smoke 2', docente: ''),
      comprobar: (m) => m.nombre == 'Materia Smoke 2' && m.docente == null);
  final tarea = await paso(
    'Crear tarea (entrega en 2 días)',
    () => estudio.crearTarea(Tarea(id: 0, materiaId: materia!.id, titulo: 'Tarea Smoke', fechaEntrega: hoy.add(const Duration(days: 2)))),
  );
  await paso('Listar tareas', estudio.listarTareas, comprobar: (lista) => lista.any((t) => t.id == tarea?.id));
  await paso('Completar tarea (PATCH estado)', () => estudio.cambiarEstado(tarea!.id, completada: true),
      comprobar: (t) => t.completada);
  await paso('Volver a pendiente', () => estudio.cambiarEstado(tarea!.id, completada: false), comprobar: (t) => !t.completada);
  await paso(
    'Actualizar tarea (PUT)',
    () => estudio.actualizarTarea(Tarea(
      id: tarea!.id,
      materiaId: materia!.id,
      titulo: 'Tarea Smoke editada',
      descripcion: 'Con descripción',
      fechaEntrega: tarea.fechaEntrega,
      prioridad: 'alta',
    )),
    comprobar: (t) => t.titulo == 'Tarea Smoke editada' && t.prioridad == 'alta',
  );
  final evaluacion = await paso(
    'Crear evaluación',
    () => estudio.crearEvaluacion(Evaluacion(id: 0, materiaId: materia!.id, nombre: 'Parcial Smoke', fecha: hoy.add(const Duration(days: 3)))),
  );
  await paso('Listar evaluaciones', estudio.listarEvaluaciones, comprobar: (lista) => lista.any((e) => e.id == evaluacion?.id));

  // ---------- Hábitos ----------
  final habito = await paso('Crear hábito', () => habitos.crear(nombre: 'Hábito Smoke', descripcion: 'Prueba'));
  await paso('Marcar hábito hoy', () => habitos.marcar(habito!.id, hoy).then((_) => true));
  await paso('Marcar dos veces responde 409', () async {
    try {
      await habitos.marcar(habito!.id, hoy);
      return -1;
    } on ApiException catch (e) {
      return e.codigo;
    }
  }, comprobar: (codigo) => codigo == 409);
  await paso('Historial de la semana', () => habitos.historial(habito!.id, desde: Fechas.lunesDe(hoy), hasta: hoy),
      comprobar: (fechas) => fechas.contains(hoy));
  await paso('Estadísticas (racha actual 1)', () => habitos.estadisticas(habito!.id, hoy), comprobar: (e) => e.rachaActual == 1);
  await paso('Actualizar hábito', () => habitos.actualizar(habito!.id, nombre: 'Hábito Smoke 2'),
      comprobar: (h) => h.nombre == 'Hábito Smoke 2');

  // ---------- Salud ----------
  await paso('Agua +250 ml (crea el registro del día)', () => salud.cambiarAgua(hoy, 250), comprobar: (r) => r.cantidadMl == 250);
  await paso('Agua +250 ml (actualiza el total)', () => salud.cambiarAgua(hoy, 250), comprobar: (r) => r.cantidadMl == 500);
  await paso('Agua del día', () => salud.aguaDelDia(hoy), comprobar: (r) => r?.cantidadMl == 500);
  await paso('Registrar sueño 7.5 h', () => salud.guardarSueno(hoy, 7.5, yaExiste: false), comprobar: (r) => r.horas == 7.5);
  await paso('Actualizar sueño a 8 h', () => salud.guardarSueno(hoy, 8, yaExiste: true), comprobar: (r) => r.horas == 8);
  await paso('Historial de sueño', () => salud.historialSueno(desde: hoy.subtract(const Duration(days: 6)), hasta: hoy),
      comprobar: (lista) => lista.length == 1);
  final actividad = await paso('Registrar entrenamiento', () => salud.crearActividad(tipo: 'Pesas', duracionMinutos: 45, fecha: hoy));
  await paso(
    'Actualizar entrenamiento',
    () => salud.actualizarActividad(actividad!.id, tipo: 'Pesas', duracionMinutos: 60, fecha: hoy, descripcion: 'Pierna'),
    comprobar: (a) => a.duracionMinutos == 60 && a.descripcion == 'Pierna',
  );
  await paso('Historial de actividades', () => salud.historialActividades(desde: hoy, hasta: hoy), comprobar: (l) => l.length == 1);
  await paso('Estadísticas de salud (7 días)', () => salud.estadisticas(fecha: hoy),
      comprobar: (e) => e.minutosTotales == 60 && e.diasConAgua == 1 && e.promedioHoras == 8);

  // ---------- Mi Día ----------
  await paso(
    'Mi Día refleja los datos de todos los módulos',
    () => miDia.obtener(hoy),
    comprobar: (r) =>
        r.totalPendientes == 1 &&
        r.habitosCompletados == 1 &&
        r.aguaMl == 500 &&
        r.horasSueno == 8 &&
        r.minutosActividad == 60 &&
        r.evaluacionesProximas.length == 1,
  );
  await paso('Racha para el chip 🔥', () => miDia.mejorRachaActual([habito!.id], hoy), comprobar: (r) => r == 1);

  // ---------- Limpieza parcial y cierre ----------
  await paso('Desmarcar hábito', () => habitos.desmarcar(habito!.id, hoy).then((_) => true));
  await paso('Eliminar entrenamiento', () => salud.eliminarActividad(actividad!.id).then((_) => true));
  await paso('Cerrar sesión (revoca el token)', () => auth.cerrarSesion().then((_) => true));
  api.token = sesion.token; // se intenta usar el token revocado
  await paso('El token revocado ya no sirve (401)', () async {
    try {
      await auth.obtenerPerfil();
      return -1;
    } on ApiException catch (e) {
      return e.codigo;
    }
  }, comprobar: (codigo) => codigo == 401);

  stdout.writeln('\nResultado: $_ok OK, $_fallos FALLO');
  stdout.writeln('Se creó 1 usuario de prueba en lifeos_db: $correo');
  exit(_fallos == 0 ? 0 : 1);
}
