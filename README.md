# EcoLogiSmart

EcoLogiSmart es un prototipo de plataforma digital para pequeñas y medianas empresas de Cartagena. Reúne herramientas de Ingeniería Industrial, tecnología y sostenibilidad para organizar recursos, inventarios, materiales aprovechables y entregas, y reducir desperdicios y recorridos innecesarios.

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

La app está desarrollada con Flutter y Dart en `eco_logic_smart/`. Incluye integración configurable con Supabase (PostgreSQL, Auth y Storage), políticas de seguridad RLS y un modo local de demostración con persistencia. La nube se activa al ejecutar con la URL y la clave pública del proyecto. Sin esos valores, los datos permanecen en el dispositivo y no se sincronizan entre dispositivos.

Las fotografías de publicaciones se cargan al bucket `material-images` cuando Supabase está configurado. El modo local conserva los registros en el dispositivo para permitir pruebas sin backend.

## Requisitos e inicio

Se requiere Flutter SDK compatible con Dart `^3.10.8`.

```bash
cd eco_logic_smart
flutter pub get
flutter run
```

### Configuración de Supabase

1. Se crea un proyecto Supabase.
2. En el SQL Editor del proyecto se ejecuta `eco_logic_smart/supabase/migrations/20261025000000_ecologismart_core.sql`.
3. La aplicación requiere el Project URL y la clave pública `publishable`. La clave `service_role` no se incluye ni se comparte con la app.
4. La aplicación se inicia con estos valores:

```bash
flutter run --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICA
```

La migración crea perfiles empresariales vinculados a Supabase Auth, tablas de inventario, publicaciones y solicitudes logísticas, políticas RLS y el bucket de imágenes. El proveedor de correo y contraseña y la confirmación de correo se configuran en Supabase Auth. Sin la URL y la clave pública, la aplicación mantiene el modo local de demostración.

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

El proyecto está preparado para operar con varias empresas en Supabase, pero la sincronización requiere un proyecto real y la aplicación de la migración. La clave secreta del backend no se incluye en la aplicación. El modo local permite presentar y probar los flujos en un dispositivo, pero no sustituye un entorno de producción.
