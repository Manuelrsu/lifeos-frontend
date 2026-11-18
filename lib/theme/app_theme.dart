import 'package:flutter/material.dart';

/// Todos los colores de LifeOS en un solo lugar.
/// Las pantallas NUNCA escriben colores a mano: usan AppColors o Theme.of(context).
class AppColors {
  AppColors._();

  static const Color fondo = Color(0xFF121212);
  static const Color tarjeta = Color(0xFF1E1E1E);
  static const Color tarjetaClara = Color(0xFF262626); // inicio del degradado de las tarjetas
  static const Color tarjetaOscura = Color(0xFF1A1A1A); // fin del degradado y barra inferior
  static const Color superficie = Color(0xFF252525); // chips, campos y botones de icono
  static const Color borde = Color(0x0FFFFFFF); // blanco al 6 %

  static const Color texto = Color(0xFFF5F5F5);
  static const Color textoSecundario = Color(0xFF9E9E9E);

  // Acento principal (menta) y el texto oscuro que va encima
  static const Color menta = Color(0xFF7DD3C0);
  static const Color sobreMenta = Color(0xFF0F1F1C);

  // Acento turquesa, solo dentro de Salud
  static const Color saludClaro = Color(0xFF2DD4BF);
  static const Color saludOscuro = Color(0xFF0E7490);

  static const Color exito = Color(0xFF4ADE80);
  static const Color advertencia = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);

  /// Paleta fija para las materias (el usuario elige una al crearla).
  static const List<Color> paletaMaterias = [
    Color(0xFF7DD3C0), // menta
    Color(0xFFA78BFA), // morado
    Color(0xFF60A5FA), // azul
    Color(0xFFFBBF24), // ámbar
    Color(0xFFF472B6), // rosa
    Color(0xFF86EFAC), // verde
  ];

  static const List<String> nombresPaleta = ['Menta', 'Morado', 'Azul', 'Ámbar', 'Rosa', 'Verde'];

  /// Versión suave de un color: fondo del color al 15 %.
  static Color suave(Color color) => color.withValues(alpha: 0.15);

  static const LinearGradient degradadoTarjeta = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tarjetaClara, tarjetaOscura],
  );

  static const LinearGradient degradadoSalud = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [saludClaro, saludOscuro],
  );
}

/// Radios y espaciados del sistema de diseño (múltiplos de 4).
class AppMedidas {
  AppMedidas._();

  static const double radioTarjeta = 24;
  static const double radioItem = 16;
  static const double radioPildora = 999;
  static const double botonIcono = 44;
  static const double margenPantalla = 20;
}

/// Tema oscuro global. Se aplica a TODAS las pantallas desde MaterialApp.
ThemeData crearTemaOscuro() {
  const esquema = ColorScheme.dark(
    primary: AppColors.menta,
    onPrimary: AppColors.sobreMenta,
    secondary: AppColors.menta,
    onSecondary: AppColors.sobreMenta,
    surface: AppColors.tarjeta,
    onSurface: AppColors.texto,
    onSurfaceVariant: AppColors.textoSecundario,
    surfaceContainerHighest: AppColors.superficie,
    error: AppColors.error,
    onError: AppColors.fondo,
    outline: AppColors.borde,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: esquema,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: AppColors.fondo,
  );

  final redondeoItem = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppMedidas.radioItem));
  const pildora = StadiumBorder();

  return base.copyWith(
    textTheme: base.textTheme
        .copyWith(
          headlineLarge: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.15),
          headlineMedium: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.2),
          titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          bodyLarge: const TextStyle(fontSize: 16),
          bodyMedium: const TextStyle(fontSize: 14),
          bodySmall: const TextStyle(fontSize: 12, color: AppColors.textoSecundario),
          labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        )
        .apply(bodyColor: AppColors.texto, displayColor: AppColors.texto, fontFamily: 'Poppins'),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.fondo,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.texto,
      titleTextStyle: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.texto),
    ),
    cardTheme: CardThemeData(
      color: AppColors.tarjeta,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppMedidas.radioTarjeta),
        side: const BorderSide(color: AppColors.borde),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.superficie,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: const TextStyle(color: AppColors.textoSecundario),
      labelStyle: const TextStyle(color: AppColors.textoSecundario),
      floatingLabelStyle: const TextStyle(color: AppColors.menta),
      prefixIconColor: AppColors.textoSecundario,
      suffixIconColor: AppColors.textoSecundario,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppMedidas.radioItem), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppMedidas.radioItem),
        borderSide: const BorderSide(color: AppColors.borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppMedidas.radioItem),
        borderSide: const BorderSide(color: AppColors.menta, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppMedidas.radioItem),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppMedidas.radioItem),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      errorStyle: const TextStyle(color: AppColors.error),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.menta,
        foregroundColor: AppColors.sobreMenta,
        disabledBackgroundColor: AppColors.superficie,
        disabledForegroundColor: AppColors.textoSecundario,
        minimumSize: const Size(64, 52),
        shape: pildora,
        textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.menta,
        shape: pildora,
        textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.texto,
        side: const BorderSide(color: AppColors.borde),
        minimumSize: const Size(64, 48),
        shape: pildora,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.menta,
      foregroundColor: AppColors.sobreMenta,
      shape: CircleBorder(),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.tarjetaOscura,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.suave(AppColors.menta),
      indicatorShape: pildora,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((estados) {
        final activo = estados.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
          color: activo ? AppColors.menta : AppColors.textoSecundario,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((estados) {
        final activo = estados.contains(WidgetState.selected);
        return IconThemeData(color: activo ? AppColors.menta : AppColors.textoSecundario);
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.superficie,
      contentTextStyle: const TextStyle(fontFamily: 'Poppins', color: AppColors.texto, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: redondeoItem,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.tarjeta,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppMedidas.radioTarjeta)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.tarjeta,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: AppColors.textoSecundario,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppMedidas.radioTarjeta))),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppColors.tarjeta,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: AppColors.superficie,
      headerForegroundColor: AppColors.texto,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppMedidas.radioTarjeta)),
      todayBorder: const BorderSide(color: AppColors.menta),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: const BorderSide(color: AppColors.textoSecundario, width: 1.5),
      fillColor: WidgetStateProperty.resolveWith(
        (estados) => estados.contains(WidgetState.selected) ? AppColors.menta : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(AppColors.sobreMenta),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (estados) => estados.contains(WidgetState.selected) ? AppColors.sobreMenta : AppColors.textoSecundario,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (estados) => estados.contains(WidgetState.selected) ? AppColors.menta : AppColors.superficie,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.menta),
    dividerTheme: const DividerThemeData(color: AppColors.borde, thickness: 1),
    listTileTheme: const ListTileThemeData(iconColor: AppColors.textoSecundario, textColor: AppColors.texto),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.superficie,
      surfaceTintColor: Colors.transparent,
      shape: redondeoItem,
    ),
  );
}
