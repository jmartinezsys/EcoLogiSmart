# EcoLogiSmart

EcoLogiSmart es un prototipo de plataforma digital para apoyar a pequeñas y medianas empresas de Cartagena en la gestión de recursos, inventarios, materiales aprovechables y entregas. El proyecto integra herramientas de Ingeniería Industrial, tecnología y sostenibilidad para ayudar a reducir costos operativos, desperdicios y recorridos innecesarios.

## Objetivo

Diseñar una plataforma que facilite decisiones operativas y promueva la economía circular y la logística compartida entre negocios, sin solicitar información financiera privada como ingresos, cuentas bancarias o estados financieros.

## Funcionalidades planteadas

- **Recursos e inventario:** seguimiento de existencias y recursos para detectar excesos o faltantes.
- **Economía circular:** publicación y búsqueda de materiales aprovechables como cartón, plástico, vidrio o textiles.
- **Logística compartida:** identificación de pedidos y destinos cercanos que podrían agruparse.
- **Indicadores:** seguimiento de materiales recuperados, entregas, eficiencia y oportunidades de ahorro.

## Aplicación

El prototipo está desarrollado con Flutter y Dart en `eco_logic_smart/`. La pantalla principal presenta un resumen operativo y accesos a los módulos que componen la propuesta. Los datos visibles son demostrativos y todavía no están conectados a un servicio ni a una base de datos.

## Requisitos

- Flutter SDK compatible con Dart `^3.10.8`
- Android Studio, VS Code u otro entorno compatible con Flutter

## Ejecutar localmente

```bash
cd eco_logic_smart
flutter pub get
flutter run
```

Para revisar problemas estáticos del código:

```bash
flutter analyze
```

## Estructura

```text
eco_logic_smart/
├── lib/
│   ├── app.dart
│   ├── main.dart
│   └── features/
│       └── dashboard/
│           └── dashboard_screen.dart
├── test/
├── android/
├── ios/
└── web/
```

## Alcance actual

Esta entrega implementa la base visual de la pantalla principal. El registro de empresas, almacenamiento de datos, publicación real de materiales, agrupación de rutas y cálculo de indicadores requieren etapas posteriores de diseño y validación con usuarios.

## Propósito académico

El proyecto corresponde a un emprendimiento de Ingeniería Industrial con enfoque STEAM. La propuesta está orientada inicialmente a hoteles, restaurantes, comercios y negocios de servicios de Cartagena.
