import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/mensajes.dart';
import '../../utils/validadores.dart';
import '../../widgets/botones.dart';
import '../auth/formulario_auth.dart';

/// Cambiar contraseña (PUT /api/usuarios/me/contrasena).
/// Si la actual es incorrecta el backend responde 422 (no 401), así que la sesión no se cierra.
class CambiarContrasenaScreen extends StatefulWidget {
  const CambiarContrasenaScreen({super.key});

  @override
  State<CambiarContrasenaScreen> createState() => _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState extends State<CambiarContrasenaScreen> {
  final _formulario = GlobalKey<FormState>();
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _guardando = false;
  Map<String, String> _erroresServidor = {};

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await context.read<AuthService>().cambiarContrasena(actual: _actual.text, nueva: _nueva.text);
      if (!mounted) return;
      mostrarMensaje(context, 'Contraseña actualizada');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _erroresServidor = e.errores;
      });
      if (e.errores.isEmpty) mostrarMensaje(context, e.mensaje, error: true);
    }
  }

  void _limpiar(String _) {
    if (_erroresServidor.isNotEmpty) setState(() => _erroresServidor = {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: SafeArea(
        child: Form(
          key: _formulario,
          child: ListView(
            padding: const EdgeInsets.all(AppMedidas.margenPantalla),
            children: [
              CampoContrasena(
                controlador: _actual,
                etiqueta: 'Contraseña actual',
                validador: Validadores.contrasenaObligatoria,
                errorServidor: _erroresServidor['contrasena_actual'],
                alCambiar: _limpiar,
              ),
              const SizedBox(height: 16),
              CampoContrasena(
                controlador: _nueva,
                etiqueta: 'Contraseña nueva',
                validador: Validadores.contrasenaNueva,
                errorServidor: _erroresServidor['contrasena_nueva'],
                alCambiar: _limpiar,
                ayuda: 'Mínimo 8 caracteres, con letras y números',
              ),
              const SizedBox(height: 16),
              CampoContrasena(
                controlador: _confirmacion,
                etiqueta: 'Confirmar contraseña nueva',
                validador: (valor) => Validadores.confirmacion(valor, _nueva.text),
                alCambiar: _limpiar,
                accionTeclado: TextInputAction.done,
                alEnviar: (_) => _guardar(),
              ),
              const SizedBox(height: 28),
              PillButton(texto: 'Cambiar contraseña', cargando: _guardando, onPressed: _guardar),
            ],
          ),
        ),
      ),
    );
  }
}
