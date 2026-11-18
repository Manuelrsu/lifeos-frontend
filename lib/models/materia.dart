/// Materia: {id, nombre, docente, fecha_creacion}.
/// El color NO viene del backend: se guarda solo en el teléfono (ver PreferenciasService).
class Materia {
  const Materia({required this.id, required this.nombre, this.docente});

  final int id;
  final String nombre;
  final String? docente;

  factory Materia.fromJson(Map<String, dynamic> json) => Materia(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        docente: json['docente'] as String?,
      );

  Map<String, dynamic> toJson() => {'nombre': nombre, 'docente': docente};
}
