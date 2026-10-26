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
- [Módulos de expansión ALINX, manuales oficiales y prácticas con DHO914S](fuentes/alinx/MODULOS_EXPANSION_ALINX.md)
- [Ventilador, sensores y monitor tipo htop](plan-control-fan-monitor.md)
- [Proyecto completo fan PWM para EDF 26.06/Vivado 2026.1](../hardware/fan-control-stage2/README.md)
- [Bitácora completa: pasos, comandos, salidas y código del PWM](Bitacora_PWM_Fan_AXU3EGB_2026-10-24.pdf)
- [Manual de usuario AXU3EGB publicado por ALINX](fuentes/alinx/AXU3EGB_User_Manual_ALINX.pdf)
- [Índice Markdown de fuentes oficiales y notas de compatibilidad](fuentes/alinx/REFERENCIAS_ALINX.md)
- [Guías Linux oficiales de ALINX: resumen, límites y enlaces](fuentes/alinx/GUIAS_LINUX_ALINX_REFERENCIAS.md)
- [Síntesis Markdown del README oficial de ALINX para la familia AXU3EG](fuentes/alinx/README_ALINX_AXU3EG_FAMILIA.md)

## Estado comprobado

La microSD arrancó AMD EDF 26.06 con hardware preparado usando Vivado 2026.1. Se confirmó consola UART, 4 Cortex-A53, 4 GB de DDR instalada (aprox. 3.8 GiB utilizables), Ethernet del PS y acceso SSH. Las temperaturas de AMD System Monitor son visibles en Linux. La eMMC se detectó, pero no se montó ni modificó.

El bitstream que arrancó es una base mínima del PS con PWM AXI para la fan en la PL. La AN970 mostró barras de color con una prueba propia en Vivado. Eso no valida todavía el panel táctil, la cámara AN5641, AN9238, AN706, AN9767, UART PL, RS485, Ethernet PL, DDR de PL ni los demás periféricos. La documentación distingue mediciones reales de configuraciones todavía propuestas.

## Notas de uso

- La lámina grande está en resolución 6000 × 6500 para acercar e imprimir; J46 aparece a la izquierda y J45 a la derecha en la foto del manual.
- J45/J46 son señales de PL; no aplicar 5 V a sus I/O. La lámina añade UART PL, LED/botón PL, fan, RS485, MIPI y Ethernet PL con package pins; B65 es 1.2 V y B66 1.8 V.
- Confirmar niveles y pinout del módulo concreto antes de conectarlo; no insertar ni retirar módulos con la placa alimentada.
- Los documentos de Vivado/EDF y las fuentes de terceros mantienen sus propias licencias y atribuciones. Las imágenes de AMD, credenciales, licencias, builds y archivos WIC no se guardan en GitHub.
