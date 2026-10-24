# EcoLogiSmart

EcoLogiSmart es un prototipo de plataforma digital para apoyar a pequeñas y medianas empresas de Cartagena en la gestión de recursos, inventarios, materiales aprovechables y entregas. Integra herramientas de Ingeniería Industrial, tecnología y sostenibilidad para ayudar a reducir costos, desperdicios y recorridos innecesarios.

## Propósito

La plataforma busca facilitar decisiones operativas y promover la economía circular y la logística compartida, sin solicitar información financiera privada como ingresos, cuentas bancarias o estados financieros.

## Módulos del prototipo

- **Acceso e inicio:** inicio de sesión demostrativo y resumen de operación con oportunidades cercanas.
- **Diagnóstico operativo:** oportunidades sobre inventario, materiales recuperables y entregas agrupables.
- **Recursos e inventario:** existencias y registro de recursos y consumos operativos.
- **Economía circular:** materiales aprovechables disponibles para conexión entre negocios.
- **Logística compartida:** rutas y pedidos que podrían agruparse.
- **Indicadores:** seguimiento de metas, eficiencia e impacto estimado.
- **Perfil de empresa:** información básica del negocio, sector y ubicación.

## Aplicación

La app está desarrollada con Flutter y Dart en `eco_logic_smart/`. Las pantallas forman un prototipo navegable y utilizan datos demostrativos. Los formularios no persisten información y no existe todavía una conexión con servicios externos o base de datos.

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
├── main.dart
├── shared/
│   └── components.dart
└── features/
    ├── circular/
    ├── company/
    ├── dashboard/
    ├── indicators/
    ├── logistics/
    └── resources/
```

## Alcance

El prototipo cubre los flujos visuales iniciales para el emprendimiento de Ingeniería Industrial con enfoque STEAM, orientado a hoteles, restaurantes, comercios y negocios de servicios. La validación con usuarios, la persistencia de datos y las integraciones reales corresponden a fases posteriores.
