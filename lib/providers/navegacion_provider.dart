import 'package:flutter/foundation.dart';

/// Qué pestaña de la barra inferior está abierta. Permite que una pantalla
/// lleve a otra (por ejemplo, «Ver todo» de Mi Día abre SmartStudy).
class NavegacionProvider extends ChangeNotifier {
  static const int miDia = 0;
  static const int smartStudy = 1;
  static const int habitos = 2;
  static const int salud = 3;

  int indice = miDia;

  /// Sub-pestaña de Salud que se debe abrir (0 Hidratación … 3 Entrenamiento).
  int pestanaSalud = 0;

  void irA(int nuevo, {int? subPestanaSalud}) {
    indice = nuevo;
    if (subPestanaSalud != null) pestanaSalud = subPestanaSalud;
    notifyListeners();
  }

  /// Al cerrar sesión se vuelve a Mi Día.
  void reiniciar() {
    indice = miDia;
    pestanaSalud = 0;
    notifyListeners();
  }
}
