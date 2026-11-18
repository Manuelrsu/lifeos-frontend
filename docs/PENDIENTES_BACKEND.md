# Pendientes del backend

Funciones que la app podría aprovechar, pero que el backend actual **no tiene**. El backend es de solo lectura para el frontend, así que solo quedan documentadas. Ninguna bloquea una pantalla principal: hay una alternativa en la app, indicada en cada caso.

## 1. Color de la materia
- **Hoy:** la app guarda el color en el teléfono (`shared_preferences`, con la clave `color_materia_<id>`). No viaja a MySQL ni aparece en otro dispositivo.
- **Propuesta:** columna `color VARCHAR(7)` en `materias`, opcional.
  - `POST /api/smartstudy/materias` y `PUT /materias/<id>` → cuerpo `{"nombre": "Cálculo", "docente": null, "color": "#7DD3C0"}` (`color` opcional, con formato `#RRGGBB`; si es inválido → 422).
  - Respuesta: la materia con `"color": "#7DD3C0"` o `null`.

## 2. Meta de hidratación por usuario
- **Hoy:** la meta es global (`META_HIDRATACION_ML` en el `.env`, 2000 ml). La app la lee de `meta_ml` y no puede cambiarla.
- **Propuesta:** `PUT /api/usuarios/me/meta-hidratacion` con el cuerpo `{"meta_ml": 2500}` (entero entre 500 y 10000) → 200 `{"meta_ml": 2500}`. Además, `GET /api/mi-dia` y `/api/salud/estadisticas` usarían la meta del usuario.

## 3. Racha en Mi Día
- **Hoy:** para el chip 🔥, la app pide `GET /api/habitos/<id>/estadisticas` por cada hábito activo, es decir, N peticiones.
- **Propuesta:** agregar en `GET /api/mi-dia` → `datos.habitos.mejor_racha_actual` (entero), calculado con la función `calcular_rachas` que ya existe.

## 4. Semana de cada hábito en una sola petición
- **Hoy:** la pantalla de hábitos pide `GET /api/habitos/<id>/historial?desde=<lunes>&hasta=<domingo>` por cada hábito.
- **Propuesta:** `GET /api/habitos/semana?desde=YYYY-MM-DD&hasta=YYYY-MM-DD` → `[{"habito_id": 1, "fechas": ["2026-11-16", ...]}, ...]`.

## 5. Hora de dormir y de despertar
- **Hoy:** el sueño solo guarda `horas`. La app no pide ni muestra horas de inicio y fin.
- **Propuesta:** columnas opcionales `hora_dormir` y `hora_despertar` (`TIME`), con el cuerpo `{"horas": 7.5, "hora_dormir": "23:30", "hora_despertar": "07:00"}`.

## 6. Sumar agua de forma atómica
- **Hoy:** «+1 vaso» lee el total del día y luego hace `POST` (si no hay registro) o `PUT` con el total nuevo. Si dos teléfonos lo tocan a la vez, uno de los dos cambios puede perderse.
- **Propuesta** (ya está en las mejoras futuras del backend): `POST /api/salud/hidratacion/<fecha>/sumar` con el cuerpo `{"cantidad_ml": 250}` → el registro actualizado (lo crea si no existía).
