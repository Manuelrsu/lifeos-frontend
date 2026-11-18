import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias que SOLO se guardan en este teléfono (el backend no tiene esos campos).
/// No son datos de MySQL: si el usuario cambia de teléfono, vuelven a los valores por defecto.
class PreferenciasService {
  static const _claveVaso = 'tamano_vaso_ml';
  static const _prefijoColor = 'color_materia_';

  static const int vasoPorDefecto = 250;
  static const List<int> tamanosVaso = [200, 250, 300, 500];

  /// Meta de sueño de la app (el backend no tiene meta de sueño): 8 horas.
  static const double metaSuenoHoras = 8;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Mililitros que suma cada «+1 vaso».
  Future<int> tamanoVaso() async => (await _prefs).getInt(_claveVaso) ?? vasoPorDefecto;

  Future<void> guardarTamanoVaso(int ml) async => (await _prefs).setInt(_claveVaso, ml);

  /// Índice del color de la paleta elegido para una materia (0 si no se eligió).
  Future<Map<int, int>> coloresMaterias(Iterable<int> ids) async {
    final prefs = await _prefs;
    return {for (final id in ids) id: prefs.getInt('$_prefijoColor$id') ?? (id % 6)};
  }

  Future<void> guardarColorMateria(int idMateria, int indiceColor) async =>
      (await _prefs).setInt('$_prefijoColor$idMateria', indiceColor);

  Future<void> borrarColorMateria(int idMateria) async => (await _prefs).remove('$_prefijoColor$idMateria');
}
