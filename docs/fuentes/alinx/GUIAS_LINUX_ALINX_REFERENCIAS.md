# Guías Linux de ALINX: referencias y adaptación al EDF actual

Estas notas resumen las tres guías Markdown que ALINX publica en [`linux/documents_EN`](https://github.com/alinxalinx/AXU2CG-E_AXU3EG_AXU4EV-E_AXU5EV-E/tree/master/linux/documents_EN). Los documentos originales y sus imágenes permanecen en el repositorio oficial; esta página los enlaza y explica qué partes aplican a nuestra AXU3EGB.

## Documentos oficiales

1. [Arrancar Linux desde una tarjeta SD](https://github.com/alinxalinx/AXU2CG-E_AXU3EG_AXU4EV-E_AXU5EV-E/blob/master/linux/documents_EN/make_sd_for_runnging_linux.md)
2. [Uso de interfaces y periféricos desde Linux](https://github.com/alinxalinx/AXU2CG-E_AXU3EG_AXU4EV-E_AXU5EV-E/blob/master/linux/documents_EN/use_peripherals_interfaces.md)
3. [Crear Linux con PetaLinux](https://github.com/alinxalinx/AXU2CG-E_AXU3EG_AXU4EV-E_AXU5EV-E/blob/master/linux/documents_EN/use_petalinux_to_make_linux.md)

El repositorio de ALINX describe una familia de placas (AXU2CG-E, AXU3EG, AXU4EV-E y AXU5EV-E). La página de PetaLinux exige las herramientas **2020.1**; son referencias históricas de esa plataforma, no instrucciones para instalar AMD EDF 26.06 ni para regenerar el arranque actual con Vivado 2026.1.

## Qué aporta para estudiar

- La guía de SD explica el flujo Linux antiguo: partición FAT de arranque, partición ext4 de rootfs, archivos BOOT.bin/image.ub/boot.scr y consola serie a 115200 baudios. Para aquel sistema indica usuario/contraseña inicial `root`/`root`.
- La guía de periféricos recorre PS_UART y PL_UART, RS485, CAN, cámara MIPI, LEDs/botones, Ethernet PS/PL, USB, M.2, eMMC, EEPROM, QSPI, RTC y sensor LM75. Es útil para entender qué dispositivos esperaba exponer el Linux de demostración de ALINX.
- Su ejemplo de cámara muestra AN5641 por MIPI y salida de video por DisplayPort. Eso no es el panel RGB AN970 que queremos probar: la AN970 usa P4 de 40 pines y señales RGB/táctiles en J45.
- La guía de PetaLinux cubre crear y compilar proyectos 2020.1, incluido uso de paquetes offline. Sirve para comparar el flujo Yocto/PetaLinux de esa época, no como receta para EDF.

## Diferencias con la placa y el sistema que arrancamos

La microSD actual arranca la imagen completa AMD EDF 26.06 (`.wic`) con un bitstream mínimo generado en Vivado 2026.1. En la placa se observó `mmcblk0` como microSD con `/` montado y `mmcblk1` como eMMC sin montar. Por eso, no asumir la numeración de dispositivos de los ejemplos ALINX.

La interfaz de Ethernet observada fue `end0`, no `eth0`/`eth1`. El nombre del dispositivo depende del sistema; identificarlo con `ip -br address`. El bitstream actual tampoco activa el diseño completo de PL: la existencia de instrucciones para PL_UART, RS485, CAN, Ethernet PL o MIPI no prueba que estén disponibles en el EDF actual. Primero hace falta integrar y validar esas interfaces en Vivado, firmware y device tree.

Los ejemplos Linux de la guía usan dispositivos, GPIO heredado por sysfs, nodos de video, usuarios y paquetes del rootfs de ALINX. No copiar sus rutas o números GPIO sin comprobarlos en el EDF actual. En particular, la guía recomienda usuarios `root`/`root`, usa nombres de interfaz fijos y menciona un rootfs de su demo; no se deben aplicar esas credenciales/configuraciones al sistema arrancado.

## Operaciones que requieren especial cuidado

La guía contiene ejemplos de `fdisk`, `mkfs`, `flash_erase` y `dd` sobre almacenamiento. Pueden borrar particiones, eMMC o QSPI. No ejecutar esos comandos en esta placa siguiendo la guía antigua: la microSD actual aparece como `mmcblk0`, mientras que allí el ejemplo de eMMC también usa `mmcblk0`. Conservar la microSD que arranca y no escribir eMMC/QSPI durante las pruebas de AN970.

## Relación con la pantalla AN970

La ruta de pantalla de la guía Linux usa DisplayPort como salida de video para mostrar la cámara MIPI. No implementa el panel AN970. Para nuestra prueba, el siguiente trabajo es un diseño Vivado separado que genere RGB 800×480 hacia J45, primero con barras de color; después se probarán el backlight y el táctil. El mapa P4↔J45 de este repositorio sigue pendiente de prueba física.

**Fuente y atribución:** documentación publicada por ALINX en el repositorio enlazado arriba. Los textos originales no se vuelven a publicar aquí; se conservan sus enlaces para acceder a ellos con sus imágenes y contexto.
