# Plan de prueba AN970 en AXU3EG

## Hardware identificado

La AN970 es una pantalla tactil capacitiva de 7 pulgadas, 800x480, RGB de 24 bits. El modulo usa el conector hembra P4 de 40 pines. El manual AXU3EG indica que J45 expone los mismos 40 pines: tierra, 5 V, dos 3.3 V y 34 señales FPGA. El manual especifica que los bancos 43-46 son de 3.3 V; el conector J45 usa señales de los bancos 45 y 46. Esto coincide con la interfaz electrica esperada por el modulo.

Antes de conectar, apagar la placa, confirmar que es el encabezado J45 y alinear el pin 1 con el pin 1. No forzar el conector ni conectarlo desplazado. Las señales de video salen desde la PL; la pantalla no se activa con el Linux actual por si solo.

## Mapeo P4 de AN970 a J45

El cableado es directo por numero de pin: P4-n de AN970 va a J45-n de AXU3EG. Las posiciones de alimentacion/tierra tambien coinciden. Para llevarlo al XDC, usar este mapa de señales:

| P4/J45 | Senal AN970 | Pin FPGA | Banco |
|---:|---|---|---:|
| 3 | INIT (interrupt touch) | B10 | 45 |
| 4 | BACK_LED_PWM | C11 | 45 |
| 5 | SCL (touch) | F10 | 45 |
| 6 | SDA (touch) | G11 | 45 |
| 7 | LCD_HSYNC | C12 | 45 |
| 8 | LCD_VSYNC | D12 | 45 |
| 9 | LCD_DCLK | A11 | 45 |
| 10 | LCD_DE | A12 | 45 |
| 11-18 | LCD_B[7:0] (bits intercalados) | F11, F12, E13, E14, A13, B13, A14, B14 | 45/46 |
| 19-26 | LCD_G[6:0] (bits intercalados) | C13, C14, L13, L14, H12, J12, J14, K14 | 46 |
| 27-34 | LCD_R[6:0] (bits intercalados) | H13, H14, F13, G13, G14, G15, D14, D15 | 46 |
| 35 | LCD_SDA | A15 | 46 |
| 36 | LCD_SCL | B15 | 46 |

La tabla agrupa los pines de datos en orden fisico P4: dentro de cada par van primero los bits pares indicados en el manual (B6/B7, B4/B5, etc.). Al escribir el XDC, cada bit del bus RGB debe asociarse cuidadosamente con su pin individual segun la tabla del manual. No copiar las listas agrupadas como si fueran el orden del bus.

## Secuencia de validacion

1. Respaldar la microSD de EDF y conservar intacta la imagen que arranca.
2. Preparar un proyecto Vivado 2026.1 separado del proyecto base y del proyecto original.
3. Verificar contra los manuales la asignacion J45, el orden exacto de bits RGB y los tiempos de LCD. Crear un generador 800x480 con pixel clock y temporizaciones confirmados; empezar con barras de color.
4. Simular los contadores, HSYNC, VSYNC, DE, RGB y backlight. Ejecutar DRC, sintesis e implementacion antes de programar.
5. Probar temporalmente por JTAG con la pantalla conectada y la placa apagada durante el cableado. Documentar resultado y cualquier ajuste.
6. Solo despues decidir si se integra al arranque EDF. El tactil se prueba aparte por I2C en P4-5/6 y la interrupcion P4-3.

## Estado

AN970 aun no probada en esta placa. El bitstream activo es minimo y no incluye salida RGB. La documentacion de ALINX enumera un tutorial AXU3EG para AN970 y otro para captura MIPI con AN5641, pero no hemos validado que sus fuentes o binarios sean compatibles directamente con Vivado 2026.1/EDF 26.06.

Fuentes: [manual AN970](https://alinx.com/public/upload/file/AN970_User_Manual.pdf), [manual AXU3EG](https://alinx.com/public/upload/file/AXU3EG_User_Manual.pdf), [lista de tutoriales AXU3EG](https://github.com/fpgauk/axu3eg/blob/main/docs/AXU3EG_Tutorial_List.md).
