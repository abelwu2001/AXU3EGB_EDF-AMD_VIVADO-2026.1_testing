# Control PWM de la fan y monitor de Linux

## Estado probado en la AXU3EGB (24-10-2026)

La placa arrancó desde la microSD con un BOOT.BIN creado para el diseño Vivado 2026.1 y AMD EDF 26.06. El proceso de arranque pasó por FSBL, cargó el bitstream y Linux volvió por UART/SSH. La huella del BOOT.BIN y los archivos de soporte están registrados en [`hardware/fan-control-stage2/README.md`](../hardware/fan-control-stage2/README.md).

Linux aplica un overlay Device Tree al iniciar el servicio, registra el PWM y lo ofrece a través de UIO. Se observó `uio4` con mapa `0x00000000a0000000`, tamaño `0x10000`. `fan-pwm.service` quedó habilitado y activo. El programa leyó `Temp_LPD`, `Temp_FPD` y `Temp_PL`; a unos 29–30 °C eligió la lectura mayor, ordenó `DUTY=0`, y la fan se detuvo físicamente.

Esto valida el arranque EDF con el diseño PWM, el mapeo UIO y el estado apagado. **Aún no valida físicamente el arranque a 30 %, ni la rampa completa de 40 a 60 °C.** No se calentó artificialmente el SoC para forzar la prueba.

## Qué hace cada bloque, en simple

- **PS**: los Cortex-A53 que ejecutan Linux.
- **PL**: la lógica de la FPGA. Allí está el bloque `axi_pwm`.
- **AXI-Lite**: el bus sencillo por el que el PS escribe los registros del PWM.
- **Device Tree**: el mapa que Linux consulta para encontrar hardware. EDF deja la descripción de PL en un overlay separado.
- **Overlay**: añade la descripción de reloj, puente AXI y PWM al árbol activo. El overlay preparado no contiene `firmware-name`, para no pedir una segunda carga de bitstream.
- **UIO**: interfaz del kernel que asigna al programa un mapa identificado del bloque hardware. En esta placa, la base es `0xA0000000`.
- **systemd**: inicia el script de overlay y luego el programa Python; `enable` hace que systemd lo repita en los siguientes arranques.

## Salida de fan y polaridad

La fan está conectada al circuito de transistor controlado por la señal `FAN_PWM`/AA11. En las pruebas con constantes, el valor lógico 0 hizo girar la fan a máxima velocidad y el valor 1 la detuvo. Por eso el PWM del diseño se invierte para esta salida activa en bajo. Esta observación de la placa prevalece sobre asumir la polaridad solo por el nombre del puerto.

No hay señal de tacómetro documentada en ese circuito. El programa conoce el ciclo útil que ordena, no la velocidad real en RPM.

## Registros del IP `axi_pwm`

El bloque está en `0xA0000000`, ocupa `0x10000` bytes y recibe PL0 a 99.999001 MHz. Sus registros usados por el programa son:

| Desplazamiento | Uso |
|---|---|
| `0x00` (`CTRL`) | bit 0 habilita PWM; bit 1 invierte la salida. `CTRL=3` activa ambas opciones. |
| `0x04` (`PERIOD`) | ciclos por período PWM. |
| `0x08` (`DUTY`) | ciclos activos de cada período. |

Con `PERIOD=4000`, la frecuencia es `99,999,001 / 4000 ≈ 25 kHz`. El porcentaje pedido se convierte en `DUTY = redondear(4000 × porcentaje / 100)`. Por ejemplo, 30 % equivale a 1200 y 100 % a 4000. La salida se invierte porque la señal de la placa es activa en bajo.

## Curva de temperatura que implementa el programa

Se leen las tres temperaturas AMS y se usa la más alta. Los nombres corresponden a sensores del SoC; no son temperatura ambiente ni temperatura medida en la fan.

| Temperatura máxima | Acción del programa |
|---|---|
| Por debajo de 38 °C | Fan apagada. |
| 38 a menos de 40 °C | Histéresis: si ya estaba girando, continúa al mínimo; si estaba apagada, sigue apagada. |
| 40 °C | Solicita 30 % después de un impulso de arranque a 100 % por dos segundos. |
| 40–60 °C | Rampa lineal: 30 % a 40 °C, 47.5 % a 45 °C, 65 % a 50 °C, 82.5 % a 55 °C y 100 % a 60 °C. |
| 60 °C o más | 100 %. |
| No hay sensores etiquetados | Modo seguro del programa: solicita 100 %. |

El programa da un impulso de dos segundos al iniciarse. La versión más nueva del archivo también lo da cuando la curva vuelve a encender la fan desde apagada. Esa mejora está en este repositorio, pero **todavía falta copiar esa versión actualizada al Linux de la placa y reiniciar el servicio**; la prueba en vivo mostrada arriba usó la versión anterior, que solo daba el impulso al iniciar el servicio.

El mínimo de 30 % aún es una estimación. Hay que verificar que la fan arranque y permanezca girando cuando esa orden se use. Si no arranca de forma confiable, se debe subir el mínimo antes de depender de la curva.

## Servicio Linux y comprobaciones

El servicio es `fan-pwm.service`. Comandos de lectura:

```sh
sudo systemctl status fan-pwm.service --no-pager
journalctl -u fan-pwm.service -n 30 --no-pager
cat /sys/class/fpga_manager/fpga0/state
cat /sys/class/uio/uio4/maps/map0/addr
```

En el log, una línea como `max=30.2C; fan=0.0%` indica lectura y orden calculada. `registers: CTRL=0x3 PERIOD=4000 DUTY=0` muestra los valores escritos, no una lectura de RPM.

Para desactivar temporalmente el control:

```sh
sudo systemctl disable --now fan-pwm.service
```

Al salir limpiamente, el programa deja la orden PWM al 100 % por seguridad. El sistema todavía no tiene un watchdog independiente que garantice 100 % ante cualquier caída brusca de Linux o pérdida de energía; no tratar este servicio como protección térmica certificada.

## Próximos pasos de aprendizaje

1. Instalar la corrección del impulso al encender por temperatura y comprobar el log.
2. Comprobar el mínimo real de 30 % con observación física, sin dejar la fan detenida bajo carga.
3. Verificar a futuro el comportamiento a temperaturas intermedias sin forzar temperaturas peligrosas.
4. Luego preparar en la AN970 un monitor tipo `htop` con CPU, memoria, carga, red y temperaturas.

Watts reales requieren tensión y corriente medidos. RPM reales requieren tacómetro. Si no existen esas señales, se debe mostrar “no medido” y no inventar esos valores.