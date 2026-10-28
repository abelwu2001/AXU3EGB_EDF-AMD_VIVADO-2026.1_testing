# AXU3EGB / AXU3EG + AMD EDF — laboratorio FPGA/SoC

Registro de proyectos y pruebas realizadas con la placa ALINX AXU3EGB, Vivado y AMD Embedded Development Framework (EDF). Incluye fuentes, archivos Vivado editables, firmware y evidencias de los avances.

> **Versiones:** el diseño combinado de monitor AN970 y control de fan se compiló con **Vivado 2026.1** y se probó con **AMD EDF 26.06**. El nombre del repositorio menciona Vivado 2026.2 como objetivo de investigación; esa versión todavía no está validada aquí.

## Proyectos

| Etapa | Carpeta | Resultado |
|---|---|---|
| Monitor Linux AN970 + fan PWM | [hardware/an970-linux-monitor-2026.1](hardware/an970-linux-monitor-2026.1/) | Diseño combinado: datos reales de Linux por AXI-Lite, interfaz horizontal 800×480 y regulación térmica PWM. Arrancó en la placa. |
| Pantalla AN970 con barras de color | [hardware/an970-colorbars](hardware/an970-colorbars/) | Primera prueba de video por PL; franjas de color visibles en el panel. |
| Control PWM de fan | [hardware/fan-control-stage2](hardware/fan-control-stage2/) | PWM AXI y arranque EDF/overlay/UIO, documentado como etapa previa del control térmico. |
| Manuales, pinout y notas de laboratorio | [docs](docs/) | Referencias ALINX/AMD, preparación del entorno, primeros arranques y guías de placa. |

El historial por hitos está explicado en [docs/PROYECTOS.md](docs/PROYECTOS.md). Las capturas y fotos están agrupadas en [docs/avances/](docs/avances/).

## Hito actual: monitor Linux en la AN970

El PS ZynqMP ejecuta Linux. Un servicio lee carga de cada Cortex-A53, RAM, sensores AMS, duty PWM y dirección IPv4; publica esos valores en registros AXI-Lite. La PL lee los registros y dibuja un monitor horizontal. Otro servicio ajusta el ventilador según la temperatura.

- AXI PWM: `0xA0000000`.
- AXI-Lite de métricas: `0xA0010000`.
- Cuatro cores, RAM, tres temperaturas, porcentaje de duty e IPv4 en pantalla.
- La regla térmica arranca alrededor de 40 °C, usa histéresis alrededor de 38 °C y llega a 100 % a 60 °C.
- La pantalla informa el duty ordenado, no RPM medidas: este diseño no recibe una señal de tacómetro.
- Puede arrancarse con fan solamente o con fan + publicador de métricas; ambos modos usan el mismo bitstream combinado.

## Evidencia y límites

El monitor horizontal y el control PWM se observaron funcionando en la placa. Vivado completó síntesis, implementación y generación del bitstream. La captura de timing mostró WNS 7.215 ns, TNS 0 ns y WHS 0.037 ns. Quedaron advertencias de metodología por retardos externos de E/S no restringidos; esto no certifica todos los periféricos ni todos los modos de la placa.

## Documentación

- [Catálogo e historial de proyectos](docs/PROYECTOS.md)
- [Chuleta de systemd: tareas, dependencias y modos de arranque](docs/COMANDOS_SYSTEMD_Y_ARRANQUE.md)
- [Galería de avances](docs/avances/README.md)
- [Manual del monitor combinado](hardware/an970-linux-monitor-2026.1/README.md)
- [Manual del panel AN970 y pinout](docs/AN970_Pinout_y_Prueba.md)
- [Plan de pruebas de periféricos](docs/AN970_Plan_Prueba.md)
- [Instalación EDF/Vivado](docs/INSTALACION_EDF_VIVADO.md)
- [Primer arranque](docs/PRIMER_ARRANQUE.md)
- [Documentación ALINX](docs/fuentes/alinx/README_ALINX_AXU3EG_FAMILIA.md)

Los proyectos guardan fuentes y artefactos útiles para reconstruir el diseño. Vivado regenera los productos derivados que no se versionan, como cachés y resultados completos de síntesis e implementación.

