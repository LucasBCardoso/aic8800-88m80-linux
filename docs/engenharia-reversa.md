# Como a troca de modo foi descoberta

O dongle "AIC 88M80" vem com um instalador Windows (`Wifi6_install_bt.exe`) gravado nele.
Os binários Windows **não** estão neste repositório (são proprietários); abaixo está só o que foi aprendido com eles.

## 1. O instalador

`Wifi6_install_bt.exe` é um instalador NSIS 3.11. Extraído com 7-Zip (`7zz x Wifi6_install_bt.exe`):

```
driversfiles/win10_x64/aicloadfw.Sys    carrega o firmware  (USB\VID_A69C&PID_8D80)
driversfiles/win10_x64/aicusbwifi.Sys   driver WiFi
tool/AicWifiService.exe                 serviço que chama EjectUSB
tool/Usb_Driver.dll                     envia os comandos SCSI ao "disco" do dongle
```

O chip é o **AIC8800D80**. O firmware vem embutido nos `.sys` do Windows, por isso no Linux
se usa o driver open-source (radxa-pkg/aic8800), que traz o próprio firmware.

## 2. Por que o eject padrão não funciona

Ao conectar, o dongle aparece como disco USB `1111:1111` (só contém o instalador).
`usb_modeswitch -K` (SCSI START STOP UNIT / eject padrão) é ignorado: o dongle continua `1111:1111`.

## 3. Os comandos de fabricante (Usb_Driver.dll)

Exports da DLL: `GetHippo`, `Set_CS1_0`, `SendCMD`, `UKeySCListDevs`, `UniSCConnectDev`.
`SendCMD` monta um `SCSI_PASS_THROUGH` (`DeviceIoControl` com `IOCTL 0x4D004`, CDB de 16 bytes, timeout 20 s).

| Export      | CDB (16 bytes)            | Dados            | Função                         |
|-------------|---------------------------|------------------|--------------------------------|
| `GetHippo`  | `FD 00 00 … 00 F3`        | lê 5 bytes       | consulta; responde `"88M80"`   |
| `Set_CS1_0` | `FD 00 00 … 00 F2`        | nenhum           | **troca para modo WiFi**       |

Após `F3` + `F2` o dongle reenumera como `a69c:8d81 AICSemi AIC 8800D80`,
e os módulos `aic_load_fw` / `aic8800_fdrv` / `aic_btusb` assumem.

## 4. Detalhe importante: use SG_IO, não CBW cru

Enviar os comandos como mensagens CBW cruas com `usb_modeswitch -M` falha: o `-n` lê os 5 bytes de
dados do `F3` mas não o CSW final, o protocolo Bulk-Only fica dessincronizado e o `F2` dá timeout
(libusb erro -7), travando o dongle até ser reconectado.

Por isso `aic8800-switch.py` usa o ioctl `SG_IO` do kernel sobre `/dev/sdX`: o driver `usb-storage`
cuida do protocolo completo (CBW → dados → CSW) de cada comando.

## Testado em

- Ubuntu 24.04, kernel 6.17.0-22-generic (DKMS também compilou para 7.0.0-38-generic)
- Secure Boot desligado (com Secure Boot ligado é preciso registrar a chave MOK do DKMS)
- Driver radxa-pkg/aic8800 `5.0+git20260123.5f7be68d-10`
