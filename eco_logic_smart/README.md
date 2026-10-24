# EcoLogiSmart Flutter App

Aplicación Flutter del prototipo EcoLogiSmart. Consulta el [README del repositorio](../README.md) para conocer el objetivo, alcance y módulos del proyecto.

## Inicio rápido

```bash
flutter pub get
flutter run
```

## Pantallas del prototipo

- Inicio de sesión: valida cuentas locales creadas en el dispositivo o navegador.
- Registro de empresa: guarda el perfil localmente y abre el espacio personalizado de esa empresa.
- Carga: muestra el isotipo mientras Flutter inicializa la aplicación.

- Inicio: resumen operativo e impacto estimado.
- Diagnóstico: hallazgos operativos demostrativos y oportunidades de mejora.
- Recursos: inventario y registro local de recursos y consumos.
- Circular: materiales disponibles e interfaz para publicar excedentes.
- Rutas: oportunidades de consolidación y solicitud de transporte.
- Indicadores: seguimiento de metas e impacto estimado.
- Perfil de empresa: registro de datos operativos básicos y sector.

Las cuentas y los perfiles se conservan localmente con SharedPreferences; los módulos operativos aún usan datos de demostración y no se sincronizan entre dispositivos ni tienen backend.
