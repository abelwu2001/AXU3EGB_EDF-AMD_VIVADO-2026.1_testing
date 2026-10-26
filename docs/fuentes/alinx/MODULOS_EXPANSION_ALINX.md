# Módulos de expansión ALINX para AXU3EGB

Este índice reúne los manuales oficiales y resume para qué sirve cada módulo. Los PDF siguen alojados en ALINX; se enlazan desde allí para conservar su origen y evitar publicar copias de documentos con derechos de autor.

## Manuales y uso

| Módulo | Función | Datos principales | Manual oficial |
|---|---|---|---|
| AN970 | Pantalla LCD táctil capacitiva | 7″, 800×480, RGB888, 5 puntos táctiles | [Manual AN970 (PDF)](https://alinx.com/public/upload/file/AN970_User_Manual.pdf) |
| AN9238 | Adquisición de dos señales analógicas rápidas | AD9238, 2 canales, 12 bits, hasta 65 MSPS, entrada de módulo −5 a +5 V | [Manual AN9238 (PDF)](https://www.alinx.com/public/upload/file/AN9238_User_Manual.pdf) |
| AN706 | Adquisición de hasta ocho señales analógicas | AD7606, 8 canales, 16 bits, hasta 200 kSPS, rango indicado por ALINX −5 a +5 V | [Manual AN706 (PDF)](https://alinx.com/public/upload/file/AN706__User_Manual.pdf) |
| AN9767 | Generación de señales analógicas | AD9767, 2 canales, 14 bits, hasta 125 MSPS, salida indicada −5 a +5 V | [Manual AN9767 (PDF)](https://alinx.com/public/upload/file/AN9767_User_Manual.pdf) |
| AN5641 | Cámara MIPI con sensor OV5640 | Captura de imagen; la AXU3EG documenta el conector de cámara J23 | [Manual AN5641 (PDF)](https://www.alinx.com/public/upload/file/AN5641_User_Manual.pdf) |

## Ideas de laboratorio con el osciloscopio DHO914S

El DHO914S es de RIGOL (no Hantek): 125 MHz de ancho de banda, cuatro entradas analógicas y generador arbitrario incorporado en el modelo “S”. Su generador es una fuente de prueba; sus entradas permiten observar señales. [Ficha DHO900 de RIGOL](https://www.rigolna.com/products/rigol-digital-oscilloscopes/dho900/).

- **AN9238:** generar una senoide de baja amplitud y frecuencia, medirla simultáneamente con el osciloscopio y capturarla con el ADC. Comparar amplitud/frecuencia con las muestras leídas por la FPGA.
- **AN706:** aplicar señales lentas a sus canales y comparar el nivel analógico medido con el valor convertido por el ADC; luego probar adquisición multicanal.
- **AN9767:** generar una forma de onda digital desde la FPGA/DAC y medir amplitud, frecuencia y offset en el osciloscopio.
- **AN970:** observar pixel clock, sincronismos y señales de control; el RGB paralelo requiere cuidado al medir. La prueba de pantalla ya mostró barras de color.
- **AN5641:** usar el osciloscopio para mirar señales de control lentas, pero no medir las líneas MIPI de alta velocidad con puntas pasivas comunes.

## Precauciones y estado

- Estos módulos no quedan operativos por estar listados aquí: falta diseñar/validar la interfaz HDL, asignaciones XDC y software de lectura donde corresponda.
- Antes de conectar, confirmar en los manuales el pin 1, alimentación, dirección de señales y niveles eléctricos del conector concreto de la AXU3EGB. No insertar ni retirar módulos con la placa alimentada.
- Usar la masa del osciloscopio en GND de la placa y empezar con señales de baja tensión. No conectar directamente señales de red eléctrica.
- Los límites de tensión indicados son límites del módulo ALINX, no una recomendación para comenzar el experimento a máxima amplitud.
- Estado al añadir esta guía: AN970 mostró barras de color. Los otros módulos aún no están declarados probados en este proyecto.
