import 'package:flutter/foundation.dart';

import '../models/habito.dart';
import '../services/api_service.dart';
import '../services/habitos_service.dart';
import '../utils/fechas.dart';
import 'estado_carga.dart';

/// Estado del módulo Hábitos: la lista, los días cumplidos de esta semana y las estadísticas.
class HabitosProvider extends ChangeNotifier {
  HabitosProvider(this._servicio);

  final HabitosService _servicio;

  EstadoCarga estado = EstadoCarga.inicial;
  String? mensajeError;

  List<Habito> habitos = [];

  /// Días cumplidos de la semana actual (lunes a hoy), por hábito.
  Map<int, Set<DateTime>> semana = {};

  /// Estadísticas calculadas por el backend, por hábito (racha, porcentaje...).
  Map<int, EstadisticasHabito> estadisticas = {};

  /// Días que se están marcando ahora mismo: "idHabito-fecha".
  final Set<String> ocupados = {};

  /// Lunes de esta semana (la fila L-M-M-J-V-S-D empieza ahí).
  DateTime get lunes => Fechas.lunesDe(Fechas.hoy());

  List<Habito> get activos => habitos.where((h) => h.activo).toList();
  List<Habito> get pausados => habitos.where((h) => !h.activo).toList();

  bool cumplido(int idHabito, DateTime dia) => semana[idHabito]?.contains(Fechas.soloDia(dia)) ?? false;

  /// Cuántos hábitos activos están cumplidos hoy.
  int get completadosHoy => activos.where((h) => cumplido(h.id, Fechas.hoy())).length;

  /// Días cumplidos esta semana para un hábito (para «n/7 esta semana»).
  int diasEstaSemana(int idHabito) => semana[idHabito]?.length ?? 0;

  bool estaOcupado(int idHabito, DateTime dia) => ocupados.contains('$idHabito-${Fechas.aApi(dia)}');

  Future<void> cargar({bool silencioso = false}) async {
    if (!silencioso || estado != EstadoCarga.listo) {
      estado = EstadoCarga.cargando;
      notifyListeners();
    }
    try {
      final lista = await _servicio.listar();
      final hoy = Fechas.hoy();
      // Historial de la semana y estadísticas de cada hábito, todo al mismo tiempo
      final semanas = await Future.wait(lista.map((h) => _servicio.historial(h.id, desde: lunes, hasta: hoy)));
      final stats = await Future.wait(lista.map((h) => _servicio.estadisticas(h.id, hoy)));
      habitos = lista;
      semana = {for (var i = 0; i < lista.length; i++) lista[i].id: semanas[i]};
      estadisticas = {for (var i = 0; i < lista.length; i++) lista[i].id: stats[i]};
      estado = EstadoCarga.listo;
      mensajeError = null;
      notifyListeners();
    } on ApiException catch (e) {
      mensajeError = e.mensaje;
      if (estado != EstadoCarga.listo || !silencioso) estado = EstadoCarga.error;
      notifyListeners();
      if (silencioso) rethrow;
    }
  }

  /// Marca o desmarca un día (hoy o un día pasado; el backend no acepta días futuros).
  Future<void> alternarDia(Habito habito, DateTime dia) async {
    final clave = '${habito.id}-${Fechas.aApi(dia)}';
    ocupados.add(clave);
    notifyListeners();
    try {
      if (cumplido(habito.id, dia)) {
        await _servicio.desmarcar(habito.id, dia);
        semana[habito.id] = {...?semana[habito.id]}..remove(Fechas.soloDia(dia));
      } else {
        await _servicio.marcar(habito.id, dia);
        semana[habito.id] = {...?semana[habito.id], Fechas.soloDia(dia)};
      }
      // La racha y el porcentaje cambian: se piden de nuevo al backend
      estadisticas[habito.id] = await _servicio.estadisticas(habito.id, Fechas.hoy());
    } finally {
      ocupados.remove(clave);
      notifyListeners();
    }
  }

  Future<void> crear({required String nombre, String? descripcion}) async {
    final nuevo = await _servicio.crear(nombre: nombre, descripcion: descripcion);
    habitos = [...habitos, nuevo];
    semana[nuevo.id] = {};
    estadisticas[nuevo.id] = await _servicio.estadisticas(nuevo.id, Fechas.hoy());
    notifyListeners();
  }

  Future<void> actualizar(Habito habito, {String? nombre, String? descripcion, bool? activo}) async {
    final nuevo = await _servicio.actualizar(habito.id, nombre: nombre, descripcion: descripcion, activo: activo);
    habitos = [for (final h in habitos) h.id == nuevo.id ? nuevo : h];
    notifyListeners();
  }

  /// Elimina el hábito y todo su historial.
  Future<void> eliminar(Habito habito) async {
    await _servicio.eliminar(habito.id);
    habitos = habitos.where((h) => h.id != habito.id).toList();
    semana.remove(habito.id);
    estadisticas.remove(habito.id);
    notifyListeners();
  }

  void limpiar() {
    estado = EstadoCarga.inicial;
    habitos = [];
    semana = {};
    estadisticas = {};
    notifyListeners();
  }
}
