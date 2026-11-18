import '../utils/fechas.dart';
import 'evaluacion.dart';
import 'salud.dart';
import 'tarea.dart';

/// Hábito tal como aparece en Mi Día: {id, nombre, cumplido}.
class HabitoDelDia {
  const HabitoDelDia({required this.id, required this.nombre, required this.cumplido});

  final int id;
  final String nombre;
  final bool cumplido;

  factory HabitoDelDia.fromJson(Map<String, dynamic> json) =>
      HabitoDelDia(id: json['id'] as int, nombre: json['nombre'] as String, cumplido: json['cumplido'] as bool);
}

/// Respuesta de GET /api/mi-dia. El backend NO guarda este resumen:
/// lo arma leyendo tareas, evaluaciones, hábitos y salud.
class ResumenDia {
  const ResumenDia({
    required this.fecha,
    required this.totalPendientes,
    required this.vencidas,
    required this.paraHoy,
    required this.proximas,
    required this.evaluacionesProximas,
    required this.habitosTotal,
    required this.habitosCompletados,
    required this.habitosPorcentaje,
    required this.habitos,
    required this.aguaMl,
    required this.metaAguaMl,
    required this.aguaPorcentaje,
    required this.horasSueno,
    required this.actividades,
    required this.minutosActividad,
  });

  final DateTime fecha;

  // Tareas
  final int totalPendientes;
  final List<Tarea> vencidas;
  final List<Tarea> paraHoy;
  final List<Tarea> proximas;

  // Evaluaciones de los próximos 7 días
  final List<Evaluacion> evaluacionesProximas;

  // Hábitos activos
  final int habitosTotal;
  final int habitosCompletados;
  final double habitosPorcentaje;
  final List<HabitoDelDia> habitos;

  // Salud (null = no hay registro ese día; el backend no inventa un 0)
  final int? aguaMl;
  final int metaAguaMl;
  final double aguaPorcentaje;
  final double? horasSueno;
  final List<Actividad> actividades;
  final int minutosActividad;

  /// Entregas para mostrar: vencidas, las de hoy y las próximas, por fecha.
  List<Tarea> get entregas => [...vencidas, ...paraHoy, ...proximas]..sort((a, b) => a.fechaEntrega.compareTo(b.fechaEntrega));

  /// Progreso combinado del día (0 a 1): promedio de los hábitos y del agua.
  /// Las tareas no entran porque el backend solo informa las PENDIENTES
  /// (no cuántas se completaron hoy), así que no hay un «x de y» honesto para ellas.
  double get progresoCombinado {
    final partes = <double>[];
    if (habitosTotal > 0) partes.add(habitosPorcentaje / 100);
    partes.add((aguaPorcentaje / 100).clamp(0.0, 1.0));
    return partes.reduce((a, b) => a + b) / partes.length;
  }

  factory ResumenDia.fromJson(Map<String, dynamic> json) {
    List<Tarea> tareas(dynamic lista) =>
        (lista as List).map((t) => Tarea.fromJson(t as Map<String, dynamic>)).toList();

    final t = json['tareas'] as Map<String, dynamic>;
    final e = json['evaluaciones'] as Map<String, dynamic>;
    final h = json['habitos'] as Map<String, dynamic>;
    final s = json['salud'] as Map<String, dynamic>;
    final agua = s['hidratacion'] as Map<String, dynamic>;
    final sueno = s['sueno'] as Map<String, dynamic>;

    return ResumenDia(
      fecha: Fechas.desdeApi(json['fecha'] as String),
      totalPendientes: t['total_pendientes'] as int,
      vencidas: tareas(t['vencidas']),
      paraHoy: tareas(t['para_hoy']),
      proximas: tareas(t['proximas']),
      evaluacionesProximas:
          (e['proximas'] as List).map((x) => Evaluacion.fromJson(x as Map<String, dynamic>)).toList(),
      habitosTotal: h['total'] as int,
      habitosCompletados: h['completados'] as int,
      habitosPorcentaje: (h['porcentaje'] as num).toDouble(),
      habitos: (h['lista'] as List).map((x) => HabitoDelDia.fromJson(x as Map<String, dynamic>)).toList(),
      aguaMl: agua['cantidad_ml'] as int?,
      metaAguaMl: agua['meta_ml'] as int,
      aguaPorcentaje: (agua['porcentaje'] as num).toDouble(),
      horasSueno: (sueno['horas'] as num?)?.toDouble(),
      actividades: (s['actividades'] as List).map((x) => Actividad.fromJson(x as Map<String, dynamic>)).toList(),
      minutosActividad: s['minutos_actividad'] as int,
    );
  }
}
