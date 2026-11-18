/// Hábito diario: {id, nombre, descripcion, activo, fecha_creacion}.
class Habito {
  const Habito({required this.id, required this.nombre, this.descripcion, this.activo = true});

  final int id;
  final String nombre;
  final String? descripcion;

  /// Un hábito inactivo no sale en Mi Día, pero conserva su historial.
  final bool activo;

  factory Habito.fromJson(Map<String, dynamic> json) => Habito(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        activo: json['activo'] as bool? ?? true,
      );
}

/// Estadísticas calculadas por el backend a partir del historial (no se guardan).
class EstadisticasHabito {
  const EstadisticasHabito({
    required this.totalCumplimientos,
    required this.diasVentana,
    required this.porcentajeCumplimiento,
    required this.rachaActual,
    required this.mejorRacha,
    this.ultimoCumplimiento,
  });

  final int totalCumplimientos;
  final int diasVentana; // días considerados (máximo 30)
  final double porcentajeCumplimiento;
  final int rachaActual;
  final int mejorRacha;
  final String? ultimoCumplimiento;

  factory EstadisticasHabito.fromJson(Map<String, dynamic> json) => EstadisticasHabito(
        totalCumplimientos: json['total_cumplimientos'] as int,
        diasVentana: json['dias_ventana'] as int,
        porcentajeCumplimiento: (json['porcentaje_cumplimiento'] as num).toDouble(),
        rachaActual: json['racha_actual'] as int,
        mejorRacha: json['mejor_racha'] as int,
        ultimoCumplimiento: json['ultimo_cumplimiento'] as String?,
      );
}
