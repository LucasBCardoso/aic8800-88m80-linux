#!/bin/bash
# Instala o driver Linux do dongle WiFi 6 USB "AIC 88M80" (AIC8800D80) no Ubuntu/Debian.
# Uso: sudo bash install.sh
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Rode com sudo: sudo bash install.sh"; exit 1; }
DIR="$(cd "$(dirname "$0")" && pwd)"

# Pacotes do driver open-source da Radxa (inclui correções para kernel 6.17+)
VER="5.0+git20260123.5f7be68d-10"
URL="https://github.com/radxa-pkg/aic8800/releases/download/${VER//+/%2B}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "== 1/4 Instalando dependências (dkms, headers do kernel, python3)"
apt-get update -qq
apt-get install -y dkms "linux-headers-$(uname -r)" python3

echo "== 2/4 Baixando e instalando driver + firmware aic8800 ($VER)"
for p in aic8800-firmware aic8800-usb-dkms; do
    curl -fsSL -o "$TMP/${p}_${VER}_all.deb" "$URL/${p}_${VER//+/%2B}_all.deb"
done
# Hashes dos pacotes testados; aborta se o download não for exatamente o mesmo arquivo
(cd "$TMP" && sha256sum -c --strict <<EOF
0b7c5e229a4214f738e260cfdca45dc934abb5079890c709346577126dba94f8  aic8800-firmware_${VER}_all.deb
50f73e0113c7fbc41502a7d5740b98d001a662df57ef0c0dceca5cb9a9503e13  aic8800-usb-dkms_${VER}_all.deb
EOF
) || { echo "ERRO: hash SHA-256 não confere — pacote alterado ou corrompido, abortando."; exit 1; }
apt-get install -y "$TMP"/aic8800-firmware_*.deb "$TMP"/aic8800-usb-dkms_*.deb

echo "== 3/4 Instalando script de troca de modo + regra udev"
install -m 755 "$DIR/aic8800-switch.py" /usr/local/sbin/aic8800-switch.py
install -m 644 "$DIR/99-aic8800-modeswitch.rules" /etc/udev/rules.d/99-aic8800-modeswitch.rules
udevadm control --reload-rules

echo "== 4/4 Trocando o dongle para modo WiFi (se estiver conectado)"
for b in /sys/block/sd*; do
    [ -e "$b" ] || continue
    if udevadm info -q property -p "$b" | grep -q "ID_VENDOR_ID=1111"; then
        python3 -I /usr/local/sbin/aic8800-switch.py "/dev/${b##*/}" || true
    fi
done
sleep 8

lsusb | grep -i -E "a69c|1111" || echo "(dongle não conectado — conecte agora, a troca é automática)"
ip -br link | grep -E "^wl" || true
echo "Pronto. Se não aparecer a interface wlx..., desconecte e conecte o dongle de novo."
