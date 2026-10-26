# EcoLogiSmart

EcoLogiSmart es un prototipo de plataforma digital para apoyar a pequeñas y medianas empresas de Cartagena en la gestión de recursos, inventarios, materiales aprovechables y entregas. Integra herramientas de Ingeniería Industrial, tecnología y sostenibilidad para ayudar a reducir costos, desperdicios y recorridos innecesarios.

La descripción del proyecto, su alcance, el plan de trabajo del grupo y los indicadores propuestos están consolidados en la [documentación del proyecto](documentacion_proyecto.md). El [informe de cambios](informe_general.md) resume el historial de commits.

## Propósito

La plataforma busca facilitar decisiones operativas y promover la economía circular y la logística compartida, sin solicitar información financiera privada como ingresos, cuentas bancarias o estados financieros.

## Módulos

- Acceso y perfil de empresa.
- Inventario por empresa y alertas de existencias mínimas.
- Publicaciones de materiales aprovechables con fotografía.
- Solicitudes logísticas y detección básica de destinos coincidentes.
- Diagnóstico e indicadores calculados a partir de los registros disponibles.

## Aplicación

La app está desarrollada con Flutter y Dart en `eco_logic_smart/`. Incluye integración configurable con Supabase (PostgreSQL, Auth y Storage), permisos Row Level Security y un modo de demostración persistente local. La nube se activa al ejecutar con el URL y la clave pública del proyecto. Sin esos valores, la app anuncia el modo demostración y los datos no se sincronizan entre dispositivos.

Las fotografías de publicaciones se cargan al bucket `material-images` cuando Supabase está configurado. El modo local conserva los registros en el dispositivo para permitir pruebas sin backend.

## Requisitos e inicio

Se requiere Flutter SDK compatible con Dart `^3.10.8`.

```bash
cd eco_logic_smart
flutter pub get
flutter run
```

### Activar Supabase

1. Crea un proyecto Supabase.
2. En el SQL Editor del proyecto, ejecuta `eco_logic_smart/supabase/migrations/20261025000000_ecologismart_core.sql`.
3. Copia el Project URL y la clave `publishable` del proyecto. No incluyas ni compartas la clave `service_role`.
4. Inicia la app pasando la configuración:

```bash
flutter run --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICA
```

La migración crea perfiles empresariales desde Auth, tablas de inventario, publicaciones y rutas, políticas RLS y el bucket de fotos. En Supabase Auth habilita correo/contraseña y define la confirmación de email según el flujo que quieras usar. Sin URL y clave, se mantiene la demostración local.

Para revisar problemas estáticos:

```bash
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed .
```

## Estructura principal

```text
eco_logic_smart/lib/
├── app.dart
├── app_shell.dart
├── main.dart
├── models/
│   ├── company_account.dart
│   └── operational_records.dart
├── services/
│   ├── account_repository.dart
│   ├── backend_config.dart
│   ├── local_account_store.dart
│   └── workspace_repository.dart
├── shared/
│   └── components.dart
└── features/
    ├── auth/
    ├── company/
    ├── dashboard/
    ├── circular/
    ├── indicators/
    ├── logistics/
    └── resources/
```

## Alcance

El proyecto está preparado para operar con varias empresas en Supabase, pero requiere un proyecto real y aplicar la migración para activar la nube. La clave secreta del backend no se incluye en la aplicación. El modo local permite presentar y probar los flujos en un dispositivo, pero no sustituye un entorno de producción.
