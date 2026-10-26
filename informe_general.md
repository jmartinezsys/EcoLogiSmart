# Informe general de cambios del sistema

Desde su creación, EcoLogiSmart pasó de una estructura inicial en Flutter a un prototipo con registro de empresas, módulos operativos e integración configurable con Supabase. Las fechas y horas corresponden a Colombia (UTC-05:00), y los cambios aparecen en orden cronológico inverso.

## 25 de octubre de 2026

### 22:36:42 — `45e561e` — Mejora visual de la aplicación móvil

La interfaz recibió un tema visual más uniforme, con ajustes en colores, tipografía, campos y botones. El tablero ahora presenta el perfil de la empresa en una tarjeta con su identidad gráfica y adapta el contenido a distintos tamaños. El inventario calcula sus categorías a partir de los productos registrados y reemplaza los consumos de agua y energía de ejemplo por una indicación para mantener las existencias actualizadas.

### 22:18:53 — `52847e5` — Integración de Supabase y persistencia para los módulos empresariales

La aplicación incorporó autenticación con correo y contraseña, recuperación de contraseña y restauración de sesión. Los perfiles de empresa, el inventario, las publicaciones de materiales y las solicitudes logísticas pueden conectarse a Supabase; cuando no hay configuración de nube, el prototipo conserva un modo de demostración local.

También se incorporaron repositorios para cuentas y operaciones, modelos de datos, pantallas de diagnóstico e indicadores, y flujos de economía circular y logística. Una migración SQL define perfiles, inventario, publicaciones, solicitudes, políticas de seguridad por fila (RLS) y almacenamiento de imágenes. La integración requiere configurar un proyecto Supabase y aplicar la migración; el repositorio no incluye un servicio Supabase desplegado.

## 24 de octubre de 2026

### 18:28:42 — `a06ec47` — Personalización de cuentas y carga inicial

El prototipo incorporó el registro de empresas, perfiles personalizados y almacenamiento local de cuentas. La pantalla de inicio de sesión y la carga de la aplicación se ajustaron para recuperar la cuenta y mostrar la identidad visual de EcoLogiSmart.

### 18:05:02 — `62beca4` — Incorporación del informe de cambios

Se añadió el primer informe del historial de cambios del sistema.

### 15:14:10 — `fdeef64` — Corrección del arranque web y la navegación

La aplicación se reorganizó en módulos de autenticación, empresa, diagnóstico, indicadores, logística, economía circular y recursos. Se añadieron navegación y componentes compartidos, se ajustó el tablero y se actualizaron las guías del proyecto y las pruebas de widgets.

### 11:12:23 — `f6ae527` — Creación del tablero de gestión sostenible

Se creó el primer tablero de gestión sostenible y se organizó el punto de entrada de la aplicación Flutter. También se actualizaron las guías del repositorio y de la aplicación.

### 07:07:19 — `d55df2b` — Estructura inicial del proyecto Flutter

Se creó la estructura inicial de Flutter, con configuración de análisis, dependencias, pruebas y archivos de plataforma para Android, iOS y web.

### 06:36:57 — `7cd402b` — Inicio del repositorio

Se inició el repositorio con un README básico.

## Cambios locales sin commit

Los cambios locales actuales ajustan el inicio de la versión web. La pantalla de carga muestra un mensaje y ofrece reintentar si la aplicación falla o tarda más de 45 segundos en abrir. Estos cambios todavía no aparecen en el historial de commits.
