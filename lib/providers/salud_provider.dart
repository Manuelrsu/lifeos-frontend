import 'package:flutter/foundation.dart';

import '../models/salud.dart';
import '../services/api_service.dart';
import '../services/salud_service.dart';
import '../utils/fechas.dart';
import 'estado_carga.dart';

/// Estado del módulo Salud: hidratación, descanso, actividad y entrenamiento.
class SaludProvider extends ChangeNotifier {
  SaludProvider(this._servicio);

  final SaludService _servicio;

  static const int diasSueno = 14; // historial de descanso que se muestra
  static const int diasActividades = 30; // historial de actividades que se muestra

  EstadoCarga estado = EstadoCarga.inicial;
  String? mensajeError;

  /// Agua de hoy (null = todavía no hay registro hoy).
  RegistroHidratacion? aguaHoy;
  List<RegistroHidratacion> aguaSemana = [];
  List<RegistroSueno> suenos = [];
  List<Actividad> actividades = [];
  EstadisticasSalud? estadisticas;

  bool aguaOcupada = false;

  int get aguaHoyMl => aguaHoy?.cantidadMl ?? 0;

  /// Meta diaria de agua: la define el backend (META_HIDRATACION_ML).
  int get metaMl => estadisticas?.metaMl ?? 2000;

  /// Registro de sueño de una fecha (o null).
  RegistroSueno? suenoDe(DateTime fecha) {
    for (final s in suenos) {
      if (s.fecha == Fechas.soloDia(fecha)) return s;
    }
    return null;
  }

  /// Minutos de actividad por día de los últimos 7 días (para las barras), de más antiguo a hoy.
  List<({DateTime dia, int minutos})> get minutosUltimos7Dias {
    final hoy = Fechas.hoy();
    return List.generate(7, (i) {
      final dia = hoy.subtract(Duration(days: 6 - i));
      final minutos = actividades.where((a) => a.fecha == dia).fold<int>(0, (suma, a) => suma + a.duracionMinutos);
      return (dia: dia, minutos: minutos);
    });
  }

  Future<void> cargar({bool silencioso = false}) async {
    if (!silencioso || estado != EstadoCarga.listo) {
      estado = EstadoCarga.cargando;
      notifyListeners();
    }
    final hoy = Fechas.hoy();
    try {
      final r = await Future.wait([
        _servicio.aguaDelDia(hoy),
        _servicio.historialAgua(desde: hoy.subtract(const Duration(days: 6)), hasta: hoy),
        _servicio.historialSueno(desde: hoy.subtract(const Duration(days: diasSueno - 1)), hasta: hoy),
        _servicio.historialActividades(desde: hoy.subtract(const Duration(days: diasActividades - 1)), hasta: hoy),
        _servicio.estadisticas(fecha: hoy),
      ]);
      aguaHoy = r[0] as RegistroHidratacion?;
      aguaSemana = r[1] as List<RegistroHidratacion>;
      suenos = r[2] as List<RegistroSueno>;
      actividades = r[3] as List<Actividad>;
      estadisticas = r[4] as EstadisticasSalud;
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

  /// Suma (positivo) o resta (negativo) agua a hoy.
  Future<void> cambiarAgua(int diferenciaMl) async {
    aguaOcupada = true;
    notifyListeners();
    try {
      aguaHoy = await _servicio.cambiarAgua(Fechas.hoy(), diferenciaMl);
      final hoy = Fechas.hoy();
      aguaSemana = [aguaHoy!, ...aguaSemana.where((r) => r.fecha != hoy)];
      estadisticas = await _servicio.estadisticas(fecha: hoy);
    } finally {
      aguaOcupada = false;
      notifyListeners();
    }
  }

  /// Guarda las horas de sueño de una fecha (crea o reemplaza el registro de ese día).
  Future<void> guardarSueno(DateTime fecha, double horas) async {
    final nuevo = await _servicio.guardarSueno(fecha, horas, yaExiste: suenoDe(fecha) != null);
    suenos = [nuevo, ...suenos.where((s) => s.fecha != nuevo.fecha)]..sort((a, b) => b.fecha.compareTo(a.fecha));
    estadisticas = await _servicio.estadisticas(fecha: Fechas.hoy());
    notifyListeners();
  }

  Future<void> eliminarSueno(DateTime fecha) async {
    await _servicio.eliminarSueno(fecha);
    suenos = suenos.where((s) => s.fecha != Fechas.soloDia(fecha)).toList();
    estadisticas = await _servicio.estadisticas(fecha: Fechas.hoy());
    notifyListeners();
  }

  /// Crea (id == null) o actualiza una actividad o entrenamiento.
  Future<void> guardarActividad({
    int? id,
    required String tipo,
    required int duracionMinutos,
    required DateTime fecha,
    String? descripcion,
  }) async {
    final Actividad guardada;
    if (id == null) {
      guardada = await _servicio.crearActividad(tipo: tipo, duracionMinutos: duracionMinutos, fecha: fecha, descripcion: descripcion);
    } else {
      guardada = await _servicio.actualizarActividad(id, tipo: tipo, duracionMinutos: duracionMinutos, fecha: fecha, descripcion: descripcion);
    }
    actividades = [guardada, ...actividades.where((a) => a.id != guardada.id)]..sort((a, b) => b.fecha.compareTo(a.fecha));
    estadisticas = await _servicio.estadisticas(fecha: Fechas.hoy());
    notifyListeners();
  }

  Future<void> eliminarActividad(int id) async {
    await _servicio.eliminarActividad(id);
    actividades = actividades.where((a) => a.id != id).toList();
    estadisticas = await _servicio.estadisticas(fecha: Fechas.hoy());
    notifyListeners();
  }

  void limpiar() {
    estado = EstadoCarga.inicial;
    aguaHoy = null;
    aguaSemana = [];
    suenos = [];
    actividades = [];
    estadisticas = null;
    notifyListeners();
  }
}
