import '../utils/fechas.dart';

/// Tarea académica: {id, materia_id, titulo, descripcion, fecha_entrega, prioridad, estado, fecha_creacion}.
class Tarea {
  const Tarea({
    required this.id,
    required this.materiaId,
    required this.titulo,
    required this.fechaEntrega,
    this.descripcion,
    this.prioridad = 'media',
    this.estado = 'pendiente',
  });

  static const prioridades = ['baja', 'media', 'alta'];

  final int id;
  final int materiaId;
  final String titulo;
  final String? descripcion;
  final DateTime fechaEntrega;
  final String prioridad; // baja | media | alta
  final String estado; // pendiente | completada

  bool get completada => estado == 'completada';

  /// Vencida: pendiente y con fecha de entrega anterior a hoy.
  bool vencidaEn(DateTime hoy) => !completada && Fechas.diasEntre(hoy, fechaEntrega) < 0;

  /// Próxima: pendiente y se entrega hoy o en los próximos 3 días (se resalta en ámbar).
  bool proximaEn(DateTime hoy) {
    final dias = Fechas.diasEntre(hoy, fechaEntrega);
    return !completada && dias >= 0 && dias <= 3;
  }

  factory Tarea.fromJson(Map<String, dynamic> json) => Tarea(
        id: json['id'] as int,
        materiaId: json['materia_id'] as int,
        titulo: json['titulo'] as String,
        descripcion: json['descripcion'] as String?,
        fechaEntrega: Fechas.desdeApi(json['fecha_entrega'] as String),
        prioridad: json['prioridad'] as String? ?? 'media',
        estado: json['estado'] as String? ?? 'pendiente',
      );

  /// Cuerpo para crear o actualizar (`POST /tareas`, `PUT /tareas/<id>`).
  Map<String, dynamic> toJson() => {
        'materia_id': materiaId,
        'titulo': titulo,
        'descripcion': descripcion,
        'fecha_entrega': Fechas.aApi(fechaEntrega),
        'prioridad': prioridad,
        'estado': estado,
      };
}
