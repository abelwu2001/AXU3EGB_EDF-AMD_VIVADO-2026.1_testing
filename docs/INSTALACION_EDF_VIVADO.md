# Instalacion y primera puesta en marcha

Esta guia separa la instalacion de Vivado, la preparacion del entorno AMD EDF y el primer arranque de la placa. La configuracion que arranco fisicamente fue **Vivado 2026.1 + imagen oficial AMD EDF 26.06**. El nombre de este repositorio menciona Vivado 2026.2 porque esa migracion es el proximo objetivo; no se debe tomar como version ya validada.

## 1. Instalar Vivado

1. Descarga el instalador oficial de AMD desde [Vivado Design Suite](https://www.amd.com/en/products/software/adaptive-socs-and-fpgas/vivado.html). Se requiere una cuenta AMD.
2. Para reproducir la base probada, instala **Vivado 2026.1** y selecciona soporte de dispositivos **Zynq UltraScale+ MPSoC**. El dispositivo de esta placa es `xczu3eg-sfvc784-1-e`.
3. Incluye los controladores de cable/JTAG si el instalador los ofrece y vas a programar o depurar la placa por JTAG.
4. Abre Vivado y confirma la version con `Help > About` o desde su consola Tcl:

   ```tcl
   version -short
   ```

No hace falta instalar Vitis solo para abrir y generar el hardware de esta base. Algunos IP de diseños mas completos pueden requerir licencias adicionales; cada usuario debe usar su propia licencia. No copies archivos `.lic`, claves ni datos de cuenta al repositorio.

Para probar Vivado 2026.2, instala esa version en paralelo y abre una copia del proyecto. Conserva la base validada de 2026.1 hasta completar la migracion, sintesis, implementacion y pruebas fisicas.

## 2. Preparar AMD EDF

### Opcion recomendada para compilar desde fuentes

AMD soporta para EDF 26.06 determinados hosts Linux, incluyendo Ubuntu 24.04.3 LTS nativo. AMD indica que Windows y WSL no son hosts soportados para compilar EDF 26.06. En este trabajo se uso Ubuntu 24.04 dentro de WSL para preparar y validar partes del entorno, pero la reconstruccion local completa de Linux no termino. Para una compilacion reproducible usa Ubuntu nativo compatible o el contenedor de build oficial de AMD.

En el host Linux, instala los paquetes requeridos siguiendo la [guia oficial de requisitos de EDF](https://edf.docs.amd.com/en/v26.06/downloads-and-release-notes.html). Luego configura `repo` y descarga las fuentes fijadas al release:

```sh
mkdir -p "$HOME/bin" "$HOME/fpga/axu3eg-edf-26.06/yocto"
curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o "$HOME/bin/repo"
chmod a+x "$HOME/bin/repo"
export PATH="$HOME/bin:$PATH"

git config --global user.name "Tu nombre"
git config --global user.email "tu-correo@example.com"

cd "$HOME/fpga/axu3eg-edf-26.06/yocto"
repo init -u https://github.com/Xilinx/yocto-manifests.git \
  -b refs/tags/amd-edf-rel-v26.06.1 -m default-edf.xml
repo sync
source edf-init-build-env
```

`repo sync` descarga numerosos repositorios y puede tardar y ocupar bastante espacio. El script de entorno inicializa el directorio de compilacion. Para los pasos actualizados y opciones de cache, consulta la [guia oficial de configuracion Yocto de EDF](https://edf.docs.amd.com/en/v26.06/yocto/setting-up-the-yocto-environment.html).

### Adaptar EDF al hardware AXU3EG

El proyecto de hardware, sus XDC/Tcl, la configuracion de placa y el `BOOT.BIN` deben corresponder entre si. La guia oficial de [desarrollo de hardware personalizado EDF](https://edf.docs.amd.com/en/v26.06/hwdev/custom-hardware-development.html) describe el flujo desde Vivado/XSA hasta la integracion de firmware y Linux.

Para esta placa, el handoff de Vivado se convierte en descripcion de sistema y configuracion de maquina EDF. En el trabajo local se uso `gen-machine-conf parse-sdt` con el SDT generado por Vivado y el nombre de maquina `axu3eg-ps`. Esa configuracion especifica aun no esta publicada en este repositorio, asi que estos pasos describen el metodo pero el repositorio por si solo todavia no permite reconstruir el `BOOT.BIN`.

La imagen WIC y `BOOT.BIN` generados no se guardan en GitHub. El WIC local tiene varios gigabytes y los archivos de distribucion de AMD no deben volver a publicarse sin revisar sus condiciones de redistribucion. El build Yocto completo desde fuentes tampoco se presenta como terminado.

## 3. Grabar la microSD y arrancar

Estos pasos requieren la imagen EDF adaptada a AXU3EG, que debe llevar el `BOOT.BIN` correcto en la particion EFI. La imagen oficial sin ese firmware de placa no se ha probado en la AXU3EG. El archivo WIC no esta incluido en este repositorio.

1. Usa una microSD de prueba de al menos 16 GB. **Grabar la imagen borra por completo la tarjeta seleccionada.** Conserva intacta la microSD anterior de PetaLinux.
2. Verifica el SHA-256 del WIC antes de grabarlo. En Windows:

   ```powershell
   Get-FileHash .\axu3eg-edf-2026.1.wic -Algorithm SHA256
   ```

   Compara el valor con el manifiesto publicado junto a la imagen por quien la distribuye.
3. En Rufus, selecciona cuidadosamente la microSD y el archivo `.wic`. Si pregunta por el modo de escritura, elige **DD Image mode**. Revisa dos veces que el destino sea la microSD de prueba, no otro disco.
4. Con la placa apagada, selecciona el modo de arranque desde SD segun el manual de la revision exacta de AXU3EG/AXU3EGB.
5. Conecta el USB-UART, abre una terminal serie a **115200 baudios, 8N1, sin control de flujo** y empieza a guardar el log antes de alimentar la placa.
6. Enciende y deja seleccionada la opcion predeterminada **EDF Linux**; no elijas Xen para esta primera prueba. Ingresa como `amd-edf`; el primer acceso local pide establecer una contrasena.
7. Conecta Ethernet al puerto del PS. La direccion se consulta en Linux; no asumas que la interfaz siempre se llama `eth0`.

No escribas QSPI ni eMMC para esta prueba. La eMMC de 29.6 GB se detecto en el sistema, pero no se monto ni se modifico.

## 4. Comprobar el sistema

Ejecuta estos comandos por separado en la consola serie o via SSH:

```sh
uname -a
tr '\0' '\n' < /proc/device-tree/model
lscpu
free -h
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS
ip -br link
ip -br address
systemctl --failed --no-pager
```

El arranque comprobado mostro cuatro Cortex-A53 AArch64, cerca de 3.8 GiB utilizables, microSD como raiz y `end0` activa con direccion IP. `systemd --failed` puede mostrar una unidad opcional fallida; inspeccionala individualmente antes de considerarla un fallo general.

Para leer temperaturas que Linux exponga por hwmon:

```sh
for f in /sys/class/hwmon/hwmon*/temp*_input; do
    [ -r "$f" ] || continue
    printf '%s: ' "$f"
    awk '{printf "%.1f °C\n", $1 / 1000}' "$f"
done
```

En la prueba compartida aparecieron lecturas cercanas a 29-30 °C. Sus nombres fisicos no se identificaron. El ventilador se oyo girar, pero el bitstream actual lo mantiene con la salida fija en bajo; no hay control automatico PWM.

## 5. Alcance de lo que hay en GitHub

Por ahora el repositorio contiene documentacion (`README.md` e `INSTALLATION.md`). No contiene el WIC, `BOOT.BIN`, la licencia Vivado, caches, ni los fuentes completos de hardware/Yocto. Por eso la guia permite entender e instalar las herramientas y documenta el primer arranque, pero una clonacion limpia todavia no reproduce por si sola toda la imagen probada. Las fuentes de proyecto publicables y sus instrucciones de build deben agregarse en una siguiente entrega, verificando licencias de IP de AMD/Xilinx y ALINX.

## Referencias oficiales

- [AMD Vivado Design Suite](https://www.amd.com/en/products/software/adaptive-socs-and-fpgas/vivado.html)
- [AMD EDF 26.06: hosts soportados y requisitos](https://edf.docs.amd.com/en/v26.06/downloads-and-release-notes.html)
- [AMD EDF 26.06: configurar el entorno Yocto](https://edf.docs.amd.com/en/v26.06/yocto/setting-up-the-yocto-environment.html)
- [AMD EDF 26.06: hardware personalizado](https://edf.docs.amd.com/en/v26.06/hwdev/custom-hardware-development.html)
- [Manual AXU3EG](https://alinx.com/public/upload/file/AXU3EG_User_Manual.pdf)
