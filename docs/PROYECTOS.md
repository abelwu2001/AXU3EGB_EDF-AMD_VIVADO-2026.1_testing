# Catálogo de proyectos AXU3EGB

Este repositorio conserva los avances como hitos separados y mantiene el diseño integrado actual como referencia principal.

## Mapa rápido de lo que hicimos

| Hito | Proyecto | Qué aporta | Evidencia |
|---|---|---|---|
| 1 | [Arranque AMD EDF 26.06](BASE_EDF_2026.1.md) | Linux AArch64, SSH/Ethernet, DDR y sensores AMS en la placa. | [Fotos del monitor en funcionamiento](avances/README.md#prueba-en-placa). |
| 2 | [Barras de color en AN970](../hardware/an970-colorbars/README.md) | Primer video RGB generado en la PL y salida por J45. | [Foto de las barras en el panel](../hardware/an970-colorbars/evidence/an970-colorbars-on-board.png). |
| 3 | [Fan PWM AXI](../hardware/fan-control-stage2/README.md) | IP PWM, mapa AXI, overlay Device Tree, UIO y servicio térmico en Linux. | [Documentación de la etapa PWM](../hardware/fan-control-stage2/README.md). |
| 4 | [Monitor Linux + fan](../hardware/an970-linux-monitor-2026.1/README.md) | Diseño integrado: telemetría PS→AXI→PL, pantalla horizontal e indicador PWM. | [Galería de capturas y fotos](avances/README.md). |

La galería conserva las capturas representativas de Vivado y fotos reales de cada salida de video. No publica volcados indiscriminados de terminal: esos podían incluir datos de acceso y no añaden evidencia visual al diseño.

## Preparación de EDF y Vivado

- [Instalación y notas de Vivado/EDF](INSTALACION_EDF_VIVADO.md)
- [Base EDF 26.06](BASE_EDF_2026.1.md)
- [Primer arranque por microSD/UART/Ethernet](PRIMER_ARRANQUE.md)
- [Diagnóstico de periféricos](DIAGNOSTICO_PERIFERICOS.md)

Se verificó el arranque de Linux AArch64 con 4 cores Cortex-A53, 4 GB físicos de DDR (aprox. 3.8 GiB visibles en Linux), Ethernet PS, SSH y lecturas AMS.

## Pruebas de hardware en orden

### Colorbars en AN970

Carpeta: [`hardware/an970-colorbars`](../hardware/an970-colorbars/)

Primer diseño de video por PL. El panel AN970 mostró barras de color. Sirvió para comprobar el camino de pines RGB y señales de control desde Vivado hacia J45; no valida el táctil ni todos los modos del panel.

### PWM AXI para la fan

Carpeta: [`hardware/fan-control-stage2`](../hardware/fan-control-stage2/)

Se creó un IP PWM AXI, se probó acceso desde Linux mediante Device Tree/UIO y se preparó un BOOT.BIN de la etapa PWM. Quedó como referencia anterior para entender el PWM y el arranque.

### Monitor Linux + fan integrados

Carpeta: [`hardware/an970-linux-monitor-2026.1`](../hardware/an970-linux-monitor-2026.1/)

Versión integrada actual compilada con Vivado 2026.1. La pantalla usa registros AXI-Lite alimentados por Linux para dibujar CPU, RAM, temperaturas, duty PWM e IP. `fan-pwm.service` controla la fan; `linux-metrics-publish.service` publica los datos para la pantalla; `monitor-bitstream.service` carga el bitstream desde `/lib/firmware` al arrancar.

## Modos de arranque del monitor integrado

Los dos modos comparten el mismo bitstream y servicio de fan:

- **Fan solamente:** `monitor-bitstream.service` + `fan-pwm.service`; dejar deshabilitado `linux-metrics-publish.service`. La imagen sigue siendo el diseño combinado, pero las métricas no se actualizan.
- **Fan + pantalla con métricas:** habilitar los tres servicios.

Los comandos exactos para cambiar el modo y reiniciar están en el README del proyecto combinado. No ejecutar dos controladores que escriban al mismo PWM.

## Trabajo posterior

- Probar la respuesta térmica de forma controlada y revisar los umbrales con la placa real.
- Mejorar las restricciones externas de timing de la AN970.
- Validar otras funciones del panel/táctil y periféricos del kit por separado.
- Investigar Vivado 2026.2 cuando el flujo EDF esté disponible para una prueba repetible.

## Fotos

La [galería de avances](avances/README.md) reúne evidencia desde Block Design y Address Map hasta la pantalla ejecutándose en la placa.

