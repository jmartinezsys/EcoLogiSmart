# Informe general de cambios del sistema

Desde su creación, EcoLogiSmart pasó de una estructura inicial en Flutter a una aplicación web publicada y un prototipo móvil con registro de empresas, inventario, intercambio de materiales y rutas compartidas. Las fechas y horas corresponden a Colombia (UTC-05:00), y los cambios aparecen en orden cronológico inverso.

## 28 de octubre de 2026

### 23:19:38 — `3aa9164` — Cierre de sesión y recuperación del inventario local

Se facilitaron el cierre de sesión y la revisión de la cuenta desde el tablero y el perfil empresarial. También se añadió una opción para recuperar productos que se habían guardado localmente antes de conectar la cuenta con el inventario en la nube.

### 23:05:32 — `5cbc811` — Compatibilidad de publicaciones con la migración de Supabase

Se ajustó la aplicación para mostrar las publicaciones aunque la base de datos todavía no tenga habilitadas las funciones de intercambio. La pantalla informa cuándo hace falta actualizar la configuración del servicio.

### 22:34:06 — `a9abd1f` — Intercambios de materiales y rutas compartidas

Se añadieron categorías para recursos, selección de ciudades colombianas, publicaciones para aprovechamiento o intercambio, propuestas entre empresas y solicitudes para unirse a rutas. Se incorporó una segunda migración para guardar intercambios, solicitudes de ruta y sus estados.

## 26 de octubre de 2026

### 00:07:34 — `91997f5` — Ajustes de carga y formularios empresariales

Se corrigieron detalles de carga en el tablero y los formularios, se ajustó la navegación y se ampliaron las pruebas de la aplicación.

## 25 de octubre de 2026

### 22:45:41 — `e9f9ecb` — Actualización de documentación e inicio web

Se revisaron las guías del proyecto y se mejoró la pantalla de inicio web para mostrar el estado de carga y ofrecer reintento si la aplicación no inicia.

### 22:36:42 — `45e561e` — Mejora visual de la aplicación móvil

La interfaz recibió un tema visual más uniforme, con ajustes en colores, tipografía, campos y botones. El tablero presenta el perfil de la empresa con su identidad gráfica y adapta el contenido a distintos tamaños. El inventario calcula sus categorías a partir de los productos registrados y reemplaza consumos de agua y energía de ejemplo por una indicación para mantener las existencias actualizadas.

### 22:18:53 — `52847e5` — Integración de Supabase y persistencia para los módulos empresariales

La aplicación incorporó autenticación con correo y contraseña, recuperación de contraseña y restauración de sesión. Los perfiles de empresa, el inventario, las publicaciones de materiales y las solicitudes logísticas pueden conectarse a Supabase; cuando no hay configuración de nube, el prototipo conserva un modo de demostración local.

También se incorporaron repositorios para cuentas y operaciones, modelos de datos, pantallas de diagnóstico e indicadores, y flujos de economía circular y logística. Una migración SQL define perfiles, inventario, publicaciones, solicitudes, políticas de seguridad por fila (RLS) y almacenamiento de imágenes. La integración compartida requiere un proyecto Supabase configurado y sus migraciones aplicadas.

### 17:08:26 — `149140f` — Publicación de la aplicación web

Se configuró la publicación automática de la versión web en GitHub Pages y se mejoró la presentación del tablero. La aplicación quedó disponible en [jmartinezsys.github.io/EcoLogiSmart](https://jmartinezsys.github.io/EcoLogiSmart/).

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
