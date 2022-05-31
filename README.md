# ELLI (EFI with LUKS and LVM installer)
O ELLI é um script instalador simples de Arch Linux.

# Passo-a-passo
Primeiro, executando o modo live do Arch Linux e conectado à internet, instale o git:
'''
pacman -Sy git
'''
Segundo, clone este repositório:
'''
git clone https://github.com/lbecher/elli.git
'''
Terceiro, permita a execução do script '''start.sh''':
'''
chmod +x start.sh
'''
Quarto, execute o script '''start.sh''':
'''
./start.sh
'''
Quinto, entre no root de sua instalação:
'''
arch-chroot /mnt
'''
Sexto, adicione um novo usuário:
'''
useradd -m -G wheel nome_do_seu_usuario
'''
Sétimo, apague o '''#''' na linha '''# %wheel ALL=(ALL) ALL''', após executar o comando:
'''
EDITOR=nano visudo
'''
Oitavo, acesse seu usuário:
'''
su nome_do_seu_usuario
'''
Nono, instale o paru:
'''
cd ~/ && git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si
'''
Décimo, instale o plymouth:
'''
paru -S pymouth
'''
