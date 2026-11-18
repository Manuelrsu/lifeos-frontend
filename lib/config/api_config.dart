/// Configuración de la conexión con el backend (un solo lugar para cambiarla).
class ApiConfig {
  ApiConfig._();

  /// URL base de la API de Flask.
  ///
  /// - Emulador Android: 10.0.2.2 es el 127.0.0.1 de la PC (valor por defecto).
  /// - Teléfono físico: flutter run --dart-define=API_URL=http://192.168.1.50:5000
  static const String urlBase = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:5000');

  /// Tiempo máximo de espera de cada petición.
  static const Duration tiempoEspera = Duration(seconds: 10);
}
