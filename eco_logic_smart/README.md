# EcoLogiSmart Flutter App

Aplicación Flutter EcoLogiSmart. Consulta la [documentación del proyecto](../documentacion_proyecto.md) para conocer objetivo, alcance y plan de trabajo. El [README del repositorio](../README.md) documenta módulos, backend y configuración.

## Inicio rápido

```bash
flutter pub get
flutter run
```

Sin `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`, la app inicia en modo demostración y guarda operaciones en el dispositivo. Para usar la nube, configura ambos valores con `--dart-define` y ejecuta en el SQL Editor la migración ubicada en `supabase/migrations/`.

En Supabase Auth, agrega `co.ecologismart.app://login-callback` a **URL Configuration → Redirect URLs** para recuperación de contraseña móvil. En web, agrega también el origen donde se publique la app.

## Flujo de la aplicación

El flujo incluye autenticación, registro de empresa, recuperación de contraseña, carga inicial con sesión restaurada y perfil empresarial. El tablero ofrece acceso al diagnóstico. Inventario, publicaciones, imágenes y logística usan repositorios con implementación local de demostración y persistencia en Supabase cuando está configurado.

La clave `service_role` nunca va dentro de la aplicación móvil. Aplica las políticas RLS de la migración antes de compartir el Project URL y la clave pública con una compilación.
