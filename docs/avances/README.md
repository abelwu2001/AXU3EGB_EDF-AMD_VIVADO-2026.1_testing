# Galería de avances de laboratorio

Capturas y fotos representativas de los proyectos, ordenadas para contar el progreso de punta a punta. Son evidencia visual de las etapas; los fuentes y reportes de Vivado siguen siendo la referencia técnica.

## Vivado y arquitectura del monitor

| Etapa | Evidencia |
|---|---|
| Mapa AXI | [`02-mapa-de-direcciones-axi.png`](02-mapa-de-direcciones-axi.png): PWM y métricas con segmentos de dirección separados. |
| Reloj de video y reset | [`03-reloj-y-reset-del-video.png`](03-reloj-y-reset-del-video.png): reloj de píxel y reset del dominio de video en el Block Design. |
| Integración de métricas | [`04-metricas-en-block-design.png`](04-metricas-en-block-design.png): instancia AXI-Lite de métricas conectada en el diseño. |
| Implementación | [`05-implementacion-vivado.png`](05-implementacion-vivado.png): Vivado confirma implementación completada. |
| Estado de IP | [`06-ip-status-al-dia.png`](06-ip-status-al-dia.png): los IP aparecen up-to-date. |
| Bitstream | [`07-bitstream-generado.png`](07-bitstream-generado.png): Vivado confirma generación del bitstream. |
| Prueba en placa | [`08-monitor-linux-en-la-placa.jpg`](08-monitor-linux-en-la-placa.jpg): AXU3EGB y AN970 mostrando el monitor horizontal con métricas Linux y panel PWM. |

## Resultados físicos de los proyectos

| Proyecto | Foto | Qué confirma la imagen |
|---|---|---|
| AN970 Colorbars | [Ocho barras RGB en la AN970](../../hardware/an970-colorbars/evidence/an970-colorbars-on-board.png) | La ruta de video y los pines RGB/control mostraron imagen en el panel. No prueba la pantalla táctil. |
| Monitor Linux + fan PWM | [Monitor horizontal en la placa](08-monitor-linux-en-la-placa.jpg) | La AN970 mostró las métricas publicadas por Linux y el panel de control PWM en ejecución. |

## Cómo leer las evidencias

- **Colorbars:** primer hito de video; una imagen fija generada completamente en la PL.
- **Fan PWM:** etapa de control AXI/UIO y servicio Linux documentada en [el proyecto PWM](../../hardware/fan-control-stage2/README.md). La imagen combinada más reciente muestra el bloque PWM junto al monitor; el duty mostrado es el valor ordenado, no RPM medidos.
- **Monitor combinado:** Vivado entrega el bitstream y EDF carga la lógica PL; un servicio Linux escribe CPU, RAM, temperaturas, duty e IP en registros AXI-Lite para que Verilog los dibuje.

Las capturas de progreso se seleccionaron entre las compartidas durante la sesión. Se excluyeron imágenes de terminal que podían mostrar credenciales. La galería cubre cada proyecto y sus hitos visuales principales, no cada clic intermedio de la interfaz.

