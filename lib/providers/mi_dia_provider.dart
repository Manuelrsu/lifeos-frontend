import 'package:flutter/foundation.dart';

import '../models/materia.dart';
import '../models/resumen_dia.dart';
import '../services/api_service.dart';
import '../services/habitos_service.dart';
import '../services/mi_dia_service.dart';
import '../services/preferencias_service.dart';
import '../services/salud_service.dart';
import '../services/smartstudy_service.dart';
import '../utils/fechas.dart';
import 'estado_carga.dart';

/// Estado de la pantalla Mi Día.
class MiDiaProvider extends ChangeNotifier {
  MiDiaProvider({
    required this._servicio,
    required this._smartStudy,
    required this._habitos,
    required this._salud,
    required this._preferencias,
  });

  final MiDiaService _servicio;
  final SmartStudyService _smartStudy;
  final HabitosService _habitos;
  final SaludService _salud;
  final PreferenciasService _preferencias;

  EstadoCarga estado = EstadoCarga.inicial;
  String? mensajeError;
  ResumenDia? resumen;

  /// Materias por id, para mostrar el nombre y el color en las tareas.
  Map<int, Materia> materias = {};
  Map<int, int> coloresMaterias = {};

  /// Mejor racha actual (null si no se pudo calcular: el chip no se muestra).
  int? racha;

  /// Hábitos que se están marcando/desmarcando ahora mismo (para mostrar un indicador).
  final Set<int> habitosOcupados = {};
  bool aguaOcupada = false;

  /// Carga el resumen. Con [silencioso] no se borra lo que ya se ve (deslizar para recargar).
  Future<void> cargar({bool silencioso = false}) async {
    if (!silencioso || resumen == null) {
      estado = EstadoCarga.cargando;
      notifyListeners();
    }
    try {
      final hoy = Fechas.hoy();
      // Future.wait: las peticiones van al mismo tiempo
      final resultados = await Future.wait([_servicio.obtener(hoy), _smartStudy.listarMaterias()]);
      resumen = resultados[0] as ResumenDia;
      final lista = resultados[1] as List<Materia>;
      materias = {for (final m in lista) m.id: m};
      coloresMaterias = await _preferencias.coloresMaterias(materias.keys);
      estado = EstadoCarga.listo;
      mensajeError = null;
      notifyListeners();
      await _cargarRacha(hoy);
    } on ApiException catch (e) {
      mensajeError = e.mensaje;
      estado = resumen == null ? EstadoCarga.error : EstadoCarga.listo;
      notifyListeners();
      if (silencioso && resumen != null) rethrow; // la pantalla lo muestra como mensaje
    }
  }

  Future<void> _cargarRacha(DateTime hoy) async {
    try {
      racha = await _servicio.mejorRachaActual(resumen!.habitos.map((h) => h.id).toList(), hoy);
    } on ApiException {
      racha = null; // si falla, simplemente no se muestra el chip
    }
    notifyListeners();
  }

  /// Marca o desmarca un hábito de hoy y recarga el resumen.
  Future<void> alternarHabito(HabitoDelDia habito) async {
    habitosOcupados.add(habito.id);
    notifyListeners();
    try {
      final hoy = Fechas.hoy();
      if (habito.cumplido) {
        await _habitos.desmarcar(habito.id, hoy);
      } else {
        await _habitos.marcar(habito.id, hoy);
      }
      await cargar(silencioso: true);
    } finally {
      habitosOcupados.remove(habito.id);
      notifyListeners();
    }
  }

  /// Suma un vaso de [vasoMl] mililitros al agua de hoy y recarga el resumen.
  Future<void> sumarVaso(int vasoMl) async {
    aguaOcupada = true;
    notifyListeners();
    try {
      await _salud.cambiarAgua(Fechas.hoy(), vasoMl);
      await cargar(silencioso: true);
    } finally {
      aguaOcupada = false;
      notifyListeners();
    }
  }

  /// Al cerrar sesión no deben quedar datos del usuario anterior en memoria.
  void limpiar() {
    estado = EstadoCarga.inicial;
    resumen = null;
    materias = {};
    racha = null;
    mensajeError = null;
    notifyListeners();
  }
}
