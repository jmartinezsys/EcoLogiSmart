# EcoLogiSmart Flutter App

Aplicación Flutter de EcoLogiSmart. La [documentación del proyecto](../documentacion_proyecto.md) reúne el objetivo, el alcance y el plan de trabajo. El [README del repositorio](../README.md) describe los módulos y la configuración del backend.

## Inicio rápido

```bash
flutter pub get
flutter run
```

Sin `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`, la aplicación inicia en modo de demostración y guarda las operaciones en el dispositivo. La sincronización en la nube requiere ambos valores mediante `--dart-define` y la ejecución de la migración ubicada en `supabase/migrations/` desde el SQL Editor del proyecto.

La recuperación de contraseña móvil requiere registrar `co.ecologismart.app://login-callback` en **URL Configuration → Redirect URLs** de Supabase Auth. Para la versión web también se registra el origen de publicación.

## Flujo de la aplicación

El flujo incluye autenticación, registro de empresa, recuperación de contraseña, carga inicial con sesión restaurada y perfil empresarial. El tablero ofrece acceso al diagnóstico. Inventario, publicaciones, imágenes y logística usan repositorios con implementación local de demostración y persistencia en Supabase cuando está configurado. En web, la pantalla de carga permite reintentar si la aplicación falla o tarda más de 45 segundos en abrir.

La clave `service_role` no se incorpora en la aplicación móvil. Las políticas RLS de la migración deben estar aplicadas antes de distribuir una compilación con el Project URL y la clave pública.
