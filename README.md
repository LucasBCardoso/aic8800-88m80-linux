# aic8800-88m80-linux

Faz o adaptador **WiFi 6 USB "AIC 88M80"** funcionar no **Ubuntu**.

> **É este o seu adaptador?** Ao conectar no Ubuntu, ele aparece como um "pendrive" de ~2 MB
> com um arquivo `Wifi6_install_bt.exe` dentro, e o WiFi não funciona. Se sim, este guia é para você.

---

## Antes de começar

Você vai precisar de:

- ✅ Ubuntu 22.04 ou mais novo (testado no 24.04)
- ✅ **Internet por cabo** (ou celular roteando via USB) — o WiFi ainda não funciona, né? 🙂
- ✅ A senha do seu usuário (a mesma do login)

---

## Instalação (5 minutos)

### Passo 1 — Abra o Terminal

Aperte **`Ctrl` + `Alt` + `T`** no teclado. Vai abrir uma janela preta: é o Terminal.

### Passo 2 — Copie e cole este comando

Selecione o bloco abaixo, copie, e cole no Terminal com **`Ctrl` + `Shift` + `V`**. Depois aperte **`Enter`**.

```bash
sudo apt install -y git && git clone https://github.com/LucasBCardoso/aic8800-88m80-linux.git && cd aic8800-88m80-linux && sudo bash install.sh
```

### Passo 3 — Digite sua senha

O Terminal vai pedir `[sudo] senha para ...`. Digite sua senha e aperte **`Enter`**.

> 💡 É normal **não aparecer nada** enquanto você digita a senha (nem asteriscos). Pode digitar normalmente.

Espere terminar (1 a 3 minutos). No final aparece **`Pronto.`**

### Passo 4 — Desconecte e conecte o adaptador

Tire o adaptador da porta USB, espere 3 segundos e conecte de novo.

### Passo 5 — Conecte no WiFi

Clique no **canto superior direito** da tela → **WiFi** → escolha sua rede → digite a senha. 🎉

A partir de agora funciona sozinho: em todo boot e toda vez que conectar o adaptador.
Não precisa fazer mais nada, nem depois de atualizar o Ubuntu.

---

## Conferir se deu certo

No Terminal:

```bash
lsusb | grep -i -E "a69c|1111"
```

| O que aparece | Significa |
|---|---|
| `a69c:8d81 AICSemi AIC 8800D80` | ✅ Está em modo WiFi, tudo certo |
| `1111:1111 ... 88M80` | ❌ Ainda está em modo "pendrive" — veja abaixo |
| nada | O adaptador não está conectado |

---

## Problemas comuns

| Problema | Solução |
|---|---|
| Continua aparecendo como pendrive (`1111:1111`) | Desconecte e conecte o adaptador de novo. Se não resolver, veja [Troca manual](#troca-manual) |
| Apareceu uma **tela azul** ("MOK management") ao reiniciar | Seu PC tem Secure Boot. Escolha **Enroll MOK** → **Continue** → **Yes**, e digite a senha que o instalador pediu |
| `ERRO: hash SHA-256 não confere` | O download veio corrompido. Rode o Passo 2 de novo. Se repetir, [abra uma issue](https://github.com/LucasBCardoso/aic8800-88m80-linux/issues) |
| `fatal: destination path 'aic8800-88m80-linux' already exists` | Você já baixou antes. Rode: `cd aic8800-88m80-linux && git pull && sudo bash install.sh` |
| `Unable to locate package linux-headers-...` | Atualize o sistema (`sudo apt update && sudo apt upgrade`), reinicie e tente de novo |
| WiFi parou depois de atualizar o Ubuntu | Reinicie o computador. Se não voltar, rode o instalador de novo |

### Troca manual

Se o adaptador ficar preso em modo pendrive:

```bash
lsblk
```

Procure o disco de **~2 MB** (por exemplo `sdb`) e rode, trocando `sdb` pelo nome que apareceu:

```bash
sudo python3 /usr/local/sbin/aic8800-switch.py /dev/sdb
```

---

## Desinstalar

```bash
cd aic8800-88m80-linux && sudo bash uninstall.sh
```

---

## Como funciona (para os curiosos)

O adaptador liga se passando por um pendrive com um instalador só para Windows. O "ejetar" normal
do Linux não o tira desse modo. Este projeto:

1. Instala o driver open-source [radxa-pkg/aic8800](https://github.com/radxa-pkg/aic8800) (com verificação SHA-256);
2. Envia ao adaptador os mesmos comandos secretos que o instalador do Windows envia
   (`FD…F3` e `FD…F2`, descobertos por engenharia reversa);
3. Cria uma regra que faz isso automaticamente toda vez que ele é conectado.

Detalhes técnicos: [docs/engenharia-reversa.md](docs/engenharia-reversa.md)

| Arquivo | O que faz |
|---|---|
| `install.sh` | Instala tudo |
| `uninstall.sh` | Remove tudo |
| `aic8800-switch.py` | Troca o adaptador de modo pendrive para modo WiFi |
| `99-aic8800-modeswitch.rules` | Faz a troca automática ao conectar |
