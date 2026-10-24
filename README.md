# AXU3EGB + AMD Embedded Development Framework (EDF)

Pruebas de arranque y notas de desarrollo para una placa ALINX AXU3EG/AXU3EGB con AMD EDF, Vivado y Linux en el PS Zynq UltraScale+. El objetivo es aprender el flujo actual de AMD y validar gradualmente los periféricos del kit, empezando por la pantalla táctil AN970.

> **Estado de versiones:** la base que se preparó y arrancó en la placa usa **Vivado 2026.1** y la imagen oficial **AMD EDF 26.06**. Este repositorio se creó para explorar **2026.2**, pero esa versión todavía no está probada aquí. El nombre del repositorio expresa el objetivo de las pruebas, no una compatibilidad ya confirmada.

## Estado actual

La placa arrancó desde una microSD de 64 GB y llegó a la consola Linux por UART. El sistema operativo es AArch64 y se pudo acceder por SSH a través de Ethernet.

| Recurso | Resultado observado |
|---|---|
| SoC | Zynq UltraScale+ `zu3eg`; Linux ve cuatro Cortex-A53 AArch64 |
| DDR del PS | U-Boot informó 4 GiB; Linux mostró aproximadamente 3.8 GiB utilizables |
| UART de consola | Adaptador CP210x por COM4, 115200 baudios, 8N1 |
| microSD | Arranque EDF correcto desde una tarjeta de 64 GB; la partición raíz se expandió |
| Ethernet del PS | Interfaz `end0` activa con IPv4 e IPv6; SSH confirmado |
| eMMC | Detectada como dispositivo de 29.6 GB; no se montó ni se modificó |
| Temperaturas | Linux expuso tres lecturas de `hwmon`, alrededor de 28.9, 30.0 y 28.8 °C en la prueba compartida |
| Ventilador | PWM AXI desde Linux: overlay aplicado, UIO4 en `0xA0000000`, servicio systemd activo. A 29–30 °C ordenó 0 % y la fan se detuvo físicamente; falta validar el giro a 30 % y el tramo térmico 40–60 °C |

Estas observaciones prueban el arranque y algunas funciones del PS en esta placa. No constituyen una validación de todos los periféricos del kit.

## Hardware que está activo

El bitstream que arrancó es una base mínima para el Processing System (PS), con Cortex-A53, DDR del PS, UART0, controlador SD, Ethernet GEM3 del PS y un PWM AXI para la fan en la PL. No es el diseño completo de Vivado 2023.2. La configuración se generó para la AXU3EG con Vivado 2026.1.

La lógica programable (PL) todavía **no** incluye el diseño completo de Vivado 2023.2. Por lo tanto, no están activos en el bitstream actual el LED y botón PL, RS485, Ethernet RGMII de PL, la ruta de cámara MIPI, DDR4 de PL, procesamiento de video, ni las interfaces RGB/táctil de la AN970. El Ethernet que se probó es GEM3 del PS, no el MAC de Ethernet de la PL.

Se comprobó experimentalmente que la salida constante 0 deja la fan a máxima velocidad y la constante 1 la apaga. El bitstream nuevo implementa `axi_pwm` en `0xA0000000`; el BOOT.BIN con FSBL/PS init actual arranca y permite que Linux acceda por UIO. El servicio térmico está habilitado: a unos 30 °C reportó `DUTY=0` y la fan se detuvo. La curva solicitada (arranque a 40 °C, rampa hasta 100 % a 60 °C) está implementada en software, pero sus valores intermedios aún requieren validación física. El circuito no expone tacómetro: mostramos porcentaje PWM solicitado, no RPM reales.

## AMD EDF y Vivado

- **Vivado usado para la base comprobada:** 2026.1.
- **Imagen Linux usada:** AMD Embedded Development Framework (EDF) 26.06, imagen oficial para Cortex-A53/Mali.
- **Firmware de arranque:** `BOOT.BIN` generado para el hardware AXU3EG a partir de fuentes EDF fijadas al manifest `amd-edf-rel-v26.06.1`.
- **Adaptación de la imagen:** se incorporó el `BOOT.BIN` específico de la placa a la partición EFI de la imagen oficial; se mantuvieron el kernel, rootfs, UUID y la opción de arranque predeterminada de EDF Linux.
- **Compilación local:** no se afirma que se haya completado una reconstrucción íntegra de Linux desde fuentes. La placa arrancó usando la imagen oficial AMD preparada con el firmware propio de la placa.
- **Vivado/EDF 2026.2:** pendiente de instalación, migración y validación. No asumir compatibilidad hasta construir y probar un bitstream y una imagen de arranque con esa versión.

La versión de la distribución EDF y la versión de Vivado son identificadores distintos: EDF 26.06 es la versión de la distribución usada; Vivado 2026.1 es la versión usada para generar la base de hardware. Para desarrollar hardware personalizado con EDF, el bitstream, el handoff/XSA, la descripción del sistema y el firmware de arranque deben corresponder al mismo diseño.

## Instalación

Los pasos para instalar Vivado, preparar las fuentes EDF, grabar la microSD y hacer la primera comprobación están en [`INSTALLATION.md`](INSTALLATION.md). AMD no admite WSL como host de compilación para EDF 26.06; en WSL se validaron partes del entorno, pero no terminó una reconstrucción completa de Linux.

## Primer periférico: pantalla táctil AN970

La AN970 es un módulo LCD táctil capacitivo de 7 pulgadas, resolución 800×480 y entrada RGB de 24 bits. ALINX documenta un experimento de pantalla AN970 para AXU3EG. La placa tiene encabezados de expansión de 40 pines; el conector P4 de la pantalla está pensado para conectarse a un encabezado ALINX compatible. La asignación final debe comprobarse contra el manual de la revisión exacta de la placa y el pin 1 antes de alimentar.

Secuencia propuesta:

1. Crear una copia de trabajo del proyecto Vivado y revisar los tiempos RGB del manual AN970.
2. Implementar y simular un generador de video 800×480 con barras de color y control del backlight.
3. Ejecutar DRC, síntesis e implementación en la versión de Vivado seleccionada.
4. Probar temporalmente el bitstream por JTAG con la placa apagada durante el cableado, conservando intacta la microSD de arranque conocida.
5. Agregar y validar la entrada táctil I²C e interrupción.
6. En una etapa posterior, conectar la salida de video con la cámara MIPI AN5641.

**Estado de la AN970:** aún no probada en la placa. No hay un bitstream de barras de color ni soporte Linux/táctil listo en esta base.

La documentación de ALINX también enumera una ruta de captura MIPI con el módulo de cámara AN5641. La compatibilidad del ejemplo con el hardware local y Vivado 2026.1/2026.2 debe verificarse antes de reutilizarlo.

## Otros módulos del kit

Se identificaron los nombres AN9238, AN706, AN9767 y la cámara AN5641 como posibles pruebas futuras. Su interfaz, alimentación, asignación de pines y ejemplos de referencia se deben confirmar individualmente con el manual de cada módulo. Que el proyecto Vivado original tenga bloques relacionados no confirma que el módulo esté conectado o funcionando en el bitstream EDF actual.

## Control PWM de la fan

El proyecto reproducible, BOOT.BIN, XSA, IP AXI, overlay Device Tree, servicio y notas de validación están en [`hardware/fan-control-stage2/README.md`](hardware/fan-control-stage2/README.md). El repo incluye el Python actualizado con impulso de arranque al iniciar y al salir del estado apagado; ese último cambio todavía debe copiarse a la placa para quedar sincronizado con la versión publicada.

La bitácora completa de la automatización, con pasos, comandos, salidas de terminal y código, está en [`docs/Bitacora_PWM_Fan_AXU3EGB_2026-10-24.pdf`](docs/Bitacora_PWM_Fan_AXU3EGB_2026-10-24.pdf).

## Próximo proyecto guiado: ventilador y monitor en la AN970

El plan de estudio para medir temperaturas, añadir control PWM seguro y preparar un panel tipo `htop` para la pantalla está en [`docs/plan-control-fan-monitor.md`](docs/plan-control-fan-monitor.md). Separa las mediciones reales (CPU, RAM, red y temperaturas) de las que requieren hardware adicional (watts y RPM).

## Verificación desde Linux

Ejecutar los comandos por separado en una terminal Linux o por SSH:

```sh
lscpu
free -h
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS
ip -br address
systemctl --failed --no-pager
```

Para leer las temperaturas expuestas por `hwmon`:

```sh
for f in /sys/class/hwmon/hwmon*/temp*_input; do
    [ -r "$f" ] || continue
    printf '%s: ' "$f"
    awk '{printf "%.1f °C\n", $1 / 1000}' "$f"
done
```

El kernel puede reportar servicios opcionales fallidos, por ejemplo una espera de red durante el arranque. Revisar cada unidad por separado antes de considerarla un problema de hardware.

## Descarga de la imagen EDF

La imagen WIC adaptada para AXU3EG se va a compartir en la [carpeta de OneDrive](https://1drv.ms/f/c/c153ffb3571b5ab8/IgD8ozVjlK9xR7iuHMOohfT8AUykfKEdCnq35IGSLgh_6Ew?e=mqqHaI) cuando termine de subirse. El archivo ocupa varios GB y por eso no se almacena en GitHub.

## Uso de imágenes y licencias

El WIC/rootfs se comparte desde la carpeta de OneDrive indicada arriba; las descargas de AMD, licencias, claves, credenciales y salidas generadas de Vivado/Yocto no se distribuyen en este repositorio. Antes de publicar fuentes HDL, IP empaquetada o binarios, revisar las licencias de AMD/Xilinx, ALINX y de los autores originales. Mantener atribuciones y enlaces a los repositorios de referencia.

La imagen original de PetaLinux 2020 y los proyectos Vivado 2023.2 se conservan como referencias separadas; no se sobrescribieron con la base EDF.

## Referencias

- [Documentación de hardware personalizado de AMD EDF 26.06](https://edf.docs.amd.com/en/v26.06/hwdev/custom-hardware-development.html)
- [Descargas y notas de AMD EDF 26.06](https://edf.docs.amd.com/en/v26.06/downloads-and-release-notes.html)
- [Manual de usuario AN970](https://alinx.com/public/upload/file/AN970_User_Manual.pdf)
- [Manual de usuario AXU3EG](https://alinx.com/public/upload/file/AXU3EG_User_Manual.pdf)
- [Lista de tutoriales AXU3EG de ALINX](https://github.com/fpgauk/axu3eg/blob/main/docs/AXU3EG_Tutorial_List.md)
- [Proyecto Vivado/PetaLinux 2023.2 AXU3EG de referencia](https://github.com/Nero7991/zcu106-2023.2-axu3eg)

---

## English summary

This repository tracks AMD EDF bring-up and Vivado experiments for an ALINX AXU3EG/AXU3EGB. The tested bring-up used **Vivado 2026.1** and the official **AMD EDF 26.06** image. Linux booted from microSD; UART, four Cortex-A53 cores, 4 GiB installed DDR, PS GEM3 Ethernet/SSH, and SoC temperatures were observed. The PL contains an AXI PWM controller for the fan at `0xA0000000`. The BOOT.BIN and UIO overlay booted; systemd read temperatures and stopped the fan at about 29–30 °C. The software curve from 40 °C to 60 °C and the 30% minimum still need physical validation. The latest Python start-kick update is in the repository but has not yet been deployed to the board. The active PL design does not include the AN970 display, AN5641 camera path, or full 2023.2 TRD peripherals. Vivado/EDF 2026.2 remains future work.



## Documentación de placa y pinout

La recopilación de guías, PDFs, manuales y tablas de pines está en [`docs/`](docs/README.md). La lámina de Vivado/XDC (6000 × 6500 px) muestra J45/J46 completos, AN970 P4 y las señales PL principales con sus package pins.
