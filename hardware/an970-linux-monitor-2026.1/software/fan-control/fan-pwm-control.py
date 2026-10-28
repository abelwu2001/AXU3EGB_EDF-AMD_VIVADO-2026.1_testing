#!/usr/bin/env python3
"""Temperature based fan control for AXU3EGB EDF Linux / AXI PWM IP."""
import glob
import mmap
import os
import struct
import sys
import time

PWM_BASE = 0xA0000000
PWM_PERIOD = 4000                 # 99.999 MHz / 4000 ~= 25 kHz
REG_CTRL, REG_PERIOD, REG_DUTY = 0x00, 0x04, 0x08
CTRL_ENABLE = 1 << 0
CTRL_POLARITY_INVERT = 1 << 1     # PWM output is active-low at FAN_PWM
START_C = 40.0
STOP_C = 38.0                     # hysteresis: don't chatter at 40 C
FULL_C = 60.0
MIN_RUNNING_PERCENT = 30.0        # must be confirmed against this fan
KICKSTART_SECONDS = 2.0
SAMPLE_SECONDS = 2.0


def log(message):
    print(f"fan-pwm: {message}", flush=True)


def read_temperatures():
    """Return labeled SoC temperatures in Celsius, gathered from hwmon."""
    values = []
    for label_path in glob.glob("/sys/class/hwmon/hwmon*/temp*_label"):
        try:
            with open(label_path, encoding="ascii") as f:
                label = f.read().strip()
            if label not in {"Temp_LPD", "Temp_FPD", "Temp_PL"}:
                continue
            input_path = label_path[:-len("_label")] + "_input"
            with open(input_path, encoding="ascii") as f:
                milli_c = int(f.read().strip())
            values.append((label, milli_c / 1000.0))
        except (OSError, ValueError) as exc:
            log(f"sensor read failed at {label_path}: {exc}")
    return values


def find_uio():
    """Find the UIO device whose map0 is the PWM's 0xA0000000 region."""
    for name_path in glob.glob("/sys/class/uio/uio*/name"):
        uio_dir = os.path.dirname(name_path)
        try:
            with open(os.path.join(uio_dir, "maps/map0/addr"), encoding="ascii") as f:
                addr = int(f.read().strip(), 0)
            with open(os.path.join(uio_dir, "maps/map0/size"), encoding="ascii") as f:
                size = int(f.read().strip(), 0)
            if addr == PWM_BASE and size >= 0x0C:
                return os.path.basename(uio_dir), size
        except (OSError, ValueError):
            continue
    raise RuntimeError("No UIO map found at 0xA0000000; fan stays at hardware reset state")


class Pwm:
    def __init__(self, uio_name, map_size):
        self.fd = os.open(f"/dev/{uio_name}", os.O_RDWR | os.O_SYNC)
        self.mem = mmap.mmap(self.fd, map_size, flags=mmap.MAP_SHARED,
                             prot=mmap.PROT_READ | mmap.PROT_WRITE, offset=0)

    def write(self, offset, value):
        struct.pack_into("<I", self.mem, offset, value & 0xFFFFFFFF)

    def set_percent(self, percent):
        percent = max(0.0, min(100.0, percent))
        duty = round(PWM_PERIOD * percent / 100.0)
        # Disable while changing timing registers; then enable active-low mode.
        self.write(REG_CTRL, 0)
        self.write(REG_PERIOD, PWM_PERIOD)
        self.write(REG_DUTY, duty)
        self.write(REG_CTRL, CTRL_ENABLE | CTRL_POLARITY_INVERT)
        return duty

    def close(self):
        self.mem.close()
        os.close(self.fd)


def desired_percent(temp_c, fan_running):
    """Off below 38 C; start at 40 C and ramp linearly to 100% at 60 C."""
    if temp_c <= STOP_C:
        return 0.0, False
    if not fan_running and temp_c < START_C:
        return 0.0, False
    if temp_c < START_C:
        return MIN_RUNNING_PERCENT, True
    if temp_c >= FULL_C:
        return 100.0, True
    span = (100.0 - MIN_RUNNING_PERCENT) / (FULL_C - START_C)
    return MIN_RUNNING_PERCENT + (temp_c - START_C) * span, True


def main():
    uio_name, map_size = find_uio()
    pwm = Pwm(uio_name, map_size)
    fan_running = True
    try:
        # Startup kick: briefly run full speed so the fan reliably starts.
        pwm.set_percent(100.0)
        log(f"{uio_name} mapped 0x{PWM_BASE:08X}; 25 kHz PWM; 100% kick for {KICKSTART_SECONDS:.0f}s")
        time.sleep(KICKSTART_SECONDS)
        while True:
            temperatures = read_temperatures()
            if not temperatures:
                # Sensor failure is fail-safe: request full fan, never turn it off.
                temp_c = None
                percent = 100.0
                fan_running = True
                log("no labeled SoC temperature sensors; fail-safe 100%")
            else:
                temp_c = max(value for _, value in temperatures)
                was_running = fan_running
                percent, should_run = desired_percent(temp_c, fan_running)
                if should_run and not was_running:
                    # Kick the fan when temperature control starts it from rest.
                    pwm.set_percent(100.0)
                    log(f"temperature reached {temp_c:.1f}C; 100% startup kick for {KICKSTART_SECONDS:.0f}s")
                    time.sleep(KICKSTART_SECONDS)
                    percent, fan_running = desired_percent(temp_c, True)
                else:
                    fan_running = should_run
                readings = ", ".join(f"{name}={value:.1f}C" for name, value in temperatures)
                log(f"{readings}; max={temp_c:.1f}C; fan={percent:.1f}%")
            duty = pwm.set_percent(percent)
            log(f"registers: CTRL=0x3 PERIOD={PWM_PERIOD} DUTY={duty}")
            time.sleep(SAMPLE_SECONDS)
    finally:
        # Leave the fan at full speed if the program is stopped cleanly.
        try:
            pwm.set_percent(100.0)
            log("stopping: left PWM at 100%")
        finally:
            pwm.close()


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        log(f"fatal error: {exc}")
        sys.exit(1)

