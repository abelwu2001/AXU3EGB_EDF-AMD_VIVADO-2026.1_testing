# Primera prueba por consola

La imagen oficial EDF 26.06 adaptada ya paso las verificaciones del archivo. Usar `images/axu3eg-edf-2026.1.wic` con su `images/SHA256SUMS`. Falta comprobar el arranque fisico.

1. Grabar la imagen completa en una microSD de prueba de al menos 16 GB. Se borrará el contenido de esa tarjeta. Conservar la tarjeta PetaLinux 2020.
2. Seleccionar el modo SD con la placa apagada, según el manual de su revisión; conectar USB-UART y alimentación.
3. Abrir la consola serie: **115200, 8N1, sin control de flujo**. Guardar el log desde el encendido.
4. Comprobar que gira el ventilador y que aparecen las etapas de arranque, U-Boot y Linux. En algunos builds el FSBL imprime poco; no depender solo de su banner.
5. Dejar arrancar **EDF Linux**, la opcion predeterminada; no seleccionar Xen para esta prueba. Ingresar como `amd-edf`. El primer acceso local pide establecer contraseña.

Ejecutar en la consola Linux de la placa:

```sh
uname -a
tr '\0' '\n' < /proc/device-tree/model
lscpu
free -h
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS
ip -br link
ip -br address
sudo dmesg | tail -80
```

Se espera ver ARM aarch64/Cortex-A53 y el modelo `ALINX AXU3EG - EDF 2026.1 base`. Parte de los 4 GB configurados puede quedar reservada para firmware y otros usos. El nombre de Ethernet se consulta con `ip -br link`; no asumir que siempre se llama `eth0`.

Conectar el cable al puerto Ethernet del PS. El puerto que usa Ethernet en la PL no está implementado en esta base. Si no obtiene dirección, conservar las salidas de `ip` y los mensajes de `dmesg` antes de cambiar la configuración.

Si no aparece nada por UART, verificar primero el puerto COM, el cable USB-UART, alimentación y modo de arranque. Si U-Boot aparece pero Linux no, guardar el error completo. Si hay fallos de entrenamiento DDR o detección de memoria, contrastar la variante física con la configuración PS heredada del proyecto original.

No escribir QSPI ni eMMC durante esta primera prueba.
