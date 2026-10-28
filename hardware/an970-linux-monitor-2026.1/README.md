# AXU3EGB — monitor Linux AN970 + fan PWM

Este proyecto es la versión combinada que se probó en la placa: el ZynqMP ejecuta AMD EDF 26.06, Linux publica datos por AXI-Lite y la PL dibuja un monitor horizontal en el AN970. El PWM de la PL regula el ventilador con las temperaturas de AMS.

## Qué muestra y qué se probó

- Cuatro usos de CPU, RAM utilizada, temperaturas Temp_LPD/FPD/PL, IP IPv4 y porcentaje de ciclo de trabajo PWM.
- Control térmico del ventilador: comienza cerca de 40 °C, usa histéresis cerca de 38 °C y aumenta hacia 100 % a 60 °C. El umbral mínimo de marcha está fijado en el script.
- La placa arrancó y mostró datos en vivo; los servicios `monitor-bitstream`, `fan-pwm` y `linux-metrics-publish` quedaron activos.
- La implementación se generó con Vivado 2026.1 para `xczu3eg-sfvc784-1-e`; timing: WNS 7.215 ns, TNS 0, WHS 0.037 ns. Hay advertencias de metodología por retardos externos de E/S sin restricciones. No equivale a certificar cada periférico del board.
- El panel reporta el duty que escribe el PWM; no hay lectura de RPM/tacómetro del ventilador en este diseño.

## Abrir el proyecto Vivado

Abrí `project/axu3eg_base.xpr` en Vivado 2026.1. El repositorio local de IP está en `../ip_repo`; si Vivado no encuentra los IP, agregá `ip_repo` en Settings → IP → Repository y ejecutá **Report IP Status → Rerun**. El proyecto usa `base.xdc` para asignar señales del conector AN970 y FAN_PWM.

Luego abrí el Block Design `base`, regenerá Output Products si aparece desactualizado, validá el diseño, ejecutá synthesis, implementation y Generate Bitstream. El `.bit` y el `.bit.bin` de `artifacts/` son los artefactos del build que se probó. El `.bit.bin` es el formato preparado con Bootgen para FPGA Manager. El BOOT.BIN del EDF en `/efi` no se reemplazó; Linux carga el PL bitstream desde `/lib/firmware/monitor.bit.bin` con systemd.

## Direcciones AXI

| Bloque | Base | Uso |
|---|---:|---|
| AXI PWM | `0xA0000000` | CTRL +0, PERIOD +4, DUTY +8 |
| Linux metrics | `0xA0010000` | Registros AXI-Lite de métricas |

| Registro | Offset | Valor escrito por Linux |
|---|---:|---|
| 0 | `0x00` | CPU0..CPU3, un byte por núcleo |
| 1 | `0x04` | RAM utilizada, porcentaje |
| 2 | `0x08` | Temp_LPD en décimas de °C |
| 3 | `0x0C` | Temp_FPD en décimas de °C |
| 4 | `0x10` | Temp_PL en décimas de °C |
| 5 | `0x14` | Duty PWM, porcentaje |
| 6 | `0x18` | IPv4 en orden de red |

## Linux — instalar los servicios

Los archivos fuente están en `software/`. Estos pasos son para AMD EDF y requieren root/sudo. Primero copiá `artifacts/monitor.bit.bin` a `/lib/firmware/monitor.bit.bin`, instalá el publicador en `/usr/local/sbin/linux-metrics-publish.py`, instalá el script de control y setup desde `software/fan-control/`, el overlay como `/etc/fan-pwm/fan-pwm-device-tree.dtso` y las unidades de `software/systemd/` en `/etc/systemd/system/` (el drop-in en `/etc/systemd/system/fan-pwm.service.d/`). El servicio de setup busca las direcciones UIO y activa el overlay si todavía no existe.

```sh
sudo install -m 0644 monitor.bit.bin /lib/firmware/monitor.bit.bin
sudo install -m 0755 fan-pwm-control.py fan-pwm-uio-setup.sh /usr/local/sbin/
sudo install -d /etc/fan-pwm /etc/systemd/system/fan-pwm.service.d
sudo install -m 0644 fan-pwm-device-tree.dtso /etc/fan-pwm/
sudo install -m 0644 monitor-bitstream.service linux-metrics-publish.service /etc/systemd/system/
sudo install -m 0644 monitor-bitstream.conf /etc/systemd/system/fan-pwm.service.d/
sudo systemctl daemon-reload
```

Ajustá las rutas de origen a donde hayas copiado los archivos. Para la primera prueba, activá el modo fan + monitor:

```sh
sudo systemctl enable monitor-bitstream.service fan-pwm.service linux-metrics-publish.service
sudo systemctl start fan-pwm.service linux-metrics-publish.service
systemctl --no-pager status monitor-bitstream.service fan-pwm.service linux-metrics-publish.service
```

La dependencia de `fan-pwm.service` carga el bitstream primero. El publicador requiere el servicio PWM para poder mostrar duty real.

### Elegir modo al próximo arranque

- **Solo fan, pantalla sin el monitor Linux:** deshabilitá `linux-metrics-publish.service`; dejá habilitados `monitor-bitstream.service` y `fan-pwm.service`.
- **Fan + pantalla con métricas:** habilitá los tres servicios.

```sh
# Modo fan al boot
sudo systemctl disable linux-metrics-publish.service
sudo systemctl enable monitor-bitstream.service fan-pwm.service

# Modo fan + pantalla al boot
sudo systemctl enable monitor-bitstream.service fan-pwm.service linux-metrics-publish.service
```

`enable` elige qué servicio se inicia al próximo boot; `start`/`stop` cambia la sesión actual. Ambos modos dependen del mismo bitstream combinado y del servicio de fan. No actives dos controladores de fan a la vez.

## Revisión de salud

```sh
systemctl is-enabled monitor-bitstream.service fan-pwm.service linux-metrics-publish.service
systemctl is-active monitor-bitstream.service fan-pwm.service linux-metrics-publish.service
cat /sys/class/fpga_manager/fpga0/state
for d in /sys/class/uio/uio*; do [ -r "$d/maps/map0/addr" ] && printf '%s %s %s\n' "${d##*/}" "$(cat "$d/name")" "$(cat "$d/maps/map0/addr")"; done
journalctl -u fan-pwm.service -n 10 --no-pager
journalctl -u linux-metrics-publish.service -n 10 --no-pager
```

Esperado: UIO map `0xA0000000` para PWM y `0xA0010000` para métricas; FPGA manager `operating`; servicios activos según el modo elegido.

## Hitos previos

El proyecto de colorbars y el primer fan PWM se conservan como experiencias separadas en [`hardware/an970-colorbars`](../an970-colorbars/) y [`hardware/fan-control-stage2`](../fan-control-stage2/). El catálogo del repositorio enlaza estos hitos y la guía fotográfica.



## Servicios systemd y selección del modo

La guía detallada de [comandos systemd, dependencias y arranque](../../docs/COMANDOS_SYSTEMD_Y_ARRANQUE.md) explica cómo crear tareas, revisar prioridades, interpretar `After=`/`Requires=`/ `WantedBy=` y elegir fan sola o fan + pantalla con métricas al reinicio.
