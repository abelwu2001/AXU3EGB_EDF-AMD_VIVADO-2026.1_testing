#!/bin/sh
# Apply the Linux PL description, then bind the PWM registers through UIO.
# The BOOT.BIN already loaded the FPGA bitstream, so this overlay intentionally
# has no firmware-name property: it must not ask Linux to reload the bitstream.
set -eu

CONFIGFS=/sys/kernel/config
OVERLAYS="$CONFIGFS/device-tree/overlays"
OVERLAY_NAME=fan-pwm-platform
DTB=/run/fan-pwm-platform.dtbo
DTS=/etc/fan-pwm/fan-pwm-device-tree.dtso

if ! mountpoint -q "$CONFIGFS"; then
    mount -t configfs configfs "$CONFIGFS"
fi

has_pwm_uio() {
    for addr in /sys/class/uio/uio*/maps/map0/addr; do
        [ -r "$addr" ] || continue
        [ "$(cat "$addr")" = "0x00000000a0000000" ] && return 0
    done
    return 1
}

find_pwm_node() {
    for node in \
        /proc/device-tree/axi/axi_pwm@a0000000 \
        /proc/device-tree/amba_pl/axi_pwm@a0000000 \
        /proc/device-tree/amba/axi_pwm@a0000000; do
        if [ -d "$node" ]; then
            PWM_NODE=$node
            return 0
        fi
    done
    return 1
}

if has_pwm_uio; then
    exit 0
fi

if ! find_pwm_node; then
    # The base EDF Device Tree strips PL nodes; apply the generated PL overlay.
    [ -r "$DTS" ] || { echo "Missing PL overlay source: $DTS" >&2; exit 1; }
    dtc -@ -I dts -O dtb -o "$DTB" "$DTS"
    mkdir -p "$OVERLAYS/$OVERLAY_NAME"
    if ! cat "$DTB" > "$OVERLAYS/$OVERLAY_NAME/dtbo"; then
        rmdir "$OVERLAYS/$OVERLAY_NAME" 2>/dev/null || true
        echo "Could not apply the PL Device Tree overlay" >&2
        exit 1
    fi
    if ! find_pwm_node; then
        echo "Overlay applied but axi_pwm@a0000000 did not appear" >&2
        exit 1
    fi
fi

COMPAT=$(tr '\000' '\n' < "$PWM_NODE/compatible" | head -n 1)
[ -n "$COMPAT" ] || { echo "PWM node has no compatible string" >&2; exit 1; }
modprobe uio_pdrv_genirq "of_id=$COMPAT"

i=0
while [ "$i" -lt 50 ]; do
    has_pwm_uio && exit 0
    i=$((i + 1))
    sleep 0.1
done

echo "No UIO map found at 0xA0000000" >&2
exit 1