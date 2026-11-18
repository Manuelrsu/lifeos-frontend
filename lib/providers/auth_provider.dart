import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import '../services/almacen_sesion.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// En qué punto está la sesión. La raíz de la app decide qué pantalla mostrar con esto.
enum EstadoSesion {
  /// Revisando si hay un token guardado (se ve el Splash).
  iniciando,

  /// Hay token guardado pero no se pudo comprobar (servidor apagado o sin internet).
  errorConexion,

  /// Sin sesión: Bienvenida, login o registro.
  sinSesion,

  /// Sesión válida: la app principal.
  conSesion,
}

/// Estado de la sesión (ChangeNotifier: avisa a las pantallas cuando algo cambia).
class AuthProvider extends ChangeNotifier {
  // `this._api` guarda el parámetro en el campo privado; al llamar se escribe `api:`
  AuthProvider({required this._api, required this._servicio, required this._almacen}) {
    // Si cualquier petición privada responde 401, la sesión se cierra aquí
    _api.alExpirarSesion = _sesionExpirada;
  }

  final ApiService _api;
  final AuthService _servicio;
  final AlmacenSesion _almacen;

  EstadoSesion estado = EstadoSesion.iniciando;
  Usuario? usuario;

  /// Mensaje para mostrar una sola vez (por ejemplo, «Tu sesión expiró»).
  String? avisoPendiente;

  /// Para que la navegación vuelva a la primera pantalla cuando se cierra la sesión.
  VoidCallback? alCerrarSesion;

  /// Al abrir la app: ¿hay un token guardado y sigue sirviendo?
  Future<void> cargarSesionGuardada() async {
    estado = EstadoSesion.iniciando;
    notifyListeners();

    final token = await _almacen.leerToken();
    if (token == null) {
      estado = EstadoSesion.sinSesion;
      notifyListeners();
      return;
    }

    _api.token = token;
    try {
      usuario = await _servicio.obtenerPerfil(); // comprueba el token con el servidor
      estado = EstadoSesion.conSesion;
    } on ApiException catch (e) {
      if (e.codigo == 401) {
        // _sesionExpirada ya limpió todo (lo llamó ApiService)
        return;
      }
      // Sin conexión: no borramos el token; el usuario puede reintentar
      avisoPendiente = e.mensaje;
      estado = EstadoSesion.errorConexion;
    }
    notifyListeners();
  }

  /// Inicia sesión y guarda el token en el almacenamiento cifrado.
  Future<void> iniciarSesion({required String correo, required String contrasena}) async {
    final sesion = await _servicio.iniciarSesion(correo: correo, contrasena: contrasena);
    await _almacen.guardarToken(sesion.token);
    _api.token = sesion.token;
    usuario = sesion.usuario;
    estado = EstadoSesion.conSesion;
    notifyListeners();
  }

  /// Registra la cuenta y entra directamente (registro + login).
  Future<void> registrar({required String nombre, required String correo, required String contrasena}) async {
    await _servicio.registrar(nombre: nombre, correo: correo, contrasena: contrasena);
    await iniciarSesion(correo: correo, contrasena: contrasena);
  }

  /// Cierra la sesión en el servidor (revoca el token) y en el teléfono.
  /// Aunque el servidor no responda, la sesión local se cierra igual.
  Future<void> cerrarSesion() async {
    try {
      await _servicio.cerrarSesion();
    } on ApiException {
      // Si no hay conexión el token igual se borra del teléfono
    }
    await _limpiar();
  }

  /// Actualiza el usuario guardado (después de editar el perfil).
  void actualizarUsuario(Usuario nuevo) {
    usuario = nuevo;
    notifyListeners();
  }

  /// Toma el aviso pendiente y lo borra (para mostrarlo una sola vez).
  String? tomarAviso() {
    final aviso = avisoPendiente;
    avisoPendiente = null;
    return aviso;
  }

  void _sesionExpirada(String mensaje) {
    avisoPendiente = mensaje;
    _limpiar();
  }

  Future<void> _limpiar() async {
    _api.token = null;
    usuario = null;
    estado = EstadoSesion.sinSesion;
    await _almacen.borrarToken();
    alCerrarSesion?.call();
    notifyListeners();
  }
}
