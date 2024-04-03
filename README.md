# ELLI (EFI with LUKS and LVM installer)

O ELLI é um script instalador simples de Arch Linux.

# Antes de executar o script

## Mudando o layout do teclado para ABNT2

```
loadkeys br-abnt2
```

## Formatando o dispositivo de armazenamento

Crie três partições. Primeiro uma de 512M para EFI, depois uma de 1024M para o GRUB e, por último, uma com todo o tamanho disponível no seu dispositivo.

Considerando um SSD NVMe, como exemplo, vamos alterá-lo via fdisk.

```
fdisk /dev/nvme0n1
```

### Esquema de partição

É fundamental que o esquema de partição seja GPT.

```
g
```

### Partição EFI

```
n
```

```
1
```

Deixe o valor padrão para o setor inicial.

```
+512M
```

```
t
```

```
1
```

### Partição do GRUB

```
n
```

```
2
```

Deixe o valor padrão para o setor inicial.

```
+1024M
```

### Partição do sistema de arquivos criptografado

```
n
```

```
3
```

Deixe o valor padrão para o setor inicial. Faça o mesmo para o setor final, pois, assim, a partição ficará com o tamanho total disponível.

# Preparando-se para instalar

Antes, conecte-se à Internet. Se deseja utilizar uma rede Wi-Fi, [leia isso](https://wiki.archlinux.org/title/iwd).

```
pacman -Sy git glibc
```

```
git clone https://github.com/lbecher/elli.git
```

```
cd elli
```

```
chmod +x install.sh
```

Altere os parâmetros no início do arquivo install.sh, utilizando o seu editor de texto preferido.

# Instalando

```
./install.sh
```
