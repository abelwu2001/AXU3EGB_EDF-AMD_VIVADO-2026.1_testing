# AXU3EGB fan PWM — Vivado 2026.1 + AMD EDF 2026.1

## Estado

Se generó un `BOOT.BIN` nuevo para el diseño de Vivado con PWM en `0xA0000000` y reloj PL0 de 99.999001 MHz. El paquete incluye FSBL, PMU firmware, bitstream, ATF, Device Tree base y U-Boot. El FSBL/PS init corresponde al hardware actual y configura los puentes necesarios para que el PS pueda acceder a la PL.

EDF genera a propósito el Device Tree base sin los periféricos PL y entrega su descripción en un overlay separado. Por eso el arranque del servicio aplica el overlay PL completo (reloj, puente AXI y PWM) y luego enlaza el PWM con UIO. El overlay de Linux no recarga el bitstream: ese ya viene dentro de BOOT.BIN.

La compilación `bitbake xilinx-bootbin` terminó correctamente; todas las tareas finalizaron. BitBake informó 99 warnings no fatales de planificación de tareas diferidas. El SHA-256 del bitstream dentro de BOOT.BIN coincide con el bitstream fuente de Vivado/SDT: `6220c077b5b2e3c6ee10243e7197332193f04ba7d1726eb1613e393b8d751d25`. El `psu_init.c` usado para el arranque también coincide con el SDT actual: `aa824df4de5f74de6c0f884094bef2f5836847671f3c85bd1978839aad83ff0b`.

El overlay runtime final se compiló y se combinó con el DTB de este BOOT.BIN usando las herramientas de Device Tree del build. La combinación produjo `/axi/axi_pwm@a0000000`, con `compatible = "xlnx,axi-pwm-1.0"`, y no contiene `firmware-name` que ordene una segunda carga de bitstream.

**Falta probar el arranque en la placa.** Los scripts de ventilador están preparados, pero aún no instalados ni activados en Linux; no afirmamos todavía que el control automático funcione en hardware.

## Archivos

- `BOOT_fan_pwm_2026-10-24.bin`: imagen lista para copiar como `/efi/boot.bin` en la microSD.
- `BOOT_fan_pwm_2026-10-24.manifest.json`, `.bif`, `bitbake-xilinx-bootbin.log`: manifiesto, lista de particiones y log de compilación.
- `pl-fan-pwm-generated.dtsi`, `pl-fan-pwm-generated.dtso`: descripción original generada por SDT.
- `software/fan-control/`: overlay runtime final, servicio systemd y controlador Python.
- `SHA256SUMS.txt`: huella para verificar la imagen BOOT.BIN.

## Paso 1: instalar el nuevo arranque

1. Deja conectado el UART y mira la IP de Linux con `ip -br address`.
2. En PowerShell de Windows, copia BOOT.BIN a la placa. Cambia `192.168.100.X` por la IP actual:

   ```powershell
   scp "Z:\AXU3EG_ORDENADO\AXU3EG_EDF_2026_1_VERSION2023_REFERENCIA\hardware\fan-control-stage2\BOOT_fan_pwm_2026-10-24.bin" amd-edf@192.168.100.X:/tmp/BOOT_fan_pwm.bin
   ```

3. En Linux por SSH o UART, conserva el arranque anterior, copia el nuevo y verifica el hash:

   ```sh
   sudo cp -a /efi/boot.bin /efi/boot.bin.pre-fan-pwm
   sudo cp /tmp/BOOT_fan_pwm.bin /efi/boot.bin
   sync
   sha256sum /efi/boot.bin
   ```

   El resultado esperado es `9a41c75cf524e77d2d7aa4d97711f02b906d3af7fd0d9a4d6c06608938a910d9`.

4. Mantén abierto el monitor UART y reinicia la placa desde la SD. JTAG puede quedar conectado, pero **no pulses Program Device**: queremos comprobar que BOOT.BIN carga por sí solo PS y PL.
5. Cuando Linux vuelva, confirma que hay red, memoria normal y que no se reinicia:

   ```sh
   ip -br address
   free -h
   cat /sys/class/fpga_manager/fpga0/state
   ```

   En este punto puede que `axi_pwm@a0000000` todavía no aparezca: el servicio aplicará el overlay después. No es un error en esta primera comprobación.

### Reversión del arranque

Si el nuevo arranque falla, inicia Linux como puedas y restaura el respaldo:

```sh
sudo cp -a /efi/boot.bin.pre-fan-pwm /efi/boot.bin
sync
```

## Paso 2: instalar y encender el control de fan

Hazlo solo después de confirmar que el nuevo BOOT.BIN arranca y Linux queda estable.

Desde PowerShell, copia los cuatro archivos finales a `/tmp` (usa la IP actual):

```powershell
$ip = "192.168.100.X"
$sw = "Z:\AXU3EG_ORDENADO\AXU3EG_EDF_2026_1_VERSION2023_REFERENCIA\hardware\fan-control-stage2\software\fan-control"
scp "$sw\fan-pwm-control.py" "amd-edf@${ip}:/tmp/"
scp "$sw\fan-pwm-uio-setup.sh" "amd-edf@${ip}:/tmp/"
scp "$sw\fan-pwm-device-tree.dtso" "amd-edf@${ip}:/tmp/"
scp "$sw\fan-pwm.service" "amd-edf@${ip}:/tmp/"
```

Luego en Linux instala archivos y arranca el servicio:

```sh
sudo install -d /etc/fan-pwm /usr/local/sbin
sudo install -m 755 /tmp/fan-pwm-control.py /usr/local/sbin/fan-pwm-control.py
sudo install -m 755 /tmp/fan-pwm-uio-setup.sh /usr/local/sbin/fan-pwm-uio-setup.sh
sudo install -m 644 /tmp/fan-pwm-device-tree.dtso /etc/fan-pwm/fan-pwm-device-tree.dtso
sudo install -m 644 /tmp/fan-pwm.service /etc/systemd/system/fan-pwm.service
sudo systemctl daemon-reload
sudo systemctl enable --now fan-pwm.service
sudo systemctl status fan-pwm.service --no-pager
journalctl -u fan-pwm.service -n 30 --no-pager
```

`enable --now` significa «arrancarlo ahora y también en futuros arranques». El log debe mostrar el UIO en `0xA0000000`, las temperaturas y el porcentaje PWM calculado. A temperatura ambiente cercana a 30 °C, dará una patada inicial de dos segundos al 100 % y después lo apagará. Al detener el servicio con `sudo systemctl disable --now fan-pwm.service`, el programa deja la fan solicitada al 100 % por seguridad.

## Curva de temperatura

- Temperatura medida: se leen `Temp_LPD`, `Temp_FPD` y `Temp_PL`; se elige la más alta.
- Debajo de 38 °C: PWM apagada.
- Al llegar a 40 °C: empieza a girar, con mínimo inicial de 30 %.
- Entre 40 °C y 60 °C: sube linealmente desde 30 % hasta 100 %.
- Desde 60 °C: 100 %.
- Si faltan lecturas de temperatura: se solicita 100 % como modo seguro.
- La diferencia entre 38 °C y 40 °C es histéresis: evita que la fan prenda/apague repetidamente si la temperatura fluctúa cerca del umbral.

El PWM es de unos 25 kHz (`4000` ciclos a `99.999001 MHz`). La salida de la placa es activa en bajo. El mínimo de 30 % es una primera estimación: hay que observar que la fan arranque y no se detenga ahí. El cableado documentado no expone tacómetro, así que Linux sabe qué porcentaje ordenó, pero no los RPM reales.

## Conceptos, en simple

- **PS**: los núcleos Cortex-A53 que ejecutan EDF/Linux.
- **PL**: la lógica programable FPGA; aquí vive el bloque `axi_pwm`.
- **AXI**: el bus por el que Linux escribe registros del PWM.
- **FSBL / PS init**: configura al arrancar relojes, DDR y puentes PS↔PL. Programar el bitstream por JTAG configura PL, pero no reemplaza toda esa preparación del procesador.
- **Device Tree**: el mapa del hardware que Linux usa para saber qué periféricos existen y sus direcciones.
- **Overlay**: un fragmento que se suma al Device Tree base al iniciar el servicio; describe el reloj, el puente AXI y el PWM de esta PL.
- **UIO**: interfaz del kernel que permite mapear los registros del PWM a un programa de usuario de forma identificada, sin abrir `/dev/mem` a ciegas.
- **BOOT.BIN**: paquete de arranque que reúne FSBL, PMU firmware, bitstream, ATF, Device Tree y U-Boot según el BIF.