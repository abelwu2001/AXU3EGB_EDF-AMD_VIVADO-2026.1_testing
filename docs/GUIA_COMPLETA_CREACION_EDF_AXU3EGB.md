# AXU3EGB: de Vivado a AMD EDF, paso a paso

Esta guía reconstruye el trabajo realizado en octubre y noviembre de 2026 usando los scripts, resultados y registros conservados. Está escrita para entender el proceso y repetirlo, indicando qué se comprobó y qué queda pendiente. Algunos archivos de preparación no están publicados en el repositorio: se identifican explícitamente. Una guía no sustituye las instrucciones y requisitos de AMD para la versión elegida.

## 1. Qué se construyó y qué arrancó

| Elemento | Resultado documentado |
|---|---|
| Placa | ALINX AXU3EG/AXU3EGB, Zynq UltraScale+ `xczu3eg-sfvc784-1-e`, 4 GiB DDR configurados |
| Herramientas | Vivado 2026.1; EDF 26.06; fuentes Yocto fijadas a `amd-edf-rel-v26.06.1` |
| Host usado | Windows con Ubuntu 24.04 en WSL. AMD no lo declara host soportado para EDF 26.06; usar Ubuntu nativo o contenedor compatible para repetir |
| Hardware base | PS, DDR, UART0, SD, Ethernet GEM3 y salida fija de fan. Proyecto posterior con PWM, AN970 y métricas |
| Firmware | `xilinx-bootbin` se compiló para `MACHINE=axu3eg-ps`; BOOT.BIN propio incorporado a la imagen de disco |
| Linux que arrancó | **Imagen oficial EDF 26.06 adaptada** con BOOT.BIN de la placa. El build completo local del rootfs desde fuentes no terminó |
| Validación física | Arranque por SD, UART y SSH, cuatro Cortex-A53, unos 3,8 GiB utilizables, fan automática y monitor AN970 funcionando |
| Cámara AN5641 | Trabajo en curso. El bitstream con interrupciones fue implementado; aún no se validó captura de imagen ni integración Linux completa |

En el host local el árbol de trabajo terminó bajo `Z:\AXU3EG_ORDENADO\AXU3EG_EDF_2026_1_VERSION2023_REFERENCIA`. Los scripts históricos usan la ruta anterior `Z:\AXU3EG_EDF_2026_1` y su equivalente `/mnt/z/AXU3EG_EDF_2026_1`: **hay que adaptar esas rutas antes de repetirlos**. Las rutas, letras de unidad y nombres de usuario son ejemplos, no propiedades de la placa.

## 2. Cómo encajan las piezas

1. **Vivado** describe el hardware: el PS, sus pines, memoria y la lógica PL. Produce `.bit` y `.xsa`.
2. **XSA** entrega la descripción de hardware; puede incluir el bitstream. El **XDC** contiene restricciones de pines y tiempos y es una pieza distinta.
3. **SDTGen** convierte el XSA y los ajustes de placa en un System Device Tree (SDT). `gen-machine-conf` transforma esa descripción en configuración de máquina para EDF/Yocto.
4. **Yocto/BitBake** construye componentes: para la placa, `xilinx-bootbin`; opcionalmente, una imagen completa Linux.
5. El **BOOT.BIN** contiene firmware de arranque y, en este flujo, un bitstream. La imagen **WIC** contiene particiones y el sistema Linux. Se colocó el BOOT.BIN propio en la partición de arranque de una copia de la imagen oficial.
6. Linux utiliza el **device tree** para conocer hardware. Después, servicios de systemd controlan la fan y actualizan las métricas. Los overlays posteriores describen dispositivos de PL; no son por sí mismos el programa PWM ni el bitstream.

## 3. Preparación de herramientas y fuentes

Instalar Vivado 2026.1 con soporte Zynq UltraScale+ MPSoC y controladores JTAG si se usan. En Tcl, verificar:

```tcl
version -short
```

Preparar Linux y el espacio según [requisitos EDF](https://edf.docs.amd.com/en/v26.06/downloads-and-release-notes.html). El trabajo original guardó el build de Yocto en el filesystem de WSL; la disponibilidad de espacio real depende del disco que contiene su VHDX. El proyecto utilizó cuatro tareas y `rm_work` para reducir el consumo de espacio. Las licencias de IP, claves y credenciales no deben subirse al repositorio.

Para obtener las fuentes fijadas, siguiendo la guía EDF y adaptando las rutas:

```bash
mkdir -p "$HOME/bin" "$HOME/fpga/axu3eg-edf-26.06/yocto"
curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o "$HOME/bin/repo"
chmod +x "$HOME/bin/repo"
export PATH="$HOME/bin:$PATH"
cd "$HOME/fpga/axu3eg-edf-26.06/yocto"
repo init -u https://github.com/Xilinx/yocto-manifests.git \
  -b refs/tags/amd-edf-rel-v26.06.1 -m default-edf.xml
repo sync
source edf-init-build-env
```

La captura exacta de revisiones del trabajo se guardó localmente en `linux/manifest-locked.xml`; el tag por sí solo no reemplaza ese manifiesto. No se incluye aquí una lista inventada de paquetes del host: consultar la documentación AMD de esa versión.

## 4. Hardware base en Vivado

Se creó una base independiente, sin el TEMAC del diseño anterior que requería licencia. La configuración PS/DDR/MIO se heredó de un diseño AXU3EG previo; debe verificarse frente al esquemático y la revisión física de cada placa antes de generar firmware. El script histórico `create_hardware.tcl`:

1. Comprueba Vivado 2026.1 y crea el proyecto `axu3eg_base` para `xczu3eg-sfvc784-1-e`.
2. Crea el Block Design `base` y un Zynq UltraScale+ MPSoC llamado `ps`.
3. Aplica `hardware/ps_config_original.tcl`, extraído del diseño de referencia. En la base inicial desactiva interfaces PL no usadas; no se debe copiar esa desactivación a diseños posteriores sin revisar.
4. Valida, guarda y genera productos del BD; crea `base_wrapper` y lo selecciona como top.
5. El script posterior agrega una constante de un bit a `fan_on_n`, con nivel bajo, y el XDC de placa; valida, sintetiza, implementa y genera el `.bit`.
6. Con el diseño implementado exporta un XSA incluyendo el bitstream. Se verificaron DRC y timing del diseño base.

El XDC de la base asignaba `fan_on_n` a `AA11` con `LVCMOS33`. El PWM posterior usa el mismo pin pero lógica distinta. No asumir que los puertos de pantalla o cámara están incluidos en la base mínima. La referencia completa de placa, `ps_config_original.tcl`, no está incluida en este repositorio; por ello un clon limpio **no reproduce de cero esa configuración exacta**. El proyecto PWM y sus fuentes posteriores sí se encuentran en [`hardware/fan-control-stage2`](../hardware/fan-control-stage2/README.md).

En interfaz gráfica, después de editar el BD: **Validate Design → Save → Generate Output Products → Generate Bitstream**. `Out-of-date` significa que hay que reconstruir las etapas afectadas; `Force up-to-date` no recompila. Comprobar errores, DRC y timing antes de exportar **File → Export Hardware → Include bitstream**. Un WNS positivo no demuestra que las interfaces sin restricciones externas estén verificadas.

## 5. Generar SDT y configuración EDF

En Windows, con XSA y DTS de placa ya preparados, el comando usado fue conceptualmente:

```powershell
& 'Z:\FPGA\2026.1\Vivado\bin\sdtgen.bat' `
  -xsa 'Z:/AXU3EG_EDF_2026_1/handoff/axu3eg_base.xsa' `
  -dir 'Z:/AXU3EG_EDF_2026_1/handoff/sdt-final' `
  -user_dts 'Z:/AXU3EG_EDF_2026_1/linux/axu3eg-board.dtsi'
```

El DTS local identificaba `alinx,axu3eg`, UART0 a 115200, GEM3 con PHY MDIO dirección 0, SDHCI1 con `disable-wp` y `no-1-8-v`. El reloj PSS generado se comprobó en 33,333 MHz frente al diseño heredado. Estos datos pertenecen a esa placa/configuración, no son universales.

En Ubuntu, desde el árbol Yocto, el script histórico hacía lo siguiente una vez inicializado el entorno (sustituir la ruta local de SDT):

```bash
YOCTO="$HOME/fpga/axu3eg-edf-26.06/yocto"
cd "$YOCTO"
source edf-init-build-env
mkdir -p "$YOCTO/../hardware/sdt"
cp -a /mnt/z/AXU3EG_EDF_2026_1/handoff/sdt-final/. "$YOCTO/../hardware/sdt/"
gen-machine-conf parse-sdt --hw-description "$YOCTO/../hardware/sdt" \
  --machine-name axu3eg-ps --soc-family zynqmp
```

Atención: `edf-init-build-env` puede cambiar el directorio actual. Verificar con `pwd` las rutas efectivas de SDT y `conf` antes de ejecutar. El resultado local incluyó `conf/machine`, `conf/multiconfig` y `conf/dts`. La configuración histórica activó `BIF_BITSTREAM_ATTR:axu3eg-ps = "bitstream"` para incluir el bitstream de la base; el contenido exacto generado para la máquina debe revisarse junto con el XSA correspondiente.

## 6. BOOT.BIN específico y WIC oficial

Dentro del entorno Yocto configurado, el comando de firmware fue:

```bash
MACHINE=axu3eg-ps bitbake xilinx-bootbin
```

El resultado estaba en `build/tmp/deploy/images/axu3eg-ps/boot.bin`. El firmware base comprobado tenía SHA-256 `7be2b091d405585cb1bbee27ecac6c5a94f694e291658f27010ccb1e111d5594`; este hash identifica **ese archivo histórico**, no todos los firmware posteriores. La composición registrada incluye FSBL, firmware PMU, bitstream PL, TF-A, DTB y U-Boot. Las direcciones y atributos reales deben extraerse del BIF generado para la versión y placa utilizadas.

Se intentó también:

```bash
MACHINE=amd-cortexa53-mali-common bitbake edf-linux-disk-image
```

Hubo interrupciones, cachés vacías y fallos de dependencias; no se obtuvo un rootfs completo local validado. La solución usada fue descargar la **imagen oficial EDF 26.06 para Cortex-A53/Mali** de AMD, descomprimir una copia y sustituir el `boot.bin` de su partición EFI por el firmware de la placa. El script histórico usó `mcopy` con offset `@@32768`, que solo es válido para **esa imagen y geometría**. Antes de aplicarlo a otra imagen, inspeccionar sus particiones; no usar ese offset a ciegas. La imagen de entrada y el WIC final no están en este repositorio.

Las comprobaciones del archivo final incluyeron tabla híbrida MBR/GPT, particiones, PARTUUID de raíz, cargador EFI y kernel ARM64, BOOT.BIN incorporado, consistencia ext4 y presencia de usuario `amd-edf` y systemd. El WIC histórico resultante tenía SHA-256 `7aaa3de569a5fd6e195f52f2214472eacc88e3faa906380bb156f03b2c8aa74a`. Los scripts originales de empaquetado usan rutas absolutas locales y dependen de artefactos externos; no basta con clonar este repositorio para reproducir ese WIC.

## 7. microSD y primer arranque

1. Verificar el SHA-256 de los archivos que se van a utilizar, comparándolo con su manifiesto. Grabar el WIC completo en una microSD de prueba de al menos 16 GB: **se borra la unidad elegida**. Conservar una tarjeta de recuperación.
2. Con la placa apagada, seleccionar el modo SD según el manual de su revisión. Conectar alimentación y UART; abrir consola **115200, 8N1, sin control de flujo**.
3. Encender, guardar la salida desde el arranque, elegir EDF Linux si aparece menú y entrar con `amd-edf`, siguiendo el procedimiento de contraseña de la imagen utilizada.
4. Revisar una orden por vez:

```sh
uname -a
tr '\0' '\n' < /proc/device-tree/model
lscpu
free -h
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS
ip -br address
systemctl --failed --no-pager
```

Conectar Ethernet al puerto del PS y obtener la IP con `ip -4 -br address`. Desde Windows: `ssh amd-edf@DIRECCION_IP`. La IP puede cambiar entre reinicios. Se comprobó acceso por UART y SSH; no se escribió eMMC ni QSPI en esta primera puesta en marcha.

## 8. Fan PWM y pantalla AN970

Los pasos y archivos reales están en [fan PWM](../hardware/fan-control-stage2/README.md), [monitor AN970](../hardware/an970-linux-monitor-2026.1/README.md) y [comandos systemd](COMANDOS_SYSTEMD_Y_ARRANQUE.md). Resumen de la secuencia:

1. Se agregó el IP `axi_pwm` con mapa AXI en `0xA0000000` y rango 64 KiB; se compiló el bitstream y se preparó un BOOT.BIN con esa versión. Antes de reemplazar `/efi/boot.bin` se conservó una copia y se verificó el hash.
2. En Linux se compiló y aplicó un overlay que describe el PWM; `uio_pdrv_genirq` permitió mapear registros a través de UIO. Los números `/dev/uioN` pueden cambiar: identificar por dirección en `/sys/class/uio/uio*/maps/map0/addr`.
3. `fan-pwm-control.py` lee sensores LPD/FPD/PL y gobierna el PWM. Los registros observados fueron `CTRL=0x3`, `PERIOD=4000` y `DUTY` variable; durante el arranque real también se observó un impulso temporal al 100 %. Para conocer la curva y sus excepciones, leer el código del controlador publicado.
4. Se duplicó el proyecto, se generó el reloj de píxel, el módulo RGB y el XDC de AN970; se comprobaron barras de colores en pantalla. El contacto táctil **no está validado** por esa prueba.
5. Se añadió un IP AXI Lite para métricas en `0xA0010000` y un publicador Python: CPU, RAM, LPD/FPD/PL, PWM e IP. Las conexiones de siete registros a la lógica de pantalla y el formato deben coincidir en HDL y Python. Ver [código del monitor](../hardware/an970-linux-monitor-2026.1/software/linux-metrics-publish.py).
6. Windows convirtió el `.bit` a formato para FPGA Manager usando Bootgen `-process_bitstream bin`; se transfirió por `scp`, se compararon hashes y se guardó como `/lib/firmware/monitor.bit.bin`.
7. Se configuraron servicios con el orden `monitor-bitstream → fan-pwm → linux-metrics-publish`. El primer intento falló por expansión de `%s` dentro de `ExecStart`; se corrigió con `echo -n monitor.bit.bin` y `systemctl daemon-reload`. Tras un reinicio se comprobó funcionamiento.

Para **fan sola**, detener y deshabilitar el publicador; la fan continúa usando el mismo bitstream combinado:

```sh
sudo systemctl disable --now linux-metrics-publish.service
sudo systemctl enable monitor-bitstream.service fan-pwm.service
```

Para **fan y métricas**, habilitar y arrancar los tres:

```sh
sudo systemctl enable --now monitor-bitstream.service fan-pwm.service linux-metrics-publish.service
systemctl --no-pager --full status monitor-bitstream.service fan-pwm.service linux-metrics-publish.service
```

Estos comandos corresponden al montaje publicado, no seleccionan imágenes diferentes de FPGA. No ejecutar otro controlador que escriba al mismo PWM. Después de cambiar bitstream, confirmar que los periféricos y direcciones coincidan antes de que los servicios accedan a ellos. Reprogramar la PL con servicios activos puede interrumpirlos; no se debe hacer durante un DMA en curso.

## 9. Cámara AN5641: estado y trabajos pendientes

La cámara incorpora un OV5640 y usa MIPI de dos carriles. En una copia del proyecto se añadieron receptor CSI-2, AXI IIC, adaptador AXI Stream, Video Frame Buffer Write y acceso a DDR por HP1. El diseño sintetizó e implementó. Posteriormente se verificó que tres IRQ estaban desconectadas y se agregó `camera_irq_concat` conectando `camera_iic/iic2intc_irpt` a In0, `v_frmbuf_wr_0/interrupt` a In1 y `mipi_csi2_rx_subsyst_0/csirxss_csi_irq` a In2, con salida a `ps/pl_ps_irq0`. Se habilitó `CONFIG.PSU__USE__IRQ0`. El nuevo `.bit` se generó; el resumen de timing indicó WNS +2,493 ns y WHS +0,023 ns. También se exportó localmente `project/camara_irq.xsa`.

En el kernel instalado no estaba habilitado `CONFIG_VIDEO_OV5640`. Se encontró el código y `Module.symvers` del kernel correspondiente, se compiló `ov5640.ko` para `6.18.10-xilinx-g4f7afe14f724` y el usuario lo insertó temporalmente. Que el módulo cargue no significa que detecte una cámara. El bus observado `i2c-0` era el Cadence del PS; aún faltaba describir el AXI IIC y el sensor en device tree. Deben verificarse alimentación, reloj, reset, pines físicos, formato y grafo multimedia con la documentación y el hardware reales. El módulo recompilado debe coincidir con el kernel de destino.

Quedan sin demostrar: inicialización adecuada del PS/HP1 con el firmware real, asignación de interrupciones en Linux, DMA y buffers seguros, correspondencia YUV del flujo y memoria, recepción de cuadros, visualización y pantalla táctil. Igualar anchos de AXI Stream rellenando con ceros no convierte formatos de color. El warning de DCI/MIPI y los caminos sin restricciones externas requieren revisión antes de declarar validación completa. No instalar este diseño como servicio automático mientras falten esas pruebas.

## 10. Consultas y recuperación

```sh
systemctl is-active fan-pwm.service linux-metrics-publish.service
systemctl is-enabled monitor-bitstream.service fan-pwm.service linux-metrics-publish.service
systemctl cat fan-pwm.service
sudo journalctl -u fan-pwm.service -n 20 --no-pager
cat /sys/class/fpga_manager/fpga0/state
for d in /sys/class/uio/uio*; do
  [ -r "$d/maps/map0/addr" ] || continue
  printf '%s %s %s\n' "${d##*/}" "$(cat "$d/name")" "$(cat "$d/maps/map0/addr")"
done
```

`active` describe ahora; `enabled` el próximo arranque. Si un servicio cambió en disco, ejecutar `sudo systemctl daemon-reload` antes de probar. `operating` indica estado del FPGA Manager, pero no prueba cuál bitstream se cargó ni que cada periférico funcione. Para reemplazar firmware de arranque conservar y verificar primero una copia recuperable y acceso UART/SD.

## Fuentes y alcance

- [Guía del repositorio para instalación EDF](INSTALACION_EDF_VIVADO.md), [primera conexión](PRIMER_ARRANQUE.md) y [systemd](COMANDOS_SYSTEMD_Y_ARRANQUE.md).
- [AMD: hardware personalizado EDF](https://edf.docs.amd.com/en/v26.06/hwdev/custom-hardware-development.html) y [entorno Yocto](https://edf.docs.amd.com/en/v26.06/yocto/setting-up-the-yocto-environment.html).
- Proyecto AXU3EG de referencia: [Nero7991/zcu106-2023.2-axu3eg](https://github.com/Nero7991/zcu106-2023.2-axu3eg).

Los documentos locales históricos que dicen “falta prueba física” fueron escritos antes del arranque real posterior. Los valores y logs aquí señalados provienen de esos registros y de las pruebas compartidas; las acciones no registradas no se reconstruyen como hechos.

