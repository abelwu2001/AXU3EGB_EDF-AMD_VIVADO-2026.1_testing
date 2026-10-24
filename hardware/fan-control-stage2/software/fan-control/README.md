# Fan PWM control — Vivado 2026.1 + AMD EDF

Files in this directory:

- `fan-pwm-device-tree.dtso`: final overlay. Describes PL clock, AXI interface and the PWM at `0xA0000000`; intentionally omits `firmware-name` because BOOT.BIN already loads the bitstream.
- `fan-pwm-uio-setup.sh`: applies that overlay when the base Device Tree has no PWM node, then binds `uio_pdrv_genirq` to the node's compatible string and confirms map0 address.
- `fan-pwm-control.py`: Linux temperature-based PWM daemon.
- `fan-pwm.service`: systemd unit that performs setup first, then starts the daemon.
- `fan-pwm-uio-legacy.dts`: initial generic UIO overlay used during exploration; not used by the final setup script.

The final overlay was compiled using `dtc -@`, then merged with the actual base DTB from the newly built BOOT.BIN using `fdtoverlay`. The merged tree contains `/axi/axi_pwm@a0000000` and the correct `xlnx,axi-pwm-1.0` compatible string.

## Fan curve

- Read `Temp_LPD`, `Temp_FPD`, `Temp_PL` from hwmon and choose the hottest.
- Below 38 °C: off.
- At 40 °C: start at 30%.
- From 40 °C to 60 °C: ramp linearly to 100%.
- At or above 60 °C: 100%.
- At service start and each transition from stopped to running: 2 seconds at 100% to help overcome startup friction.
- Missing sensors: fail-safe request of 100%.
- Stop threshold 38 °C and start threshold 40 °C provide hysteresis.

PWM is 4000 PL0 cycles, about 25 kHz at 99.999 MHz. `CTRL=3` enables the IP and inverts its output for the board's active-low fan input. The 30% minimum needs physical validation; the board does not expose tachometer feedback, so the daemon cannot report actual RPM.

## Deployment destinations

- `fan-pwm-control.py` -> `/usr/local/sbin/fan-pwm-control.py`
- `fan-pwm-uio-setup.sh` -> `/usr/local/sbin/fan-pwm-uio-setup.sh`
- `fan-pwm-device-tree.dtso` -> `/etc/fan-pwm/fan-pwm-device-tree.dtso`
- `fan-pwm.service` -> `/etc/systemd/system/fan-pwm.service`

Install and enable only after the matching BOOT.BIN has booted and Linux is stable. Stopping the service leaves the fan requested at 100%.