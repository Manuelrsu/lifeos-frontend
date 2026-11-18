# Integración con el backend de LifeOS

Fuente: el **código** de `lifeos-backend` (controllers, services y models), revisado el 2026-11-18 y comparado con `docs/API.md`. No se encontraron diferencias entre la documentación y el código en las rutas usadas aquí.

## 1. Reglas generales (confirmadas en el código)

- **URL base:** `http://10.0.2.2:5000` desde el emulador Android (es el `127.0.0.1` de la PC). Todas las rutas empiezan con `/api`.
- **Token:** encabezado `Authorization: Bearer <token>` (`controllers/decoradores.py`). Dura 24 h (`expira_en_segundos: 86400`) y no hay renovación.
- **Cuerpo:** JSON con `Content-Type: application/json`. Si falta o está mal formado → **400** «Se esperaba un cuerpo JSON válido».
- **Respuesta de éxito:** `{"ok": true, "mensaje": "...", "datos": <objeto | lista | null>}`
- **Respuesta de error:** `{"ok": false, "mensaje": "...", "errores": {"campo": "detalle"} | null}`
- **Códigos:** 200, 201 (creado), 400 (JSON inválido), 401 (sin token, token inválido, expirado o revocado; también credenciales incorrectas en el login), 404 (no existe **o es de otro usuario**), 405, 409 (duplicado), 413 (más de 1 MB), 422 (validación, con `errores` por campo), 500 y 503 (la base de datos no responde).
- **Fechas:** sin hora, `YYYY-MM-DD`. Con hora (`fecha_creacion`), ISO 8601 en UTC con `Z`.
- **«Hoy»:** el servidor usa la hora de Colombia. Las rutas que dependen de «hoy» aceptan `?fecha=YYYY-MM-DD` o `fecha` en el cuerpo. La app envía la fecha del teléfono.
- **Cambio de contraseña:** si la contraseña actual es incorrecta, el backend responde **422** (no 401), a propósito, para que la app no cierre la sesión.

## 2. Inventario de rutas

«Priv.» = exige token. Los campos con `?` son opcionales.

### Estado y autenticación
| Método | Ruta | Priv. | Cuerpo / parámetros | `datos` en la respuesta | Errores |
|---|---|---|---|---|---|
| GET | `/api/estado` | No | – | `{servidor, base_de_datos}` | 503 |
| POST | `/api/auth/registro` | No | `nombre` (2–100), `correo` (máx. 120, formato), `contrasena` (8–128, letras y números) | Usuario `{id, nombre, correo, fecha_creacion}` → 201 | 400, 409 correo repetido, 422 |
| POST | `/api/auth/login` | No | `correo`, `contrasena` | `{token, tipo: "Bearer", expira_en_segundos, usuario}` | 401 «Correo o contraseña incorrectos», 422 |
| POST | `/api/auth/logout` | Sí | – | `null` (revoca el token) | 401 |
| GET | `/api/usuarios/me` | Sí | – | Usuario | 401 |
| PUT | `/api/usuarios/me` | Sí | `nombre`?, `correo`? (al menos uno) | Usuario | 409, 422 |
| PUT | `/api/usuarios/me/contrasena` | Sí | `contrasena_actual`, `contrasena_nueva` | `null` | 422 (incluida una contraseña actual incorrecta) |

### SmartStudy (`/api/smartstudy`, todo privado)
| Método | Ruta | Cuerpo / parámetros | `datos` |
|---|---|---|---|
| POST | `/materias` | `nombre` (2–100, único por usuario → 409), `docente`? (máx. 100) | Materia `{id, nombre, docente, fecha_creacion}` → 201 |
| GET | `/materias` | – | Lista ordenada por nombre |
| GET/PUT/DELETE | `/materias/<id>` | PUT: `nombre`?, `docente`? | Materia / `null`. **DELETE borra también sus tareas y evaluaciones** |
| POST | `/tareas` | `materia_id` (propia; si no → 404), `titulo` (2–150), `descripcion`? (máx. 2000), `fecha_entrega` (se permiten fechas pasadas), `prioridad`? (`baja`/`media`/`alta`, por defecto `media`), `estado`? (`pendiente`/`completada`) | Tarea `{id, materia_id, titulo, descripcion, fecha_entrega, prioridad, estado, fecha_creacion}` → 201 |
| GET | `/tareas` | `?materia_id&estado&prioridad&fecha_desde&fecha_hasta` | Lista ordenada por `fecha_entrega` |
| GET | `/tareas/pendientes` | Los mismos filtros, sin `estado` | Lista |
| GET/PUT/DELETE | `/tareas/<id>` | PUT: cualquier campo editable | Tarea / `null` |
| PATCH | `/tareas/<id>/estado` | `{"estado": "pendiente" \| "completada"}` | Tarea |
| POST | `/evaluaciones` | `materia_id`, `nombre` (2–150), `fecha`, `descripcion`? | Evaluación `{id, materia_id, nombre, fecha, descripcion, fecha_creacion}` → 201 |
| GET | `/evaluaciones` | `?materia_id&fecha_desde&fecha_hasta` | Lista |
| GET/PUT/DELETE | `/evaluaciones/<id>` | | Evaluación / `null` |
| GET | `/proximos` | `?dias` (1–90, por defecto 7), `?fecha` | `{fecha_desde, fecha_hasta, tareas: [...pendientes], evaluaciones: [...]}` |

### Hábitos (`/api/habitos`, todo privado)
| Método | Ruta | Cuerpo / parámetros | `datos` |
|---|---|---|---|
| POST | `` | `nombre` (2–100, único → 409), `descripcion`? (máx. 255) | Hábito `{id, nombre, descripcion, activo, fecha_creacion}` → 201 |
| GET | `` | `?activo=true\|false` | Lista |
| GET/PUT/DELETE | `/<id>` | PUT: `nombre`?, `descripcion`?, `activo`? (bool) | Hábito / `null` |
| POST | `/<id>/cumplimientos` | `{"fecha"?: "YYYY-MM-DD"}` (por defecto hoy; **se permiten días pasados**, futuros → 422) | `{habito_id, fecha}` → 201; ya marcado → 409 |
| DELETE | `/<id>/cumplimientos/<fecha>` | – | `null`; si no estaba marcado → 404 |
| GET | `/<id>/historial` | `?desde&hasta` (por defecto, los últimos 30 días) | `{habito_id, desde, hasta, fechas: [desc]}` |
| GET | `/<id>/estadisticas` | `?fecha` | `{habito_id, total_cumplimientos, dias_ventana, porcentaje_cumplimiento, racha_actual, mejor_racha, ultimo_cumplimiento}` |

### Salud (`/api/salud`, todo privado)
| Método | Ruta | Cuerpo / parámetros | `datos` |
|---|---|---|---|
| POST | `/hidratacion` | `cantidad_ml` (entero 0–10000), `fecha`? (no futura) | `{id, fecha, cantidad_ml, fecha_creacion}` → 201; ese día ya tiene registro → 409 |
| GET | `/hidratacion` | `?desde&hasta` (por defecto 30 días) | Lista (más reciente primero) |
| GET/PUT/DELETE | `/hidratacion/<fecha>` | PUT: `cantidad_ml` (**reemplaza** el total) | Registro / 404 si no hay |
| POST | `/sueno` | `horas` (número >0 y ≤24, máx. 2 decimales), `fecha`? | `{id, fecha, horas (float), fecha_creacion}` → 201; duplicado → 409 |
| GET | `/sueno` | `?desde&hasta` | Lista |
| GET/PUT/DELETE | `/sueno/<fecha>` | PUT: `horas` | Registro / 404 |
| POST | `/actividades` | `tipo` (2–50), `duracion_minutos` (1–1440), `fecha`?, `descripcion`? (máx. 500) | `{id, fecha, tipo, duracion_minutos, descripcion, fecha_creacion}` → 201 |
| GET | `/actividades` | `?desde&hasta&tipo` | Lista |
| GET/PUT/DELETE | `/actividades/<id>` | PUT: cualquier campo | Actividad / `null` |
| GET | `/estadisticas` | `?dias` (1–90, por defecto 7), `?fecha` | `{dias, desde, hasta, hidratacion{promedio_ml, dias_con_registro, dias_meta_cumplida, meta_ml}, sueno{promedio_horas, dias_con_registro}, actividad{total_actividades, minutos_totales, dias_activos}, recomendaciones[], aviso}` |

### Mi Día
| Método | Ruta | Parámetros | `datos` |
|---|---|---|---|
| GET | `/api/mi-dia` | `?fecha` | `{fecha, tareas{total_pendientes, vencidas[], para_hoy[], proximas[]}, evaluaciones{proximas[]}, habitos{total, completados, porcentaje, lista[{id, nombre, cumplido}]}, salud{hidratacion{cantidad_ml\|null, meta_ml, porcentaje}, sueno{horas\|null}, actividades[], minutos_actividad}}` |

## 3. Pantalla / acción → endpoint → estado

| Pantalla / acción | Endpoint | Estado |
|---|---|---|
| Splash: ¿hay sesión válida? | Token guardado + `GET /api/usuarios/me` | Conectado |
| Registro | `POST /api/auth/registro` y luego `POST /api/auth/login` | Conectado |
| Login | `POST /api/auth/login` | Conectado |
| Cerrar sesión | `POST /api/auth/logout` + borrar el token | Conectado |
| Perfil: ver | `GET /api/usuarios/me` | Conectado |
| Perfil: editar nombre/correo | `PUT /api/usuarios/me` | Conectado |
| Perfil: cambiar contraseña | `PUT /api/usuarios/me/contrasena` | Conectado |
| Perfil: tamaño del vaso (ml por vaso) | – | **Solo local** (preferencia del teléfono) |
| Perfil: cambiar la meta de agua | – | **Falta en el backend** (la meta es global, `META_HIDRATACION_ML`); la app solo la muestra |
| Mi Día: resumen | `GET /api/mi-dia?fecha=` | Conectado |
| Mi Día: chip de racha 🔥 | `GET /api/habitos/<id>/estadisticas` por cada hábito activo (mayor `racha_actual`) | Conectado (varias peticiones; ver pendientes) |
| Mi Día: +1 vaso | `POST` o `PUT /api/salud/hidratacion/<fecha>` | Conectado |
| Mi Día: marcar hábito | `POST` / `DELETE .../cumplimientos` | Conectado |
| SmartStudy: lista de tareas, pendientes y completadas | `GET /api/smartstudy/tareas` | Conectado |
| SmartStudy: completar tarea | `PATCH /tareas/<id>/estado` | Conectado |
| SmartStudy: crear, editar y eliminar tarea | `POST /tareas`, `PUT` y `DELETE /tareas/<id>` | Conectado |
| SmartStudy: nombre de la materia en cada tarea | `GET /materias` (se cruza por `materia_id` en la app) | Conectado |
| Materias: CRUD | `/materias` | Conectado |
| Materias: color | – | **Solo local** (el backend no tiene un campo `color`) |
| Evaluaciones: listar, crear y eliminar | `/evaluaciones` | Conectado |
| Hábitos: CRUD | `/api/habitos` | Conectado |
| Hábitos: fila de la semana | `GET /<id>/historial?desde=lunes&hasta=domingo` por hábito | Conectado (varias peticiones) |
| Hábitos: marcar o desmarcar un día (hoy o pasados) | `POST` / `DELETE .../cumplimientos` | Conectado |
| Hábitos: estadísticas | `GET /<id>/estadisticas` | Conectado |
| Hábitos: icono por hábito | – | No existe: se usa un icono genérico |
| Salud, Hidratación: vaso, +1 y −1 | `GET`, `POST` y `PUT /hidratacion/<fecha>` | Conectado |
| Salud, Descanso: registrar horas e historial | `POST` / `PUT /sueno`, `GET /sueno` | Conectado |
| Salud, Descanso: hora de dormir y de despertar | – | **Falta en el backend** (solo hay `horas`): no se muestra |
| Salud, Descanso: meta de sueño (8 h) | – | **Solo local** (constante de la app; el backend no tiene meta de sueño) |
| Salud, Actividad: resumen 2×2 | `GET /api/salud/estadisticas?dias=7` | Conectado |
| Salud, Entrenamiento: registrar, historial y eliminar | `/api/salud/actividades` | Conectado |
| Salud: recomendaciones del backend | `recomendaciones` en `/estadisticas` | **No se muestran** (CLAUDE.md: nada de recomendaciones de salud) |

## 4. Cómo se verificó (18-nov-2026)

- **Contra el backend real:** `dart run tool/smoke_test.dart` usa los mismos servicios y modelos de la app. Dio **38 de 38 OK** en dos ejecuciones (Fases 4 y 8), cubriendo autenticación, perfil, SmartStudy, hábitos, salud, Mi Día y la revocación del token.
- **En el emulador Android (API 37):** se instaló el APK de debug con el backend local encendido. Se registró una cuenta desde la app, se abrió Mi Día con datos reales, se sumó un vaso (que luego apareció en Salud, leído del servidor), se creó un hábito y se marcó hoy (con la racha de 1 día calculada por el backend). Las capturas están en `docs/capturas/`.
- **Con servidor falso (`MockClient`):** 75 pruebas automáticas (`flutter test`) de modelos, servicios, providers y pantallas, con respuestas que tienen la forma exacta de las del backend.
- **Sin probar en la app real:** los formularios de materia, tarea y evaluación, la edición de perfil, el cambio de contraseña y la pestaña Descanso no se recorrieron en el emulador. Sí están cubiertos por la prueba de humo (servicios) o por pruebas de widget.

## 5. Decisiones al integrar

- **Progreso del día en Mi Día** = promedio del % de hábitos (si hay hábitos activos) y del % de agua (máximo 100 %). Las tareas no entran: el backend solo informa las **pendientes**, no cuántas se completaron hoy.
- **«+1 vaso»:** el backend guarda **un total por día**. La app lee el total (`GET /hidratacion/<fecha>`); si no existe hace `POST`, y si existe hace `PUT` con el total nuevo.
- **Actividad y Entrenamiento** comparten el mismo registro (`/api/salud/actividades`). Actividad muestra el resumen de 7 días y Entrenamiento el historial con alta, edición y borrado.
- **Fecha de «hoy»:** la app siempre envía la fecha del teléfono (`?fecha=` o `fecha` en el cuerpo), como recomienda la guía para Flutter del backend.
