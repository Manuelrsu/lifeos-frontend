/// Validaciones de formularios. Son las MISMAS reglas que aplica el backend
/// (utils/validaciones.py), para avisar antes de enviar. Devuelven el mensaje
/// de error o null si el valor es válido (así las usa TextFormField).
class Validadores {
  Validadores._();

  static final RegExp _patronCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? nombre(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'El nombre es obligatorio';
    if (texto.length < 2 || texto.length > 100) return 'El nombre debe tener entre 2 y 100 caracteres';
    return null;
  }

  static String? correo(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'El correo es obligatorio';
    if (texto.length > 120) return 'El correo debe tener como máximo 120 caracteres';
    if (!_patronCorreo.hasMatch(texto)) return 'El correo no tiene un formato válido';
    return null;
  }

  /// Para el login solo se exige que no esté vacía (el servidor decide si es correcta).
  static String? contrasenaObligatoria(String? valor) {
    if (valor == null || valor.isEmpty) return 'La contraseña es obligatoria';
    return null;
  }

  static String? contrasenaNueva(String? valor) {
    if (valor == null || valor.isEmpty) return 'La contraseña es obligatoria';
    if (valor.length < 8) return 'La contraseña debe tener al menos 8 caracteres';
    if (valor.length > 128) return 'La contraseña debe tener como máximo 128 caracteres';
    final tieneLetra = RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]').hasMatch(valor);
    final tieneNumero = RegExp(r'\d').hasMatch(valor);
    if (!tieneLetra || !tieneNumero) return 'La contraseña debe tener letras y números';
    return null;
  }

  static String? confirmacion(String? valor, String original) {
    if (valor == null || valor.isEmpty) return 'Confirma la contraseña';
    if (valor != original) return 'Las contraseñas no coinciden';
    return null;
  }

  /// Texto obligatorio con longitud mínima y máxima (títulos, nombres de materia...).
  static String? texto(String? valor, {required int minimo, required int maximo, String campo = 'Este campo'}) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return '$campo es obligatorio';
    if (texto.length < minimo) return 'Debe tener al menos $minimo caracteres';
    if (texto.length > maximo) return 'Debe tener como máximo $maximo caracteres';
    return null;
  }

  /// Texto opcional con longitud máxima (descripciones, docente...).
  static String? textoOpcional(String? valor, {required int maximo}) {
    if ((valor?.trim().length ?? 0) > maximo) return 'Debe tener como máximo $maximo caracteres';
    return null;
  }

  /// Entero obligatorio dentro de un rango (minutos, mililitros...).
  static String? entero(String? valor, {required int minimo, required int maximo}) {
    final numero = int.tryParse(valor?.trim() ?? '');
    if (numero == null) return 'Escribe un número entero';
    if (numero < minimo || numero > maximo) return 'Debe estar entre $minimo y $maximo';
    return null;
  }

  /// Horas de sueño: número mayor que 0 y hasta 24, con máximo 2 decimales (acepta coma).
  static String? horasSueno(String? valor) {
    final texto = (valor ?? '').trim().replaceAll(',', '.');
    final numero = double.tryParse(texto);
    if (numero == null) return 'Escribe un número, por ejemplo 7.5';
    if (numero <= 0 || numero > 24) return 'Debe ser mayor que 0 y como máximo 24';
    if (texto.contains('.') && texto.split('.').last.length > 2) return 'Usa como máximo 2 decimales';
    return null;
  }
}
