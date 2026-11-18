import '../utils/fechas.dart';

/// Evaluación (parcial, quiz...): {id, materia_id, nombre, fecha, descripcion, fecha_creacion}.
class Evaluacion {
  const Evaluacion({required this.id, required this.materiaId, required this.nombre, required this.fecha, this.descripcion});

  final int id;
  final int materiaId;
  final String nombre;
  final DateTime fecha;
  final String? descripcion;

  factory Evaluacion.fromJson(Map<String, dynamic> json) => Evaluacion(
        id: json['id'] as int,
        materiaId: json['materia_id'] as int,
        nombre: json['nombre'] as String,
        fecha: Fechas.desdeApi(json['fecha'] as String),
        descripcion: json['descripcion'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'materia_id': materiaId,
        'nombre': nombre,
        'fecha': Fechas.aApi(fecha),
        'descripcion': descripcion,
      };
}
