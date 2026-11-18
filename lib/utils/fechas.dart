import 'package:intl/intl.dart';

/// Ayudantes de fechas. El backend usa «YYYY-MM-DD» para fechas sin hora.
class Fechas {
  Fechas._();

  static const String _locale = 'es_CO';

  /// Hoy, sin hora (según el reloj del teléfono).
  static DateTime hoy() {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  /// Quita la hora de una fecha.
  static DateTime soloDia(DateTime fecha) => DateTime(fecha.year, fecha.month, fecha.day);

  /// DateTime → "2026-11-18" (formato que espera la API).
  static String aApi(DateTime fecha) => DateFormat('yyyy-MM-dd').format(fecha);

  /// "2026-11-18" → DateTime(2026, 11, 18).
  static DateTime desdeApi(String texto) {
    final partes = texto.split('-').map(int.parse).toList();
    return DateTime(partes[0], partes[1], partes[2]);
  }

  /// Lunes de la semana de [fecha] (las semanas empiezan en lunes).
  static DateTime lunesDe(DateTime fecha) => soloDia(fecha).subtract(Duration(days: fecha.weekday - 1));

  /// Diferencia en días entre dos fechas (sin contar horas).
  static int diasEntre(DateTime desde, DateTime hasta) =>
      DateTime.utc(hasta.year, hasta.month, hasta.day).difference(DateTime.utc(desde.year, desde.month, desde.day)).inDays;

  /// «Martes, 18 de noviembre».
  static String largo(DateTime fecha) => _capitalizar(DateFormat("EEEE, d 'de' MMMM", _locale).format(fecha));

  /// «18 nov».
  static String corto(DateTime fecha) => DateFormat('d MMM', _locale).format(fecha).replaceAll('.', '');

  /// «18 nov 2026».
  static String conAnio(DateTime fecha) => DateFormat('d MMM y', _locale).format(fecha).replaceAll('.', '');

  /// «mar» (día de la semana abreviado).
  static String diaSemanaCorto(DateTime fecha) => DateFormat('EEE', _locale).format(fecha).replaceAll('.', '');

  /// Texto relativo para entregas: «Hoy», «Mañana», «Ayer», «En 3 días», «Hace 2 días» o la fecha.
  static String relativo(DateTime fecha, {DateTime? referencia}) {
    final dias = diasEntre(referencia ?? hoy(), fecha);
    if (dias == 0) return 'Hoy';
    if (dias == 1) return 'Mañana';
    if (dias == -1) return 'Ayer';
    if (dias > 1 && dias <= 7) return 'En $dias días';
    if (dias < -1 && dias >= -7) return 'Hace ${-dias} días';
    return corto(fecha);
  }

  static String _capitalizar(String texto) => texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);
}
