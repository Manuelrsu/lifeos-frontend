import '../utils/fechas.dart';

/// Agua tomada en un día (una fila por día): {id, fecha, cantidad_ml, fecha_creacion}.
class RegistroHidratacion {
  const RegistroHidratacion({required this.fecha, required this.cantidadMl, this.id});

  final int? id;
  final DateTime fecha;
  final int cantidadMl;

  factory RegistroHidratacion.fromJson(Map<String, dynamic> json) => RegistroHidratacion(
        id: json['id'] as int?,
        fecha: Fechas.desdeApi(json['fecha'] as String),
        cantidadMl: json['cantidad_ml'] as int,
      );
}

/// Horas dormidas (la fecha es la del día en que despertó): {id, fecha, horas, fecha_creacion}.
class RegistroSueno {
  const RegistroSueno({required this.fecha, required this.horas, this.id});

  final int? id;
  final DateTime fecha;
  final double horas;

  factory RegistroSueno.fromJson(Map<String, dynamic> json) => RegistroSueno(
        id: json['id'] as int?,
        fecha: Fechas.desdeApi(json['fecha'] as String),
        // (as num).toDouble(): el JSON puede traer 8 o 8.0
        horas: (json['horas'] as num).toDouble(),
      );
}

/// Actividad física o entrenamiento (puede haber varias por día).
class Actividad {
  const Actividad({
    required this.id,
    required this.fecha,
    required this.tipo,
    required this.duracionMinutos,
    this.descripcion,
  });

  final int id;
  final DateTime fecha;
  final String tipo;
  final int duracionMinutos;
  final String? descripcion;

  factory Actividad.fromJson(Map<String, dynamic> json) => Actividad(
        id: json['id'] as int,
        fecha: Fechas.desdeApi(json['fecha'] as String),
        tipo: json['tipo'] as String,
        duracionMinutos: json['duracion_minutos'] as int,
        descripcion: json['descripcion'] as String?,
      );
}

/// Estadísticas de GET /api/salud/estadisticas (sin las recomendaciones: la app no las muestra).
class EstadisticasSalud {
  const EstadisticasSalud({
    required this.dias,
    required this.promedioMl,
    required this.diasConAgua,
    required this.diasMetaCumplida,
    required this.metaMl,
    required this.promedioHoras,
    required this.diasConSueno,
    required this.totalActividades,
    required this.minutosTotales,
    required this.diasActivos,
  });

  final int dias;
  final double? promedioMl;
  final int diasConAgua;
  final int diasMetaCumplida;
  final int metaMl;
  final double? promedioHoras;
  final int diasConSueno;
  final int totalActividades;
  final int minutosTotales;
  final int diasActivos;

  factory EstadisticasSalud.fromJson(Map<String, dynamic> json) {
    final agua = json['hidratacion'] as Map<String, dynamic>;
    final sueno = json['sueno'] as Map<String, dynamic>;
    final actividad = json['actividad'] as Map<String, dynamic>;
    return EstadisticasSalud(
      dias: json['dias'] as int,
      promedioMl: (agua['promedio_ml'] as num?)?.toDouble(),
      diasConAgua: agua['dias_con_registro'] as int,
      diasMetaCumplida: agua['dias_meta_cumplida'] as int,
      metaMl: agua['meta_ml'] as int,
      promedioHoras: (sueno['promedio_horas'] as num?)?.toDouble(),
      diasConSueno: sueno['dias_con_registro'] as int,
      totalActividades: actividad['total_actividades'] as int,
      minutosTotales: actividad['minutos_totales'] as int,
      diasActivos: actividad['dias_activos'] as int,
    );
  }
}
