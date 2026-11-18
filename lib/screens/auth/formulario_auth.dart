import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/botones.dart';

/// Estructura común de Login y Registro: botón atrás, título, subtítulo y el formulario.
class MarcoFormularioAuth extends StatelessWidget {
  const MarcoFormularioAuth({super.key, required this.titulo, required this.subtitulo, required this.hijos});

  final String titulo;
  final String subtitulo;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppMedidas.margenPantalla, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconCircleButton(
                icono: Icons.arrow_back_rounded,
                tooltip: 'Volver',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 28),
              Text(titulo, style: tema.headlineLarge),
              const SizedBox(height: 8),
              Text(subtitulo, style: tema.bodyMedium?.copyWith(color: AppColors.textoSecundario)),
              const SizedBox(height: 28),
              ...hijos,
            ],
          ),
        ),
      ),
    );
  }
}

/// Recuadro rojo suave con el mensaje general del servidor (por ejemplo, credenciales incorrectas).
class AvisoError extends StatelessWidget {
  const AvisoError({super.key, required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.suave(AppColors.error),
        borderRadius: BorderRadius.circular(AppMedidas.radioItem),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(mensaje, style: const TextStyle(color: AppColors.error, fontSize: 14))),
        ],
      ),
    );
  }
}

/// Campo de contraseña con el botón de mostrar u ocultar.
class CampoContrasena extends StatefulWidget {
  const CampoContrasena({
    super.key,
    required this.controlador,
    required this.etiqueta,
    required this.validador,
    this.errorServidor,
    this.alCambiar,
    this.accionTeclado = TextInputAction.next,
    this.alEnviar,
    this.ayuda,
  });

  final TextEditingController controlador;
  final String etiqueta;
  final FormFieldValidator<String> validador;
  final String? errorServidor;
  final ValueChanged<String>? alCambiar;
  final TextInputAction accionTeclado;
  final ValueChanged<String>? alEnviar;
  final String? ayuda;

  @override
  State<CampoContrasena> createState() => _CampoContrasenaState();
}

class _CampoContrasenaState extends State<CampoContrasena> {
  bool _oculta = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controlador,
      obscureText: _oculta,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: widget.accionTeclado,
      onChanged: widget.alCambiar,
      onFieldSubmitted: widget.alEnviar,
      validator: widget.validador,
      // forceErrorText muestra el error que mandó el servidor para este campo
      forceErrorText: widget.errorServidor,
      decoration: InputDecoration(
        labelText: widget.etiqueta,
        helperText: widget.ayuda,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: _oculta ? 'Mostrar contraseña' : 'Ocultar contraseña',
          icon: Icon(_oculta ? Icons.visibility_rounded : Icons.visibility_off_rounded),
          onPressed: () => setState(() => _oculta = !_oculta),
        ),
      ),
    );
  }
}
