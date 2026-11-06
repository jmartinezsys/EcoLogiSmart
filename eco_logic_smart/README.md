# EcoLogiSmart Flutter App

Aplicación Flutter de EcoLogiSmart. La [documentación del proyecto](../documentacion_proyecto.md) reúne el objetivo, el alcance y el plan de trabajo. El [README del repositorio](../README.md) describe los módulos y la configuración del backend.

## Inicio rápido

```bash
flutter pub get
flutter run
```

En VS Code abre la carpeta raíz del repositorio y selecciona una configuración `EcoLogiSmart` en **Run and Debug**. La configuración **Edge** intenta depuración integrada; si Edge queda esperando el depurador, usa **Web Server** y abre `http://127.0.0.1:5319` manualmente. Para Android conecta un teléfono con depuración USB o inicia un emulador antes de elegir la configuración **Android**.

La configuración de ejecución de VS Code incluye el Project URL y la publishable key del proyecto EcoLogiSmart. Ejecuta **EcoLogiSmart (Web Server, abrir Edge manualmente)** o **EcoLogiSmart (Android)** para usarlos. La publishable key está diseñada para clientes móviles/web; nunca incluyas una clave `service_role` en la app.

Antes de usar las cuentas empresariales y la sincronización, ejecuta en orden los archivos `.sql` de `supabase/migrations/`: `20261025000000_ecologismart_core.sql`, `20261029000000_marketplace_and_routes.sql`, `20261104000000_company_messaging_and_route_details.sql`, `20261105000000_end_to_end_company_chat.sql` y `20261106000000_route_eta_and_delivery_stops.sql`. Las migraciones agregan direcciones detalladas, medio de transporte, propuestas directas, chat cifrado y datos para ETAs/paradas; no reemplazan las migraciones anteriores.

En Circular, el chat se abre desde una publicación. El contenido se cifra en el cliente con claves que se guardan en el dispositivo y el servidor almacena ciphertext. La primera versión admite mensajes de texto; los archivos, notas de voz, sincronización de claves entre dispositivos y Double Ratchet no están incluidos. Si se pierde el dispositivo o sus claves, los mensajes anteriores no se podrán descifrar. En Rutas se puede calcular y elegir entre alternativas terrestres mediante OpenStreetMap/Nominatim y OSRM; se muestra distancia y ETA aproximada sin tráfico en vivo. La estimación individual de empresas que se unen usa el origen de la ruta hasta su dirección de entrega y no optimiza todas las paradas en conjunto. El proveedor público puede limitar disponibilidad; muéstrase atribución a OpenStreetMap.

La recuperación de contraseña móvil requiere registrar `co.ecologismart.app://login-callback` en **URL Configuration → Redirect URLs** de Supabase Auth. Para la versión web se registra `https://jmartinezsys.github.io/EcoLogiSmart/` y los orígenes locales `http://127.0.0.1:5319/**` y `http://localhost:5319/**`. El redirect web conserva la subruta `/EcoLogiSmart/` que necesita GitHub Pages.

## Publicación web

El workflow `.github/workflows/deploy-ecologismart-web.yml` compila con la configuración Supabase y publica en GitHub Pages al actualizar `main`. La versión publicada se consulta en [jmartinezsys.github.io/EcoLogiSmart](https://jmartinezsys.github.io/EcoLogiSmart/).

## Flujo de la aplicación

El flujo incluye autenticación, registro de empresa, recuperación de contraseña, carga inicial con sesión restaurada y perfil empresarial. El tablero ofrece acceso al diagnóstico. Inventario, publicaciones, imágenes y logística usan repositorios con implementación local de demostración y persistencia en Supabase cuando está configurado. En web, la pantalla de carga permite reintentar si la aplicación falla o tarda más de 45 segundos en abrir.

La clave `service_role` no se incorpora en la aplicación móvil. Las políticas RLS de la migración deben estar aplicadas antes de distribuir una compilación con el Project URL y la clave pública.
