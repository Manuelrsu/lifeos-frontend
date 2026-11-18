import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/validadores.dart';
import '../../widgets/botones.dart';
import 'formulario_auth.dart';
import 'registro_screen.dart';

/// Inicio de sesión conectado a POST /api/auth/login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();

  bool _enviando = false;
  String? _errorGeneral;
  Map<String, String> _erroresServidor = {};

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  /// Al escribir se borran los errores que mandó el servidor.
  void _limpiarErrores(String _) {
    if (_errorGeneral != null || _erroresServidor.isNotEmpty) {
      setState(() {
        _errorGeneral = null;
        _erroresServidor = {};
      });
    }
  }

  Future<void> _enviar() async {
    if (!_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _enviando = true);
    try {
      await context.read<AuthProvider>().iniciarSesion(correo: _correo.text, contrasena: _contrasena.text);
      // La raíz de la app cambia sola a Mi Día; aquí solo se cierran las pantallas de login
      if (mounted) Navigator.of(context).popUntil((ruta) => ruta.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _errorGeneral = e.mensaje;
        _erroresServidor = e.errores;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MarcoFormularioAuth(
      titulo: 'Inicia sesión',
      subtitulo: 'Qué bueno verte de nuevo. Ingresa con tu correo y contraseña.',
      hijos: [
        Form(
          key: _formulario,
          child: AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  controller: _correo,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  onChanged: _limpiarErrores,
                  validator: Validadores.correo,
                  forceErrorText: _erroresServidor['correo'],
                  decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.mail_outline_rounded)),
                ),
                const SizedBox(height: 16),
                CampoContrasena(
                  controlador: _contrasena,
                  etiqueta: 'Contraseña',
                  validador: Validadores.contrasenaObligatoria,
                  errorServidor: _erroresServidor['contrasena'],
                  alCambiar: _limpiarErrores,
                  accionTeclado: TextInputAction.done,
                  alEnviar: (_) => _enviar(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_errorGeneral != null) ...[AvisoError(mensaje: _errorGeneral!), const SizedBox(height: 20)],
        PillButton(texto: 'Iniciar sesión', cargando: _enviando, onPressed: _enviar),
        const SizedBox(height: 12),
        Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('¿No tienes cuenta?', style: TextStyle(color: AppColors.textoSecundario)),
              TextButton(
                onPressed: _enviando
                    ? null
                    : () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RegistroScreen())),
                child: const Text('Crear cuenta'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
