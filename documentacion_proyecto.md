# Documentación del proyecto EcoLogiSmart

## Descripción

EcoLogiSmart es una propuesta de plataforma digital para pequeñas y medianas empresas de Cartagena, en especial hoteles, restaurantes, comercios y negocios de servicios. Integra gestión de recursos e inventarios, aprovechamiento de materiales y logística compartida para organizar operaciones, reducir desperdicios y detectar oportunidades de ahorro.

El proyecto combina Ingeniería Industrial y enfoque STEAM. La plataforma utiliza información operativa voluntaria y no requiere ingresos, recaudos, utilidades, cuentas bancarias ni estados financieros.

## Problema y población objetivo

Algunas pymes tienen dificultades para controlar existencias, identificar materiales reutilizables y coordinar entregas. Esto puede producir desperdicio, costos operativos más altos y recorridos de transporte que podrían consolidarse. Materiales como cartón, plástico, vidrio y textiles pueden conservar valor para otros negocios.

La población inicial son pymes de Cartagena que gestionan compras, inventarios, residuos o entregas. Entre los actores relacionados están propietarios y administradores, responsables de compras e inventarios, personal logístico, transportadores y organizaciones que aprovechan materiales reciclables.

## Objetivo y propuesta de valor

El objetivo general es diseñar una plataforma que ayude a optimizar la gestión de recursos y operaciones logísticas, reducir costos y desperdicios, y promover el aprovechamiento de materiales mediante economía circular y logística compartida.

Los objetivos específicos son identificar las necesidades de las empresas; diseñar el seguimiento de recursos e inventarios; conectar materiales aprovechables con posibles receptores; proponer la agrupación de pedidos y rutas; definir indicadores de impacto y eficiencia; y desarrollar un prototipo conceptual con un plan de validación con usuarios.

Para ello, la propuesta reúne tres funciones que suelen gestionarse por separado:

- Organización de recursos e inventarios para reconocer excesos, faltantes y oportunidades de mejora.
- Conexión entre empresas que ofrecen materiales aprovechables y empresas que podrían utilizarlos.
- Identificación de pedidos y destinos cercanos para proponer agrupación de entregas y transporte compartido.

## Funcionamiento propuesto

1. **Registro de la empresa:** cada negocio registra datos operativos básicos, como existencias, materiales aprovechables y necesidades de transporte.
2. **Diagnóstico:** la plataforma organiza los datos y señala oportunidades relacionadas con desperdicios, inventarios y recorridos.
3. **Economía circular:** los materiales disponibles se presentan a negocios que podrían requerirlos como materia prima.
4. **Logística compartida:** pedidos con destinos o zonas cercanas se agrupan para proponer rutas y transporte compartido.
5. **Indicadores y seguimiento:** el negocio consulta medidas de costos, consumo, materiales aprovechados, entregas y eficiencia, y compara sus resultados en el tiempo.

## Aplicación desarrollada

La aplicación está disponible en [su versión web](https://jmartinezsys.github.io/EcoLogiSmart/) y también se ejecuta en dispositivos móviles. Incluye acceso y registro de empresas, perfil empresarial, tablero, diagnóstico, inventario, publicaciones de materiales, solicitudes logísticas e indicadores. Las cuentas admiten inicio, cierre y recuperación de sesión y contraseña. El acceso a la presentación pública requiere conexión a internet.

La aplicación cuenta con dos modos de almacenamiento. En el modo de demostración, las cuentas y operaciones se guardan localmente y no se sincronizan entre dispositivos. Con el servicio Supabase configurado, se habilitan autenticación y persistencia compartida para perfiles, inventario, publicaciones y solicitudes logísticas. Las imágenes de materiales también pueden guardarse en el servicio. Los productos locales se pueden recuperar al pasar una cuenta a la nube.

La conexión compartida requiere un proyecto Supabase con las dos migraciones incluidas en `eco_logic_smart/supabase/migrations/`. La migración base habilita perfiles, inventario, publicaciones, solicitudes y fotografías; la segunda añade propuestas de intercambio y solicitudes para unirse a rutas. Sin la configuración del servicio, la aplicación continúa en modo local. El flujo y los requisitos de la publicación están en el [README de la aplicación](eco_logic_smart/README.md).

### Uso básico

1. La empresa crea una cuenta e ingresa sus datos básicos.
2. En **Recursos**, registra productos, cantidades y el nivel mínimo que desea vigilar. El inventario permanece privado.
3. En **Circular**, publica solo el material que desea ofrecer. Puede marcarlo para aprovechamiento o intercambio, añadir una descripción y adjuntar una fotografía.
4. En **Rutas**, registra origen, destino, tipo de entrega, capacidad o carga y fecha. Otras empresas pueden solicitar unirse a una ruta compartida.
5. En **Indicadores**, revisa la actividad guardada, las existencias bajas, materiales publicados y destinos repetidos.

El diagnóstico señala oportunidades a partir de los datos registrados. Las coincidencias de materiales o destinos no garantizan un acuerdo: las empresas todavía coordinan las condiciones de intercambio o transporte.

## Plan de trabajo del grupo

El grupo organizó la planeación inicial por semanas y fases. Como el cronograma no asigna fechas de calendario, la secuencia se conserva por semana. La tabla registra las actividades y entregables propuestos; no confirma por sí sola que cada actividad se haya completado.

| Semana y fase | Actividades previstas | Entregable o evidencia esperada |
| --- | --- | --- |
| **1. Sensibilización y conformación** | Presentación del reto, conformación del equipo, asignación de roles y definición del campo de interés. | Acta de constitución y tres posibles retos relacionados con Cartagena: costos y eficiencia logística; desperdicio y baja valorización de materiales; y control de recursos en pymes. |
| **2. Exploración del contexto** | Observación de negocios y revisión de información sobre pymes, turismo, logística y economía circular; identificación de actores y preparación de entrevistas y encuestas. | Plan de investigación, mapa preliminar de actores e instrumentos preparados. |
| **3. Investigación del problema** | Realización de entrevistas, encuestas y observaciones; organización de datos e identificación de necesidades recurrentes. | Diagnóstico y banco de evidencias. La meta propuesta es cinco entrevistas o entre diez y veinte encuestas, además de observaciones documentadas. |
| **4. Definición del reto** | Análisis de causas y efectos, definición del perfil del usuario, delimitación del problema y formulación de la pregunta de diseño. | Ficha del reto con usuario, problema, evidencia local y la pregunta: «¿De qué manera puede EcoLogiSmart ayudar a las pymes de Cartagena a reducir costos y desperdicios mediante una mejor gestión de recursos, el aprovechamiento de materiales y la logística compartida?» |
| **5. Ideación y alternativas** | Generación de opciones, elaboración de bocetos y comparación por impacto, costo, innovación y viabilidad. | Portafolio de al menos diez ideas y matriz de selección con criterios cuantificados. Las opciones propuestas incluyen una aplicación de inventarios, mercado de materiales, sistema de rutas, banco de materiales, tablero de indicadores y transporte compartido. |
| **6. Diseño conceptual** | Definición del funcionamiento y de los componentes STEAM e industriales; elaboración de diagramas de flujo, prototipo conceptual y presupuesto preliminar. | Diseño conceptual, especificaciones, presupuesto preliminar y responsabilidades. La aplicación disponible constituye un prototipo funcional para presentar y validar la propuesta. |

Las entrevistas, encuestas y observaciones de las semanas 2 y 3 son metas de investigación. El plan propone evitar la solicitud de datos financieros privados y de permisos empresariales que no sean necesarios para validar el prototipo.

## Componentes de Ingeniería Industrial y STEAM

| Área | Aplicación en EcoLogiSmart |
| --- | --- |
| Logística | Optimización de rutas, consolidación de pedidos y transporte compartido. |
| Gestión de inventarios | Seguimiento de existencias y apoyo para prevenir excesos o faltantes. |
| Gestión de procesos | Identificación de actividades que generan desperdicio o demoras. |
| Economía circular | Aprovechamiento y conexión de materiales que pueden servir como materia prima. |
| Gestión de costos | Detección de oportunidades para reducir costos operativos y logísticos. |
| Indicadores | Medición de eficiencia, costos, tiempos, materiales aprovechados y consumo. |
| Sostenibilidad | Reducción de desperdicios, recorridos innecesarios y uso ineficiente de recursos. |

El enfoque STEAM combina diseño de interfaz, tecnología, organización de datos, análisis operativo y evaluación de impacto. La aplicación permite mostrar un primer prototipo de los módulos de recursos e inventarios, materiales, logística e indicadores.

## Indicadores iniciales

- Empresas consultadas durante la investigación.
- Usuarios que identifican dificultades con costos, inventarios, residuos o transporte.
- Materiales aprovechables identificados.
- Rutas o pedidos con potencial de agrupación.
- Ahorro potencial de costos logísticos estimado.
- Residuos que podrían reincorporarse a procesos productivos.
- Aceptación del prototipo entre las personas consultadas.

El grupo propone estas medidas para evaluar el proyecto. Sus valores dependerán de la recolección de datos y de la validación con usuarios.

## Alcance y resultado esperado

El prototipo es una herramienta de apoyo operativo, no un sistema de auditoría financiera. La información se limita a los datos necesarios para organizar recursos, materiales y transporte, lo que facilita la validación con pymes.

Como entregables del proyecto, el grupo planteó un diagnóstico sustentado en evidencia de usuarios, la definición del reto, una matriz de selección, el diseño de la plataforma, el flujo del servicio, un presupuesto preliminar e indicadores de impacto. La aplicación ya cuenta con un prototipo funcional; su alcance técnico se describe en la sección anterior.

Para explicar la propuesta a personas que no conocen el proyecto, el [guion de sustentación en PDF](output/pdf/guion_sustentacion_ecologismart.pdf) divide la exposición entre cuatro integrantes. La [versión editable](guion_sustentacion.md) conserva el texto fuente.

## Documentación relacionada

- [Informe de cambios por commits](informe_general.md): historial de modificaciones registradas en Git.
- [README de la aplicación Flutter](eco_logic_smart/README.md): instrucciones de inicio y descripción breve de sus pantallas.
