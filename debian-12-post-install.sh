#!/bin/bash

LOG_FILE="/var/log/debian_post_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Verifica se está rodando como root
if [[ $EUID -ne 0 ]]; then
   echo "Este script deve ser executado como root." 
   exit 1
fi

echo "Atualizando listas de pacotes..."
apt update -y

# Configuração dos repositórios
echo "Configurando repositórios..."
cp /etc/apt/sources.list /etc/apt/sources.list.bak  # Faz backup do sources.list
cat <<EOF > /etc/apt/sources.list
deb https://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb-src https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb https://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
EOF

# Adicionando backports
cat <<EOF > /etc/apt/sources.list.d/debian-12-backports.list
deb https://deb.debian.org/debian bookworm-backports main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian bookworm-backports main contrib non-free non-free-firmware
EOF

# Atualiza pacotes após adicionar os novos repositórios
apt update -y

# Atualizar firmware do Thunderbolt
echo "Atualizando firmware Thunderbolt..."
fwupdmgr refresh && fwupdmgr update

# Instalar Pipewire
echo "Instalando Pipewire..."
apt install -y pipewire-audio wireplumber pipewire-pulse pipewire-alsa libspa-0.2-bluetooth
systemctl --user --now enable wireplumber.service

# Instalar ZSH e configurar tema
echo "Instalando ZSH e Oh My Zsh..."
apt install -y zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="minimal"/' ~/.zshrc

# Instalar e configurar UFW
echo "Instalando e configurando UFW..."
apt install -y ufw plasma-firewall
ufw allow ssh
ufw allow 1714:1764/udp
ufw allow 1714:1764/tcp
ufw reload

# Instalar suporte a Flatpak e apps preferidos
echo "Instalando suporte a Flatpak e aplicativos..."
apt install -y flatpak plasma-discover-backend-flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.github.tchx84.Flatseal org.mozilla.Thunderbird org.telegram.desktop org.duckstation.DuckStation com.stremio.Stremio com.bitwarden.desktop org.qbittorrent.qBittorrent com.obsproject.Studio com.heroicgameslauncher.hgl com.vscodium.codium com.spotify.Client org.flameshot.Flameshot com.steamgriddb.SGDBoop

# Instalar Steam
echo "Instalando Steam..."
dpkg --add-architecture i386
apt update -y && apt install -y steam-installer mesa-vulkan-drivers libglx-mesa0:i386 mesa-vulkan-drivers:i386 libgl1-mesa-dri:i386

# Instalar TLP
echo "Instalando TLP..."
apt -t bookworm-backports install -y tlp tlp-rdw
tlp start

# Instalar throttled
echo "Instalando e configurando Throttled..."
apt install -y git build-essential python3-dev libdbus-glib-1-dev libgirepository1.0-dev libcairo2-dev python3-cairo-dev python3-venv python3-wheel
git clone https://github.com/erpalma/throttled.git
cd throttled && sudo ./install.sh
systemctl stop thermald.service
systemctl disable thermald.service
systemctl mask thermald.service
systemctl status throttled

# Instalar Microsoft Fonts
echo "Instalando fontes da Microsoft..."
apt install -y ttf-mscorefonts-installer

# Configuração do GRUB
echo "Configurando para pular menu do GRUB ao iniciar o sistema..."
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
update-grub

echo "Reinicie o sistema"
read -p "Deseja reiniciar agora? (s/n): " resposta
if [[ "$resposta" =~ ^[Ss]$ ]]; then
    reboot
fi
