# Documentación AXU3EGB / AMD EDF

Guías de instalación y uso, comprobaciones hechas en la placa, mapas de pines y documentación de referencia.

## Índice rápido

- [Instalar Vivado 2026.1 y preparar AMD EDF 26.06](INSTALACION_EDF_VIVADO.md)
- [Primer arranque por microSD y consola UART](PRIMER_ARRANQUE.md)
- [Diagnóstico de periféricos y estado observado](DIAGNOSTICO_PERIFERICOS.md)
- [Base EDF 26.06 y Vivado 2026.1](BASE_EDF_2026.1.md)
- [Pinout de J45/J46 y tablas del manual](AXU3EGB_Pinout_Referencia.pdf)
- [Machete visual de la placa](AXU3EGB_Machete_Visual.pdf) ([PNG](AXU3EGB_Machete_Visual.png))
- [Lámina grande Vivado/XDC: foto, J45, J46 y AN970](AXU3EGB_Pinout_Vivado_Grande.png)
- [AN970: pinout P4 ↔ J45 y plan de prueba](AN970_Pinout_y_Prueba.md)
- [Plan de prueba progresiva para AN970](AN970_Plan_Prueba.md)
- [Ventilador, sensores y monitor tipo htop](plan-control-fan-monitor.md)
- [Manual de usuario AXU3EGB publicado por ALINX](fuentes/alinx/AXU3EGB_User_Manual_ALINX.pdf)
- [Índice Markdown de fuentes oficiales y notas de compatibilidad](fuentes/alinx/REFERENCIAS_ALINX.md)
- [Guías Linux oficiales de ALINX: resumen, límites y enlaces](fuentes/alinx/GUIAS_LINUX_ALINX_REFERENCIAS.md)
- [Síntesis Markdown del README oficial de ALINX para la familia AXU3EG](fuentes/alinx/README_ALINX_AXU3EG_FAMILIA.md)

## Estado comprobado

La microSD arrancó AMD EDF 26.06 con hardware preparado usando Vivado 2026.1. Se confirmó consola UART, 4 Cortex-A53, 4 GB de DDR instalada (aprox. 3.8 GiB utilizables), Ethernet del PS y acceso SSH. Las temperaturas de AMD System Monitor son visibles en Linux. La eMMC se detectó, pero no se montó ni modificó.

El bitstream que arrancó es una base PS mínima. No valida todavía LCD/táctil AN970, cámara AN5641, UART PL, RS485, Ethernet PL, DDR de PL ni el resto de periféricos. La documentación distingue mediciones reales de configuraciones todavía propuestas.

## Notas de uso

- La lámina grande está en resolución 6000 × 6500 para acercar e imprimir; J46 aparece a la izquierda y J45 a la derecha en la foto del manual.
- El mapeo de AN970 se transcribe desde manuales ALINX, pero falta probar la pantalla en la placa y validar el XDC antes de cablear y generar un bitstream.
- J45/J46 son señales de PL; no aplicar 5 V a sus I/O. La lámina añade UART PL, LED/botón PL, fan, RS485, MIPI y Ethernet PL con package pins; B65 es 1.2 V y B66 1.8 V.
- Los documentos de Vivado/EDF y las fuentes de terceros mantienen sus propias licencias y atribuciones. Las imágenes de AMD, credenciales, licencias, builds y archivos WIC no se guardan en GitHub.
