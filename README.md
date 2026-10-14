# aic8800-88m80-linux

Faz o dongle USB WiFi 6 **"AIC 88M80"** (chip AIC8800D80) funcionar no Ubuntu/Linux.

O dongle chega se passando por um pendrive (`1111:1111`) com um instalador só para Windows.
O eject padrão do Linux não o tira desse modo; este projeto reproduz os comandos de fabricante
que o instalador Windows envia (descobertos por engenharia reversa — veja
[docs/engenharia-reversa.md](docs/engenharia-reversa.md)) e instala o driver open-source.

## Instalar

```bash
git clone https://github.com/LucasBCardoso/aic8800-88m80-linux.git
cd aic8800-88m80-linux
sudo bash install.sh
```

Precisa de internet (cabo) durante a instalação. Depois disso a troca para modo WiFi é automática
toda vez que o dongle é conectado, e o DKMS recompila o driver a cada atualização de kernel.

## Conferir

```bash
lsusb | grep -i -E "a69c|1111"   # a69c:8d81 = modo WiFi ✔   1111:1111 = ainda em modo disco
ip -br link | grep ^wl           # interface wlx...
nmcli dev wifi list
```

## Se o dongle continuar como disco (1111:1111)

```bash
lsblk                                            # descubra o disco do dongle (~2 MB), ex.: sdb
sudo python3 /usr/local/sbin/aic8800-switch.py /dev/sdb
```

Se ele já recebeu comandos errados e travou, desconecte e conecte de novo antes.

## Arquivos

| Arquivo | O que faz |
|---|---|
| `install.sh` | instala dependências, driver + firmware [radxa-pkg/aic8800](https://github.com/radxa-pkg/aic8800), script e regra udev |
| `aic8800-switch.py` | envia `GetHippo` (`FD…F3`) e `Set_CS1_0` (`FD…F2`) via SG_IO |
| `99-aic8800-modeswitch.rules` | roda o script automaticamente ao conectar o dongle |
| `uninstall.sh` | remove tudo |

## Observações

- Secure Boot ligado: o DKMS pede para registrar uma chave MOK na instalação (siga a tela azul no próximo boot).
- O driver também carrega o Bluetooth (`aic_btusb`), não testado.
- Testado em Ubuntu 24.04, kernel 6.17.
