# Prueba de video AN970: barras de color

**Resultado:** prueba visual exitosa en la placa AXU3EGB con la pantalla ALINX AN970 conectada al conector J45. La foto de evidence/an970-colorbars-on-board.png muestra las ocho franjas generadas en la PL.

## Qué se probó

- Proyecto creado y compilado con **Vivado 2026.1**, dirigido a xczu3eg-sfvc784-1-e.
- Salida RGB paralela de 24 bits, resolución activa 800 × 480.
- Reloj de píxel de aproximadamente 33 MHz.
- Ventana activa lcd_de y barras de color RGB generadas en lógica Verilog.
- Pines del conector J45 asignados en base.xdc.
- El bitstream base_wrapper.bit fue programado temporalmente por JTAG y la imagen permaneció visible en la AN970.

La prueba visual confirma que la placa entrega imagen en esta configuración concreta. **No equivale a validar todos los modos del panel ni a validar el táctil.** Esta versión mantiene lcd_hsync y lcd_vsync en alto, y mantiene el backlight encendido; más adelante conviene estudiar esos controles y los tiempos indicados por ALINX.

## Abrir el proyecto

1. Descomprimir o clonar el repositorio conservando las carpetas.
2. En Vivado 2026.1, abrir project/axu3eg_base.xpr.
3. El proyecto busca el repositorio de IP en ../ip_repo; ahí está incluida la fuente del IP personalizado axi_pwm.
4. Si Vivado pregunta por productos generados, ejecutar **Generate Output Products** y después síntesis e implementación.
5. El bitstream de referencia ya generado está en base_wrapper.bit.

El proyecto contiene archivos editables (.xpr, .bd, .v, .xdc y .xci). Las carpetas de caché, simulación, síntesis e implementación se omiten porque Vivado puede regenerarlas y ocupan mucho más.

## Programar la placa

base_wrapper.bit es un bitstream para **programación volátil por JTAG**. No reemplaza /efi/boot.bin, no modifica la microSD y no configura el FPGA automáticamente después de apagar la placa. Para dejarlo persistente haría falta generar un nuevo paquete de arranque compatible con el Linux instalado; ese paso no forma parte de esta prueba.

Al programarlo por JTAG, se reemplaza temporalmente el diseño que estaba en la PL. El PS/Linux sigue siendo independiente mientras no se reinicie o se cambie el paquete de arranque.

## Qué falta

- Conectar e implementar el controlador táctil GT911 (bus I²C y señales asociadas); esta prueba solo demuestra video.
- Mostrar métricas Linux tipo htop en la AN970. Eso requiere una ruta de video para el framebuffer o un renderizador PL y un canal desde Linux para enviar datos.
- Validar el backlight y los tiempos HSYNC/VSYNC contra el modo exacto elegido del manual.
- Probar arranque persistente desde microSD solo si se decide integrar este diseño en un nuevo BOOT.BIN.

El panel es táctil capacitivo, pero la lógica táctil no está conectada por este diseño. La prueba actual no lee toques.

## Archivos

- project/axu3eg_base.xpr: proyecto Vivado.
- project/axu3eg_base.srcs/sources_1/bd/base/base.bd: diagrama de bloques.
- project/axu3eg_base.srcs/sources_1/new/an970_colorbars.v: generador de video y barras.
- project/axu3eg_base.srcs/sources_1/bd/base/ip/: configuraciones de IP.
- project/axu3eg_base.gen/sources_1/bd/base/hdl/base_wrapper.v: wrapper HDL generado por Vivado.
- base.xdc: asignaciones de pines del fan y la pantalla.
- ip_repo/axi_pwm_1_0/: fuente del IP AXI PWM requerido por este proyecto.
- base_wrapper.bit: resultado compilado para JTAG.
- evidence/an970-colorbars-on-board.png: foto de la prueba física.

## Aprendizaje: qué hace el diseño

El reloj de píxel marca cuándo se presenta cada punto. Dos contadores recorren las posiciones horizontal y vertical. lcd_de señala el rectángulo visible de 800 × 480 píxeles. Según la coordenada horizontal activa, la lógica asigna valores de rojo, verde y azul para formar franjas. Vivado sintetiza ese Verilog, ubica la lógica dentro de la FPGA y la conecta a los pines descritos en el XDC.

Referencia del panel: [Manual AN970 de ALINX](https://alinx.com/public/upload/file/AN970_User_Manual.pdf).
