import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda el token en el almacenamiento cifrado del teléfono
/// (Android Keystore), para que la sesión siga abierta al reabrir la app.
class AlmacenSesion {
  AlmacenSesion([FlutterSecureStorage? almacen]) : _almacen = almacen ?? const FlutterSecureStorage();

  static const _claveToken = 'token_lifeos';
  final FlutterSecureStorage _almacen;

  Future<String?> leerToken() => _almacen.read(key: _claveToken);

  Future<void> guardarToken(String token) => _almacen.write(key: _claveToken, value: token);

  Future<void> borrarToken() => _almacen.delete(key: _claveToken);
}
