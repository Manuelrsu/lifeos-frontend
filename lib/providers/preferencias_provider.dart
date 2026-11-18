import 'package:flutter/foundation.dart';

import '../services/preferencias_service.dart';

/// Preferencias locales (solo en este teléfono). Hoy: el tamaño del vaso de agua.
class PreferenciasProvider extends ChangeNotifier {
  PreferenciasProvider(this._servicio);

  final PreferenciasService _servicio;

  int vasoMl = PreferenciasService.vasoPorDefecto;

  Future<void> cargar() async {
    vasoMl = await _servicio.tamanoVaso();
    notifyListeners();
  }

  Future<void> cambiarVaso(int ml) async {
    await _servicio.guardarTamanoVaso(ml);
    vasoMl = ml;
    notifyListeners();
  }
}
