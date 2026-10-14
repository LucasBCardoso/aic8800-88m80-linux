#!/bin/bash
# Remove o driver, o script de troca e a regra udev instalados por install.sh.
# Uso: sudo bash uninstall.sh
set -uo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Rode com sudo: sudo bash uninstall.sh"; exit 1; }

rm -f /etc/udev/rules.d/99-aic8800-modeswitch.rules /usr/local/sbin/aic8800-switch.py
udevadm control --reload-rules
modprobe -r aic8800_fdrv aic_btusb aic_load_fw 2>/dev/null || true
apt-get remove -y aic8800-usb-dkms aic8800-firmware
echo "Removido."
