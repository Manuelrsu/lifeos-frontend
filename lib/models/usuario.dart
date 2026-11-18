/// Usuario tal como lo devuelve el backend: {id, nombre, correo, fecha_creacion}.
class Usuario {
  const Usuario({required this.id, required this.nombre, required this.correo, this.fechaCreacion});

  final int id;
  final String nombre;
  final String correo;

  /// Fecha de registro (el backend la manda en UTC con «Z»).
  final DateTime? fechaCreacion;

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      correo: json['correo'] as String,
      fechaCreacion: json['fecha_creacion'] == null ? null : DateTime.parse(json['fecha_creacion'] as String),
    );
  }

  Map<String, dynamic> toJson() => {'nombre': nombre, 'correo': correo};

  /// Primer nombre, para el saludo («Hola de nuevo, Ana»).
  String get primerNombre => nombre.trim().split(RegExp(r'\s+')).first;

  /// Iniciales para el avatar: «Ana Pérez» → «AP».
  String get iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }
}
