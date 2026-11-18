import '../models/usuario.dart';
import 'api_service.dart';

/// Resultado del login: el token y el usuario.
class SesionIniciada {
  const SesionIniciada(this.token, this.usuario);
  final String token;
  final Usuario usuario;
}

/// Rutas de autenticación y perfil (/api/auth y /api/usuarios).
class AuthService {
  AuthService(this._api);

  final ApiService _api;

  /// POST /api/auth/registro → 201 con el usuario creado.
  Future<Usuario> registrar({required String nombre, required String correo, required String contrasena}) async {
    final datos = await _api.post('/api/auth/registro', {
      'nombre': nombre.trim(),
      'correo': correo.trim(),
      'contrasena': contrasena,
    });
    return Usuario.fromJson(datos as Map<String, dynamic>);
  }

  /// POST /api/auth/login → {token, tipo, expira_en_segundos, usuario}.
  Future<SesionIniciada> iniciarSesion({required String correo, required String contrasena}) async {
    final datos = await _api.post('/api/auth/login', {'correo': correo.trim(), 'contrasena': contrasena})
        as Map<String, dynamic>;
    return SesionIniciada(datos['token'] as String, Usuario.fromJson(datos['usuario'] as Map<String, dynamic>));
  }

  /// POST /api/auth/logout → revoca el token en el servidor.
  Future<void> cerrarSesion() => _api.post('/api/auth/logout');

  /// GET /api/usuarios/me
  Future<Usuario> obtenerPerfil() async =>
      Usuario.fromJson(await _api.get('/api/usuarios/me') as Map<String, dynamic>);

  /// PUT /api/usuarios/me (solo los campos enviados).
  Future<Usuario> actualizarPerfil({String? nombre, String? correo}) async {
    final cuerpo = <String, dynamic>{
      if (nombre != null) 'nombre': nombre.trim(),
      if (correo != null) 'correo': correo.trim(),
    };
    return Usuario.fromJson(await _api.put('/api/usuarios/me', cuerpo) as Map<String, dynamic>);
  }

  /// PUT /api/usuarios/me/contrasena
  Future<void> cambiarContrasena({required String actual, required String nueva}) =>
      _api.put('/api/usuarios/me/contrasena', {'contrasena_actual': actual, 'contrasena_nueva': nueva});
}
