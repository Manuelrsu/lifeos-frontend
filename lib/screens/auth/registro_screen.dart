import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/validadores.dart';
import '../../widgets/botones.dart';
import 'formulario_auth.dart';
import 'login_screen.dart';

/// Registro conectado a POST /api/auth/registro (y luego inicia sesión solo).
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmacion = TextEditingController();

  bool _enviando = false;
  String? _errorGeneral;
  Map<String, String> _erroresServidor = {};

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _contrasena.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

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
      await context.read<AuthProvider>().registrar(
            nombre: _nombre.text,
            correo: _correo.text,
            contrasena: _contrasena.text,
          );
      if (mounted) Navigator.of(context).popUntil((ruta) => ruta.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        // 422 trae errores por campo; 409 (correo repetido) solo trae el mensaje,
        // que se muestra debajo del campo de correo
        _erroresServidor = e.codigo == 409 ? {'correo': e.mensaje} : e.errores;
        _errorGeneral = _erroresServidor.isEmpty ? e.mensaje : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MarcoFormularioAuth(
      titulo: 'Crea tu cuenta',
      subtitulo: 'Tus materias, hábitos y salud, en un solo lugar.',
      hijos: [
        Form(
          key: _formulario,
          child: AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  controller: _nombre,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  onChanged: _limpiarErrores,
                  validator: Validadores.nombre,
                  forceErrorText: _erroresServidor['nombre'],
                  decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline_rounded)),
                ),
                const SizedBox(height: 16),
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
                  validador: Validadores.contrasenaNueva,
                  errorServidor: _erroresServidor['contrasena'],
                  alCambiar: _limpiarErrores,
                  ayuda: 'Mínimo 8 caracteres, con letras y números',
                ),
                const SizedBox(height: 16),
                CampoContrasena(
                  controlador: _confirmacion,
                  etiqueta: 'Confirmar contraseña',
                  validador: (valor) => Validadores.confirmacion(valor, _contrasena.text),
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
        PillButton(texto: 'Crear cuenta', cargando: _enviando, onPressed: _enviar),
        const SizedBox(height: 12),
        Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('¿Ya tienes cuenta?', style: TextStyle(color: AppColors.textoSecundario)),
              TextButton(
                onPressed: _enviando
                    ? null
                    : () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Iniciar sesión'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
