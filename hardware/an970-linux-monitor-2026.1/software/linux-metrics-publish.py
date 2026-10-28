#!/usr/bin/env python3
"""Publish Linux metrics and fan PWM feedback to the AN970 AXI register block."""
import glob
import mmap
import os
import socket
import struct
import time

METRICS_BASE = 0xA0010000
PWM_BASE = 0xA0000000
MAP_SIZE = 0x10000


def map_uio(base, writable):
    for name_path in glob.glob("/sys/class/uio/uio*/name"):
        uio_dir = os.path.dirname(name_path)
        try:
            with open(os.path.join(uio_dir, "maps/map0/addr")) as f:
                addr = int(f.read().strip(), 0)
            with open(os.path.join(uio_dir, "maps/map0/size")) as f:
                size = int(f.read().strip(), 0)
            if addr == base and size >= MAP_SIZE:
                flags = os.O_RDWR if writable else os.O_RDONLY
                fd = os.open("/dev/" + os.path.basename(uio_dir), flags | os.O_SYNC)
                prot = mmap.PROT_READ | (mmap.PROT_WRITE if writable else 0)
                mem = mmap.mmap(fd, MAP_SIZE, flags=mmap.MAP_SHARED, prot=prot, offset=0)
                return fd, mem
        except (OSError, ValueError):
            pass
    raise RuntimeError("No encuentro el mapa UIO en 0x%08X" % base)


def read_cpu():
    result = {}
    with open("/proc/stat") as f:
        for line in f:
            fields = line.split()
            if fields and fields[0].startswith("cpu") and fields[0][3:].isdigit():
                numbers = [int(x) for x in fields[1:9]]
                result[int(fields[0][3:])] = (sum(numbers), numbers[3] + numbers[4])
    return result


def cpu_percent(old, new, core):
    if core not in old or core not in new:
        return 0
    total = new[core][0] - old[core][0]
    idle = new[core][1] - old[core][1]
    return max(0, min(100, round(100 * (total - idle) / total))) if total > 0 else 0


def read_ram_percent():
    info = {}
    with open("/proc/meminfo") as f:
        for line in f:
            key, value = line.split(":", 1)
            info[key] = int(value.split()[0])
    total = info["MemTotal"]
    available = info.get("MemAvailable", 0)
    return round(100 * (total - available) / total) if total else 0


def read_temperatures():
    values = {}
    for label_path in glob.glob("/sys/class/hwmon/hwmon*/temp*_label"):
        try:
            with open(label_path) as f:
                label = f.read().strip()
            if label in ("Temp_LPD", "Temp_FPD", "Temp_PL"):
                with open(label_path[:-6] + "_input") as f:
                    values[label] = round(int(f.read().strip()) / 100)
        except (OSError, ValueError):
            pass
    return values


def read_ipv4():
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("192.0.2.1", 9))
            return int.from_bytes(socket.inet_aton(s.getsockname()[0]), "big")
    except OSError:
        return 0


metrics_fd, metrics = map_uio(METRICS_BASE, True)
pwm_fd, pwm = map_uio(PWM_BASE, False)
previous_cpu = read_cpu()
time.sleep(1)
try:
    while True:
        current_cpu = read_cpu()
        cpu = [cpu_percent(previous_cpu, current_cpu, i) for i in range(4)]
        previous_cpu = current_cpu
        temps = read_temperatures()
        fan_period, fan_duty = struct.unpack_from("<II", pwm, 4)
        fan = round(100 * fan_duty / fan_period) if fan_period else 0
        ip_value = read_ipv4()
        values = [
            cpu[0] | (cpu[1] << 8) | (cpu[2] << 16) | (cpu[3] << 24),
            read_ram_percent(),
            temps.get("Temp_LPD", 0),
            temps.get("Temp_FPD", 0),
            temps.get("Temp_PL", 0),
            fan,
            ip_value,
        ]
        for i, value in enumerate(values):
            struct.pack_into("<I", metrics, 4 * i, value & 0xFFFFFFFF)
        print("CPU=%s RAM=%d%% LPD=%d.%dC FPD=%d.%dC PL=%d.%dC FAN=%d%% IP=%s" %
              (cpu, values[1], values[2] // 10, values[2] % 10,
               values[3] // 10, values[3] % 10, values[4] // 10,
               values[4] % 10, fan,
               socket.inet_ntoa(ip_value.to_bytes(4, "big")) if ip_value else "sin IP"),
              flush=True)
        time.sleep(1)
finally:
    pwm.close()
    metrics.close()
    os.close(pwm_fd)
    os.close(metrics_fd)

