import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lifeos/main.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/chips.dart';
import 'package:lifeos/widgets/estados.dart';
import 'package:lifeos/widgets/progreso.dart';
import 'package:lifeos/widgets/segmented_tabs.dart';
import 'package:lifeos/widgets/week_check_row.dart';

/// Envuelve un widget con el tema de LifeOS para probarlo solo.
Widget conTema(Widget hijo) => MaterialApp(theme: crearTemaOscuro(), home: Scaffold(body: hijo));

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));

  group('Tema', () {
    test('el tema es oscuro y usa los colores de LifeOS', () {
      final tema = crearTemaOscuro();
      expect(tema.brightness, Brightness.dark);
      expect(tema.scaffoldBackgroundColor, AppColors.fondo);
      expect(tema.colorScheme.primary, AppColors.menta);
      expect(tema.colorScheme.onPrimary, AppColors.sobreMenta);
      expect(tema.inputDecorationTheme.fillColor, AppColors.superficie);
    });

    testWidgets('la app arranca con el tema oscuro y en español', (tester) async {
      await tester.pumpWidget(const LifeOSApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
      expect(app.locale, const Locale('es', 'CO'));

      final contexto = tester.element(find.byType(Scaffold).first);
      expect(Theme.of(contexto).brightness, Brightness.dark);
      expect(Theme.of(contexto).scaffoldBackgroundColor, AppColors.fondo);
    });
  });

  group('Componentes', () {
    testWidgets('StatusChip y StreakChip muestran su texto', (tester) async {
      await tester.pumpWidget(conTema(const Column(children: [
        StatusChip(texto: '3 de 5 completadas', tipo: TipoEstado.exito),
        StreakChip(dias: 12),
      ])));
      expect(find.text('3 de 5 completadas'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('WeekCheckRow avisa qué día se tocó y respeta los deshabilitados', (tester) async {
      final tocados = <int>[];
      await tester.pumpWidget(conTema(WeekCheckRow(
        cumplidos: const [true, false, false, false, false, false, false],
        habilitados: const [true, true, true, false, false, false, false],
        indiceHoy: 2,
        onTocarDia: tocados.add,
      )));
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.tap(find.text('J')); // jueves: deshabilitado (futuro)
      await tester.tap(find.text('V').first);
      expect(tocados, isEmpty);

      await tester.tap(find.text('M').at(1)); // miércoles (hoy)
      expect(tocados, [2]);
    });

    testWidgets('SegmentedTabs cambia de pestaña', (tester) async {
      int? elegida;
      await tester.pumpWidget(conTema(SegmentedTabs(
        opciones: const ['Hidratación', 'Descanso'],
        seleccionada: 0,
        onCambio: (i) => elegida = i,
      )));
      await tester.tap(find.text('Descanso'));
      expect(elegida, 1);
    });

    testWidgets('ProgressRing muestra el centro y acepta valores fuera de rango', (tester) async {
      await tester.pumpWidget(conTema(const ProgressRing(progreso: 1.7, centro: Text('170 %'))));
      await tester.pumpAndSettle();
      expect(find.text('170 %'), findsOneWidget);
    });

    testWidgets('ErrorState llama a Reintentar', (tester) async {
      var reintentos = 0;
      await tester.pumpWidget(conTema(ErrorState(mensaje: 'Sin conexión', onReintentar: () => reintentos++)));
      await tester.tap(find.text('Reintentar'));
      expect(reintentos, 1);
    });
  });
}
