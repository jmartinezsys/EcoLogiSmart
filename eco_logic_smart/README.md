# EcoLogiSmart Flutter App

Aplicación Flutter de EcoLogiSmart. La [documentación del proyecto](../documentacion_proyecto.md) reúne el objetivo, el alcance y el plan de trabajo. El [README del repositorio](../README.md) describe los módulos y la configuración del backend.

## Inicio rápido

```bash
flutter pub get
flutter run
```

En VS Code abre la carpeta raíz del repositorio y selecciona una configuración `EcoLogiSmart` en **Run and Debug**. La configuración **Edge** intenta depuración integrada; si Edge queda esperando el depurador, usa **Web Server** y abre `http://127.0.0.1:5319` manualmente. Para Android conecta un teléfono con depuración USB o inicia un emulador antes de elegir la configuración **Android**.

La configuración de ejecución de VS Code incluye el Project URL y la publishable key del proyecto EcoLogiSmart. Ejecuta **EcoLogiSmart (Web Server, abrir Edge manualmente)** o **EcoLogiSmart (Android)** para usarlos. La publishable key está diseñada para clientes móviles/web; nunca incluyas una clave `service_role` en la app.

Antes de usar las cuentas empresariales y la sincronización, ejecuta en orden los archivos `.sql` de `supabase/migrations/` en el SQL Editor del proyecto: `20261025000000_ecologismart_core.sql` y `20261029000000_marketplace_and_routes.sql`. El segundo habilita intercambios y solicitudes para unirse a rutas. También configura los Redirect URLs de Auth según la sección siguiente. Si Flutter se ejecuta desde una terminal en vez de VS Code, se definen `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY` con `--dart-define`; sin esos valores, la aplicación usa almacenamiento local de demostración.

La recuperación de contraseña móvil requiere registrar `co.ecologismart.app://login-callback` en **URL Configuration → Redirect URLs** de Supabase Auth. Para la versión web se registra `https://jmartinezsys.github.io/EcoLogiSmart/` y los orígenes locales `http://127.0.0.1:5319/**` y `http://localhost:5319/**`. El redirect web conserva la subruta `/EcoLogiSmart/` que necesita GitHub Pages.

## Publicación web

El workflow `.github/workflows/deploy-ecologismart-web.yml` compila con la configuración Supabase y publica en GitHub Pages al actualizar `main`. La versión publicada se consulta en [jmartinezsys.github.io/EcoLogiSmart](https://jmartinezsys.github.io/EcoLogiSmart/).

## Flujo de la aplicación

El flujo incluye autenticación, registro de empresa, recuperación de contraseña, carga inicial con sesión restaurada y perfil empresarial. El tablero ofrece acceso al diagnóstico. Inventario, publicaciones, imágenes y logística usan repositorios con implementación local de demostración y persistencia en Supabase cuando está configurado. En web, la pantalla de carga permite reintentar si la aplicación falla o tarda más de 45 segundos en abrir.

La clave `service_role` no se incorpora en la aplicación móvil. Las políticas RLS de la migración deben estar aplicadas antes de distribuir una compilación con el Project URL y la clave pública.
