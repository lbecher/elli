# ELLI (EFI with LUKS and LVM installer)
O ELLI é um script instalador simples de Arch Linux.

# Passo-a-passo
Primeiro, executando o modo live do Arch Linux e conectado à internet, instale o git:
```
pacman -Sy git
```
Segundo, clone este repositório e acesse seu conteúdo:
```
git clone https://github.com/lbecher/elli.git && cd elli
```
Terceiro, permita a execução do script `start.sh`:
```
chmod +x start.sh
```
Quarto, execute o script `start.sh` e passe os parâmetros necessários:
```
./start.sh /dev/partição_de_boot /dev/partição_dos_volumes_lógicos tamanho_em_GB_da_partição_raiz nome_do_grupo_de_volumes_lógicos
```
Exemplo:
```
./start.sh /dev/sda1 /dev/sda2 64 archlvm
```
Quinto, entre na raiz de sua instalação:
```
arch-chroot /mnt
```
Sexto, adicione um novo usuário:
```
useradd -m -G wheel nome_do_seu_usuario
```
Exemplo:
```
useradd -m -G wheel ana
```
Sétimo, mude a senha de seu usuário:
```
passwd nome_do_seu_usuario
```
Exemplo:
```
passwd ana
```
Oitavo, apague o `#` na linha `# %wheel ALL=(ALL) ALL`, após executar o comando:
```
EDITOR=nano visudo
```
Nono, acesse seu usuário:
```
su nome_do_seu_usuario
```
Décimo, instale o paru:
```
cd ~/ && git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si
```
Décimo primeiro, instale o plymouth:
```
paru -S pymouth
```
Décimo segundo, saia de seu usuário:
```
exit
```
Décimo terceiro, acesse o diretório `/root/elli` e permita a execução do script `chroot.sh`:
```
cd /root/elli/ && chmod +x chroot.sh
```
Décimo quarto, execute o script `chroot.sh` e passe os parâmetros necessários:
```
./chroot.sh /dev/partição_dos_volumes_lógicos
```
Exemplo:
```
./chroot.sh /dev/sda2
```
