# EcoLogiSmart

EcoLogiSmart es un prototipo de plataforma digital para apoyar a pequeñas y medianas empresas de Cartagena en la gestión de recursos, inventarios, materiales aprovechables y entregas. Integra herramientas de Ingeniería Industrial, tecnología y sostenibilidad para ayudar a reducir costos, desperdicios y recorridos innecesarios.

## Propósito

La plataforma busca facilitar decisiones operativas y promover la economía circular y la logística compartida, sin solicitar información financiera privada como ingresos, cuentas bancarias o estados financieros.

## Módulos del prototipo

- **Acceso e inicio:** creación de cuenta local, validación de inicio de sesión y panel de empresa personalizado.
- **Diagnóstico operativo:** oportunidades sobre inventario, materiales recuperables y entregas agrupables.
- **Recursos e inventario:** existencias y registro de recursos y consumos operativos.
- **Economía circular:** materiales aprovechables disponibles para conexión entre negocios.
- **Logística compartida:** rutas y pedidos que podrían agruparse.
- **Indicadores:** seguimiento de metas, eficiencia e impacto estimado.
- **Perfil de empresa:** información básica del negocio, sector y ubicación.

## Aplicación

La app está desarrollada con Flutter y Dart en `eco_logic_smart/`. Las cuentas y los perfiles de empresa se guardan localmente en el dispositivo o navegador; las contraseñas se guardan como hashes con sal. No hay sincronización entre dispositivos ni servicio de autenticación en la nube. Los módulos de inventario, publicaciones y rutas todavía usan datos de demostración.

## Requisitos e inicio

Se requiere Flutter SDK compatible con Dart `^3.10.8`.

```bash
cd eco_logic_smart
flutter pub get
flutter run
```

Para revisar problemas estáticos:

```bash
flutter analyze
```

## Estructura principal

```text
eco_logic_smart/lib/
├── app.dart
├── app_shell.dart
├── main.dart
├── models/
│   └── company_account.dart
├── services/
│   └── local_account_store.dart
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

El prototipo cubre los flujos visuales iniciales para el emprendimiento de Ingeniería Industrial con enfoque STEAM, orientado a hoteles, restaurantes, comercios y negocios de servicios. La sincronización multiempresa, la autenticación en la nube y la persistencia de la operación corresponden a fases posteriores.
