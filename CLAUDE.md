# CLAUDE.md — LifeOS Frontend (Flutter)

Este archivo es la guía de trabajo para Claude Code. Léelo completo antes de hacer cualquier cosa.
Mi solicitud original va completa en el **Apéndice A**. Si este documento y el apéndice se contradicen, manda este documento.

---

## 1. Contexto

- **Proyecto:** LifeOS, «Todo tu progreso en una sola aplicación». Es una app móvil para estudiantes que reúne organización académica, hábitos y salud básica. Es el proyecto académico de mi técnica en programación de software.
- **Plazo:** unos 4 días. Prioridad: una app funcional, estable, con un diseño oscuro profesional y fácil de presentar al profesor.
- **Sistema:** Windows, VS Code y PowerShell. **Todavía no tengo instalados Flutter ni Android Studio.**
- **Backend:** ya está terminado y probado (105+ pruebas en verde). Usa Flask, SQLAlchemy, MySQL y tokens. Está en:
  `D:\USUARIO\Desktop\Backend LifeOS\lifeos-backend`
- **Frontend (este proyecto):** `D:\USUARIO\Desktop\Frontend LifeOS` (el proyecto Flutter va directamente en la raíz de esta carpeta, junto a este CLAUDE.md)
- **Diseño:** no hay un diseño en Figma. La guía visual son las 4 imágenes de referencia de `docs/diseno/` (sección 4).
- El backend se hizo contigo (Claude Code) con esta misma metodología: fases, pruebas reales, un commit por fase y honestidad sobre lo que se probó y lo que no. Repite esa forma de trabajar.

## 2. Reglas de trabajo (obligatorias)

1. **Trabaja directamente en los archivos.** Crea, escribe, ejecuta y corrige. No me entregues solo ejemplos o instrucciones, salvo en lo que únicamente yo pueda hacer (instalar programas con interfaz gráfica, abrir el emulador, mirar la pantalla).
2. **Sigue las fases en orden** (sección 8). Al terminar cada fase:
   - ejecuta `flutter analyze` (0 errores; justifica las advertencias que queden),
   - ejecuta `flutter test` y muéstrame la salida real,
   - haz **un commit** con el mensaje `Fase N: <descripción>`. **Nunca hagas `git push`.**
   - Después sigue con la siguiente fase **sin esperar mi confirmación**, salvo en los casos de la regla 6.
3. **No avances con pruebas en rojo ni con el análisis fallando.** Si algo falla, intenta resolverlo antes de detenerte.
4. **No afirmes nada que no hayas ejecutado.** Distingue siempre entre «lo ejecuté y funcionó», «compila pero no lo vi en pantalla» y «no lo probé».
5. **El backend es de solo lectura.** Puedes leer su código y su documentación, y arrancarlo para probar la conexión, pero **no modifiques ningún archivo de `lifeos-backend`** ni su base de datos (salvo los datos de prueba de la sección 7.5). Si al backend le falta algo, anótalo en `docs/PENDIENTES_BACKEND.md` y sigue.
6. **Detente y pregúntame solo si:**
   - falta algo del entorno que solo yo puedo instalar o configurar (Fase 0),
   - una decisión cambia la arquitectura o afecta datos existentes,
   - al backend le falta una ruta imprescindible para una pantalla principal y no hay alternativa razonable.
7. **No borres ni sobrescribas archivos existentes** sin revisar su contenido y decirme por qué es necesario.
8. **Cero datos falsos disfrazados.** No simules que algo se guarda en MySQL si solo está en memoria o en el teléfono. Si usas datos de demostración, márcalos en el código (`// DATOS DE DEMOSTRACIÓN`) y en la interfaz (una etiqueta «Demo»).
9. **Cero botones decorativos.** Todo botón hace algo real. Si una función no está lista, no pongas el botón o muestra un mensaje claro de «Próximamente».
10. **Código simple para estudiar:** sin patrones avanzados (nada de BLoC, Riverpod con generadores, GetX ni inyección de dependencias compleja). Comentarios breves en español que expliquen el porqué. Todos los textos de la interfaz en español.

## 3. Tecnologías

- Flutter (estable) y Dart, Material 3, consumo de la API REST por HTTP.
- **Prohibido:** React, HTML, CSS o JavaScript para la interfaz. Es una app móvil real en Flutter para Android.
- **Dependencias:** usa el mínimo necesario. La propuesta es esta; si cambias algo, justifícalo:
  - `http` para las peticiones,
  - `provider` para el estado (sencillo y fácil de explicar),
  - `flutter_secure_storage` para guardar el token,
  - `intl` para las fechas en español (`es_CO`).
  - No uses fuentes descargadas en tiempo de ejecución. Si quieres una tipografía propia, inclúyela en `assets/fonts/`.

## 4. Identidad visual (tema oscuro en TODAS las pantallas)

### 4.1 Referencias
En `docs/diseno/` hay 4 imágenes de referencia. **Míralas antes de la Fase 2.** Son la guía de estilo, no un diseño que haya que copiar al píxel. Están en inglés y con datos inventados; LifeOS va en español y solo muestra datos reales.

| Imagen | Qué tomar de ella | Dónde se usa en LifeOS |
|---|---|---|
| `01-tareas-calendario.png` | Tarjetas grises con un degradado sutil, acento menta, botones circulares con borde fino, chip de saludo con avatar, título grande, «Ver todo», tarjetas de tarea con fecha y franja de progreso (%), calendario de círculos con el día actual en menta, y la bienvenida con tarjetas apiladas y un botón circular con anillo | Bienvenida, Mi Día, SmartStudy |
| `02-estudio-racha.png` | Chip de racha con 🔥 y número, saludo grande en negrita, pestañas con contador, chip verde «3 de 5 completadas», ítems con un icono cuadrado de color, botón principal tipo píldora | Mi Día, SmartStudy |
| `03-habitos.png` | Título grande, tarjeta por hábito: icono, nombre, mini barra de progreso, «50 % · 1/2 esta semana», fila de 7 cuadros L-M-M-J-V-S-D con ✓ en los días cumplidos, insignia de racha («12 d») y botón de estadísticas | Hábitos |
| `04-salud.png` | Pestañas segmentadas tipo píldora, anillo circular de progreso con el valor en el centro, cuadrícula 2×2 de indicadores, una botella o vaso que se llena según el porcentaje, degradado y brillo turquesa solo en Salud, botón píldora con degradado | Salud |

### 4.2 Sistema de diseño (todo en `lib/theme/app_theme.dart`)

| Token | Valor |
|---|---|
| Fondo | `#121212` |
| Tarjeta | `#1E1E1E`, con un degradado sutil de `#262626` (arriba a la izquierda) a `#1A1A1A`, y un borde de 1 px blanco al 6 % |
| Superficie secundaria (chips, campos, botones de icono) | `#252525` |
| Texto principal / secundario | `#F5F5F5` / `#9E9E9E` |
| **Acento principal (menta)** | `#7DD3C0`; el texto encima del acento es oscuro (`#0F1F1C`) |
| Acento de Salud | degradado turquesa `#2DD4BF` → `#0E7490`, solo dentro de Salud |
| Éxito / advertencia / error | `#4ADE80` / `#FBBF24` / `#F87171`, en versiones suaves (fondo del color al 15 % y texto del color) |
| Colores de materia | una paleta fija de 6 tonos apagados (menta, morado, azul, ámbar, rosa, verde) que el usuario elige al crear la materia; se usa solo en el icono cuadrado y en detalles pequeños |
| Radios | tarjetas 24 · ítems internos 16 · chips y botones en píldora (999) · botones de icono circulares de 44 px |
| Espaciado | múltiplos de 4; margen lateral de pantalla 20 |
| Tipografía | **Poppins** (licencia OFL), incluida en `assets/fonts/` (Regular, Medium, SemiBold y Bold). Descárgala del repositorio `google/fonts` (`ofl/poppins`). Si no puedes, usa la predeterminada y avísame. Títulos de pantalla de 28 a 32 en negrita; texto de 14 a 16 |
| Iconos | Material Symbols / Icons **redondeados** en toda la app |

### 4.3 Componentes reutilizables (en `lib/widgets/`)
`LifeCard` (tarjeta con degradado y borde), `IconCircleButton`, `PillButton` (principal en menta y secundario de texto), `StatusChip` (éxito, advertencia, neutro), `StreakChip` (🔥 N), `SectionHeader` (título + «Ver todo» opcional), `ProgressRing` (anillo animado con el valor en el centro), `MiniProgressBar`, `WeekCheckRow` (7 cuadros de la semana), `SegmentedTabs` (píldora), `EmptyState` (icono, texto y acción) y `ErrorState` (mensaje y botón Reintentar).

### 4.4 Reglas
- **Ningún color escrito a mano en las pantallas:** usa `Theme.of(context)` o `AppColors`.
- **Solo datos reales.** Las referencias muestran ritmo cardíaco, temperatura, pasos, participantes, campanas de notificación, etc. **No los copies si LifeOS no tiene esos datos o esa función.** Nada de iconos de campana sin notificaciones reales.
- **Sin evaluaciones de salud.** No uses textos como «Good!» o «Bueno» para el sueño: muestra solo cifras y el progreso hacia la meta («7 h 12 min · meta 8 h · 90 %»).
- Animaciones sutiles: llenado del anillo y la botella, ✓ al completar y transiciones cortas (200 a 300 ms).
- Adaptable a distintos tamaños de pantalla: `SafeArea`, scroll donde haga falta y sin desbordamientos.
- Nada recargado: el menta es el único acento fuerte fuera de Salud.

## 5. Estructura de la app

- **Navegación inferior (4 pestañas):** Mi Día · SmartStudy · Hábitos · Salud. Barra oscura `#1A1A1A`, icono activo en menta con una etiqueta y un indicador en píldora.
- **Perfil:** se abre desde el avatar del chip de saludo, arriba a la izquierda en Mi Día y en la barra superior de los demás módulos.
- **Entrenamiento:** va **dentro de Salud**; no es un módulo aparte.
- Flujo de inicio: Splash → (¿hay un token válido guardado?) → Mi Día, o si no → Bienvenida → Iniciar sesión / Registro.

### Pantallas

**A. Autenticación**
- **Bienvenida** (ref. 01 izquierda): ilustración hecha con widgets (2 o 3 `LifeCard` de ejemplo, apiladas e inclinadas, con tareas, un hábito y vasos de agua de muestra), el título «Todo tu progreso en una sola aplicación», un subtítulo breve, el botón circular menta con anillo y flecha (va al login) y el enlace «Crear cuenta».
- **Login y registro** (nombre, correo, contraseña y confirmación): campos `#252525` redondeados, validaciones, mensajes de error del servidor, estado de carga (botón desactivado y con indicador) y sesión persistente.

**B. Mi Día (inicio)** (refs. 01 centro y 02)
- Arriba: chip de saludo con avatar (iniciales) y «Hola de nuevo, *Nombre*», más el `StreakChip` con la mejor racha actual de los hábitos (si el backend la da).
- Título grande con la fecha en español («Martes, 18 de noviembre»).
- `LifeCard` de progreso del día con un `ProgressRing` (% combinado de tareas, hábitos y agua, según lo que dé el backend) y un `StatusChip` («3 de 5 completadas»).
- Fila horizontal de accesos rápidos (tarjetas cuadradas con icono): SmartStudy, Hábitos, Agua (+1 vaso directo) y Entrenamiento.
- Sección «Próximas entregas» con hasta 3 tarjetas de tarea (fecha, materia y título) y «Ver todo» que lleva a SmartStudy.
- Sección «Hábitos de hoy» con una marca rápida.
- Se recarga deslizando hacia abajo.

**C. SmartStudy** (refs. 02 y 01 derecha)
- Pestañas «Pendientes (n)» / «Completadas (n)» con el `StatusChip` del día.
- Lista de tareas: icono cuadrado con el color de la materia, título, materia, fecha de entrega (resaltada en ámbar si es próxima y en rojo si está vencida) y casilla para completar.
- Pantalla de materias: crear, editar y eliminar, con el selector de color de la paleta.
- Formulario de tarea: título, descripción, materia y fecha de entrega (`showDatePicker` con el tema oscuro).
- **Deseable, solo si sobra tiempo al final:** un calendario mensual con círculos (como la ref. 01) que marca los días con entregas.

**D. Hábitos** (ref. 03)
- Título «Mis hábitos» y botón «+» para crear.
- Una tarjeta por hábito: icono, nombre, `MiniProgressBar` con «x % · n/7 esta semana», `WeekCheckRow` (el día de hoy se puede tocar para marcar o desmarcar; los días pasados solo se muestran, salvo que el backend permita registrarlos), insignia de racha y botón de estadísticas que abre una hoja inferior con la racha actual, la mejor racha y el % semanal o mensual, según lo que dé el backend.
- Mensaje motivador breve cuando se completan todos los hábitos del día.

**E. Salud** (ref. 04)
- `SegmentedTabs`: Hidratación · Descanso · Actividad · Entrenamiento.
- **Hidratación:** un vaso o botella que se llena según el % de la meta, «Llevas X de Y vasos», «Te faltan Z», botón píldora con degradado «+1 vaso» (y quitar uno si el backend lo permite).
- **Descanso:** registrar las horas de sueño (y las de dormir y despertar si el backend las tiene), un `ProgressRing` con las horas frente a la meta y el historial de los últimos días.
- **Actividad y Entrenamiento:** formulario (tipo, duración y notas, según el backend), resumen en una cuadrícula 2×2 (minutos de la semana, sesiones, etc.) e historial.
- **Sin recomendaciones médicas ni diagnósticos.**

**F. Perfil:** avatar con iniciales, nombre, correo, información de la cuenta, editar perfil o cambiar contraseña (si el backend lo permite), configuración básica (por ejemplo, la meta de agua) y cerrar sesión (llamando al logout del backend si existe), con confirmación.

## 6. Arquitectura del código

```
Frontend LifeOS/
├── lib/
│   ├── main.dart
│   ├── config/
│   │   └── api_config.dart        # URL base centralizada
│   ├── theme/
│   │   └── app_theme.dart         # AppColors + ThemeData oscuro
│   ├── models/                    # Clases con fromJson / toJson
│   ├── services/
│   │   ├── api_service.dart       # Cliente HTTP único: token, errores, timeouts
│   │   ├── auth_service.dart
│   │   └── ...                    # Un servicio por módulo
│   ├── providers/                 # Estado con ChangeNotifier (uno por módulo)
│   ├── navigation/
│   │   └── main_shell.dart        # Scaffold con la BottomNavigationBar
│   ├── screens/
│   │   ├── auth/  home/  study/  habits/  health/  profile/
│   └── widgets/                   # Tarjetas, barras de progreso, estados vacíos, etc.
├── test/
├── tool/
│   └── smoke_test.dart            # Prueba contra el backend real (sección 7.5)
├── docs/
│   ├── INTEGRACION_BACKEND.md
│   ├── PENDIENTES_BACKEND.md
│   └── diseno/                    # Imágenes de referencia (no borrar)
├── README.md
└── pubspec.yaml
```

Flujo, parecido a las capas del backend: **Pantalla → Provider → Service → ApiService → API Flask**.

## 7. Conexión con el backend

### 7.1 Antes de escribir un solo servicio
Lee, en `lifeos-backend`: `CLAUDE.md`, `README.md`, `docs/API.md`, `DOCUMENTACION.md`, la guía para Flutter (si existe), `docs/LifeOS.postman_collection.json` y los `controllers/`. Con eso:
1. Haz la lista de **todas** las rutas, con su método, los datos que esperan, la respuesta, los códigos de error y si exigen token.
2. Confirma el **formato real** de las respuestas JSON (éxito y error) y cómo se envía el token (`Authorization: Bearer <token>`, según lo que diga el código).
3. Escribe `docs/INTEGRACION_BACKEND.md` con una tabla **Pantalla / acción → endpoint → estado** (Conectado / Falta en el backend / Solo local).
**No inventes rutas ni nombres de campos. Si la documentación y el código no coinciden, manda el código.**

### 7.2 URL de la API centralizada
- En `lib/config/api_config.dart`, con `String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:5000')`.
- `10.0.2.2` es la dirección con la que el **emulador Android** llega al `127.0.0.1` de mi PC. El backend escucha en `127.0.0.1:5000`, así que funciona sin cambiarlo.
- **Teléfono físico:** necesita la IP local del PC (por ejemplo, `--dart-define=API_URL=http://192.168.1.50:5000`) y que el backend escuche en `0.0.0.0`. El backend se niega a arrancar con `FLASK_DEBUG` activo y `0.0.0.0`, así que en ese caso va con debug apagado. Documéntalo en el README.
- **HTTP sin cifrar:** Android lo bloquea por defecto. Habilítalo **solo en debug** (`android:usesCleartextTraffic="true"` en `android/app/src/debug/AndroidManifest.xml`) y explícalo en el README.

### 7.3 ApiService
- Agrega el token a cada petición, con un timeout de unos 10 s.
- Convierte cualquier fallo en un error claro en español: sin conexión o servidor apagado, 400/422 (mostrar el mensaje del backend), 401 (sesión expirada: borrar el token y volver al login), 404, 409 y 500.
- Las pantallas nunca muestran trazas técnicas; muestran un mensaje amable y, si aplica, un botón **Reintentar**.

### 7.4 Si falta una ruta
Deja preparada la integración (modelo y método del servicio), anótala en `docs/PENDIENTES_BACKEND.md` con el **método, ruta, cuerpo y respuesta esperados exactos** y, en la interfaz, oculta la función o márcala como «Demo», sin fingir que se guarda.

### 7.5 Prueba contra el backend real
- Escribe `tool/smoke_test.dart`, ejecutable con `dart run tool/smoke_test.dart`. Debe registrar un usuario de prueba **único** (`smoke_<timestamp>@lifeos.test`), iniciar sesión y crear, consultar y actualizar al menos un registro de cada módulo, imprimiendo OK o FALLO por paso.
- Para ejecutarlo, arranca el backend en segundo plano desde su carpeta, con su `venv` (`.\venv\Scripts\python.exe app.py`), y deténlo al terminar. Si no puedes arrancarlo, dime exactamente qué comando ejecutar yo.
- Esos usuarios de prueba quedan en `lifeos_db`. Dime cuántos creaste para que pueda borrarlos si quiero.

## 8. Fases

> El orden es distinto al de mi solicitud original: la autenticación y el cliente HTTP van antes que los módulos, para que cada módulo nazca conectado al backend real y no haya que rehacerlo después.

**Fase 0 — Entorno (aquí sí debes guiarme).**
Comprueba `flutter --version`, `flutter doctor -v`, `git --version` y Java. Si falta algo, dame instrucciones concretas para Windows, un paso a la vez, y espera a que te confirme:
- **Flutter SDK** en una ruta **sin espacios** (por ejemplo, `C:\src\flutter`) y agregado al PATH. Si puedes hacerlo tú con `git clone` (rama `stable`), hazlo y dime solo qué debo hacer yo con el PATH.
- **Android Studio**: instalación, Android SDK, *SDK Command-line Tools*, `flutter doctor --android-licenses` y un emulador (por ejemplo, Pixel con una API reciente). Si el emulador no arranca por la virtualización, dime cómo activarla o cómo usar mi celular con depuración USB.
- La meta es que `flutter doctor` no tenga errores en Flutter, Android toolchain y Android Studio (lo de Chrome o Visual Studio no importa).
- Si la carpeta del proyecto (que tiene un espacio en «Frontend LifeOS») causa errores de compilación, avísame y propón otra ruta.

**Fase 1 — Análisis del backend.** Sección 7.1 completa y `docs/INTEGRACION_BACKEND.md`. Resúmeme en pocas líneas qué rutas hay y qué falta.

**Fase 2 — Proyecto y tema.** `flutter create --org com.lifeos --project-name lifeos --platforms android .` en la raíz de `Frontend LifeOS` (sin tocar este CLAUDE.md ni `docs/diseno/`), `.gitignore`, `git init`, dependencias, la estructura de la sección 6, la fuente Poppins, `app_theme.dart`, los componentes de la sección 4.3 y la configuración de la API. Haz una prueba que verifique que la app arranca con el tema oscuro.

**Fase 3 — Núcleo y autenticación.** `ApiService`, modelos de usuario, `AuthService`, `AuthProvider`, almacenamiento del token, splash, bienvenida, login y registro conectados, y la navegación principal con las 4 pestañas y el Perfil. Pruebas: modelos (`fromJson`), `ApiService` con `MockClient` de `package:http/testing.dart` (éxito, 401, 400 y error de conexión) y validaciones de los formularios.

**Fase 4 — Mi Día y Perfil**, conectados.

**Fase 5 — SmartStudy**, conectado.

**Fase 6 — Hábitos**, conectado.

**Fase 7 — Salud** (hidratación, descanso, actividad y entrenamiento), conectado.

En las Fases 4 a 7, cada módulo lleva sus modelos, servicio, provider, pantallas, estados de carga, vacío y error, mensajes de confirmación, pruebas de modelos y servicio con `MockClient`, y al menos una prueba de widget.

**Fase 8 — Integración y cierre.**
- Ejecuta `tool/smoke_test.dart` contra el backend real y muéstrame la salida.
- `flutter analyze`, `flutter test` y `flutter build apk --debug` (para demostrar que compila para Android).
- Revisión visual en el código: tema oscuro en todas las pantallas, sin colores fuera del tema y sin botones sin acción.
- Escribe el `README.md` (sección 9) y actualiza `docs/INTEGRACION_BACKEND.md` y `docs/PENDIENTES_BACKEND.md`.
- Dame una **lista de comprobación manual** para que yo pruebe la app en el emulador en unos 10 minutos (qué tocar y qué debería ver).

## 9. README.md

Debe incluir: requisitos, instalación de Flutter y Android Studio (resumida), cómo arrancar el backend primero, `flutter pub get`, cómo crear y abrir el emulador, `flutter run` (emulador y teléfono físico con `--dart-define`), cómo ejecutar las pruebas y el smoke test, la estructura del proyecto, las dependencias y para qué sirve cada una, y los problemas frecuentes (servidor apagado, `10.0.2.2`, HTTP sin cifrar, token expirado, licencias de Android).

## 10. Informe final (cuando termines la Fase 8)

1. Qué pantallas desarrollaste.
2. Qué funciona (y cómo lo comprobaste).
3. Qué está conectado al backend real.
4. Qué sigue pendiente o solo es local o demo.
5. Las dependencias que usaste.
6. Cómo ejecutar la app.
7. Los comandos que debo usar.
8. Los errores que encontraste y cómo los solucionaste.
9. **Qué no probaste** (por ejemplo, «no vi la app en pantalla; solo compila y pasa las pruebas»).

---

## Apéndice A — Mi solicitud original (completa)

### PROYECTO LIFEOS — DESARROLLO COMPLETO DEL FRONTEND EN FLUTTER

Quiero que trabajes directamente en los archivos de mi proyecto y desarrolles el frontend móvil de LifeOS utilizando Flutter y Dart.

IMPORTANTE: No quiero que solamente me proporciones ejemplos de código o instrucciones. Quiero que tú mismo crees los archivos, escribas el código, organices las carpetas, ejecutes los comandos necesarios y desarrolles la aplicación directamente en el entorno de trabajo.

Tenemos aproximadamente cuatro días para terminar el proyecto, por lo que necesitamos priorizar una aplicación funcional, estable, visualmente atractiva y fácil de presentar.

### 1. CONTEXTO DEL PROYECTO

LifeOS es una aplicación móvil cuyo objetivo es centralizar la organización académica, los hábitos personales y el seguimiento básico de la salud.

Su eslogan es:

"Todo tu progreso en una sola aplicación".

La aplicación está dirigida principalmente a estudiantes, aunque puede ser utilizada por cualquier persona que quiera organizar sus actividades y mejorar sus hábitos.

La idea es que el usuario tenga en un solo lugar las herramientas necesarias para organizar su día, estudiar, registrar sus hábitos y llevar un seguimiento básico de su salud.

### 2. TECNOLOGÍAS OBLIGATORIAS

- Flutter.
- Dart.
- Material Design.
- Consumo de API REST mediante HTTP.
- Backend desarrollado con Python y Flask.
- Base de datos MySQL administrada desde el backend.

No utilices React, HTML, CSS ni JavaScript para construir el frontend.

Toda la interfaz debe ser una aplicación móvil real desarrollada en Flutter.

### 3. IDENTIDAD VISUAL Y DISEÑO

Quiero una interfaz DARK MODE, moderna, elegante y minimalista.

La inspiración visual debe combinar:

- Notion: organización, minimalismo y limpieza visual.
- Duolingo: facilidad de uso, elementos amigables y motivación.
- Aplicaciones modernas de productividad: tarjetas, indicadores de progreso y navegación sencilla.

Características visuales:

- Fondo principal oscuro, preferiblemente #121212 o similar.
- Tarjetas en tonos #1E1E1E.
- Superficies secundarias en tonos #252525.
- Texto principal blanco o gris claro.
- Texto secundario gris.
- Un color de acento verde o turquesa para representar progreso y actividad.
- Bordes redondeados.
- Iconografía consistente.
- Espaciados equilibrados.
- Tipografía moderna y legible.
- Animaciones sutiles cuando aporten valor.

Evita interfaces recargadas, demasiados colores, botones gigantes y elementos innecesarios.

La aplicación debe verse profesional, pero también debe ser fácil de comprender.

IMPORTANTE: El tema oscuro debe aplicarse a TODAS las pantallas, sin excepciones.

### 4. ESTRUCTURA GENERAL DE LA APLICACIÓN

LifeOS debe contar con cinco apartados principales:

1. Mi Día.
2. SmartStudy.
3. Hábitos.
4. Salud.
5. Perfil.

El entrenamiento debe estar incluido dentro de Salud y no debe convertirse en un módulo independiente.

Implementa una navegación inferior (Bottom Navigation Bar) que permita desplazarse fácilmente entre los cuatro primeros apartados.

El Perfil puede abrirse desde un icono en la parte superior de la aplicación.

### 5. PANTALLAS QUE DEBES DESARROLLAR

#### A. AUTENTICACIÓN

Desarrolla:

- Pantalla de bienvenida.
- Pantalla de inicio de sesión.
- Pantalla de registro.

El registro debe solicitar los datos necesarios, como nombre, correo electrónico y contraseña.

Incluye validaciones de formularios, mensajes de error y estados de carga.

El inicio de sesión debe conectarse con el backend cuando sus endpoints estén disponibles.

#### B. MI DÍA

Será la pantalla principal de LifeOS.

Debe incluir:

- Saludo personalizado con el nombre del usuario.
- Fecha actual.
- Tarjeta de resumen del progreso diario.
- Cantidad de tareas pendientes.
- Hábitos completados.
- Resumen de actividad.
- Accesos rápidos a los otros módulos.

Quiero que sea una pantalla visualmente atractiva y que transmita la idea de tener todo organizado en un solo lugar.

#### C. SMARTSTUDY

Este apartado estará enfocado en la organización académica.

Debe permitir:

- Crear materias.
- Visualizar materias registradas.
- Crear tareas académicas.
- Asignar títulos y descripciones.
- Establecer fechas de entrega.
- Marcar tareas como completadas.
- Consultar tareas pendientes y completadas.

Utiliza tarjetas organizadas y una interfaz sencilla.

#### D. HÁBITOS

Este módulo debe permitir:

- Crear hábitos personalizados.
- Registrar el cumplimiento diario.
- Marcar hábitos como completados.
- Visualizar el progreso.
- Mostrar estadísticas sencillas.

Incluye indicadores visuales de progreso y una presentación motivadora.

#### E. SALUD

Este apartado debe reunir las funciones básicas de bienestar.

Incluye:

1. Hidratación:
   - Mostrar el registro diario de vasos de agua.
   - Permitir agregar vasos.
   - Mostrar el progreso diario.

2. Descanso:
   - Permitir registrar las horas de sueño.
   - Mostrar el registro correspondiente.

3. Actividad física:
   - Registrar actividades realizadas.
   - Mostrar el progreso.

4. Entrenamiento:
   - Incluir un apartado dentro de Salud.
   - Permitir registrar actividades o entrenamientos.
   - Mostrar un historial sencillo.

No implementes recomendaciones médicas ni diagnósticos.

#### F. PERFIL

Debe incluir:

- Nombre del usuario.
- Correo electrónico.
- Información básica de la cuenta.
- Opción para cerrar sesión.
- Acceso a configuraciones básicas.

### 6. ARQUITECTURA Y ORGANIZACIÓN DEL CÓDIGO

Quiero que el proyecto esté organizado correctamente.

Puedes utilizar una estructura similar a esta:

frontend/
│
├── lib/
│   ├── main.dart
│   │
│   ├── models/
│   │
│   ├── screens/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── study/
│   │   ├── habits/
│   │   ├── health/
│   │   └── profile/
│   │
│   ├── widgets/
│   │
│   ├── services/
│   │   ├── api_service.dart
│   │   └── auth_service.dart
│   │
│   ├── theme/
│   │   └── app_theme.dart
│   │
│   └── navigation/
│
├── assets/
│
└── pubspec.yaml

Puedes ajustar la estructura si existe una mejor alternativa, pero evita complicaciones innecesarias.

El código debe ser claro, modular y fácil de mantener.

### 7. CONEXIÓN CON EL BACKEND

El backend de LifeOS está desarrollado con:

- Python.
- Flask.
- SQLAlchemy.
- MySQL.

Antes de implementar las conexiones, revisa la estructura y los endpoints existentes del backend.

No inventes rutas ni supongas que los endpoints funcionan.

Necesito que:

1. Identifiques las rutas disponibles.
2. Compruebes qué datos espera cada endpoint.
3. Construyas un servicio para realizar solicitudes HTTP.
4. Conectes el inicio de sesión y el registro.
5. Conectes las operaciones de los módulos.
6. Manejes correctamente los errores y las respuestas del servidor.

Si alguna ruta todavía no existe, deja preparada la integración y documenta exactamente qué necesita el backend.

No simules que los datos se guardan en MySQL si realmente solo están almacenados localmente.

Si necesitas utilizar datos temporales para desarrollar la interfaz, identifícalos claramente como datos de demostración.

Centraliza la URL de la API para que sea fácil cambiarla.

Ten en cuenta que cuando Flutter se ejecuta en un emulador Android, la dirección del servidor local puede ser diferente de localhost. Documenta cómo configurarla.

### 8. REQUISITOS DE FUNCIONAMIENTO

La aplicación debe:

- Abrir correctamente.
- Navegar entre sus diferentes pantallas.
- Tener formularios funcionales.
- Mostrar mensajes de confirmación y error.
- Permitir crear, consultar y actualizar los registros principales.
- Manejar estados de carga.
- Mantener una apariencia consistente.
- Adaptarse a diferentes tamaños de pantalla.

No quiero botones decorativos que no hagan nada.

Si una funcionalidad todavía no está conectada al backend, debes indicarlo.

### 9. FORMA DE TRABAJO

Trabaja directamente en los archivos.

Quiero que sigas este orden:

FASE 1:
Analiza el entorno, verifica Flutter y revisa si la carpeta frontend está correctamente configurada.

FASE 2:
Configura el proyecto Flutter y crea el tema oscuro global.

FASE 3:
Desarrolla la navegación y las pantallas principales.

FASE 4:
Desarrolla los módulos Mi Día, SmartStudy, Hábitos, Salud y Perfil.

FASE 5:
Implementa las pantallas de autenticación.

FASE 6:
Prepara y realiza la conexión con el backend existente.

FASE 7:
Ejecuta flutter pub get, flutter analyze y las pruebas disponibles.

FASE 8:
Corrige los errores y comprueba que la aplicación pueda ejecutarse.

No te detengas después de presentar el plan. Continúa implementando las fases.

Si encuentras un problema, intenta resolverlo antes de detenerte.

No elimines ni sobrescribas archivos existentes sin revisar su contenido y explicar por qué es necesario.

Si necesitas una decisión que pueda cambiar la arquitectura o afectar datos existentes, consúltame antes.

### 10. ENTREGA FINAL

Cuando termines, necesito que me informes:

1. Qué pantallas desarrollaste.
2. Qué funcionalidades funcionan.
3. Qué funcionalidades están conectadas al backend.
4. Qué funcionalidades siguen pendientes.
5. Qué dependencias utilizaste.
6. Cómo ejecutar la aplicación.
7. Qué comandos debo utilizar.
8. Qué errores encontraste y cómo los solucionaste.

También crea un README.md dentro de frontend con las instrucciones necesarias para instalar y ejecutar el proyecto.

RECORDATORIO FINAL:

Tenemos muy poco tiempo.

Prioriza una aplicación móvil funcional, completa en sus apartados principales, con un diseño oscuro profesional y una estructura de código sencilla.

No quiero que te limites a darme instrucciones: quiero que programes directamente el frontend de LifeOS en Flutter dentro de mi entorno de trabajo.