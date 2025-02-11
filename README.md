<p align="center">
    <img width="1000px" src="https://github.com/matheusitl/debian-post-install-on-thinkpad-t480/blob/main/image.png?raw=true" alt="white" />
</p>

</br>

## Configuring APT Sources

To enable additional repositories for proprietary firmware and software, using a text editor, add `contrib non-free non-free-firmware` after `main` in your APT sources:

```shell
sudo nano /etc/apt/sources.list
```

For example:

```plaintext
deb https://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian bookworm main contrib non-free non-free-firmware

deb https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb-src https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware

deb https://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
```

Run:

```shell
sudo apt update
```

</br>

## Enabling Backports, contrib, and non-free Components

Create a new repo file in the directory using a text editor

```shell
sudo nano /etc/apt/sources.list.d/debian-12-backports.list
```

or manually add the backports lines to `/etc/apt/sources.list`.

For example, add the following lines:

```plaintext
deb https://deb.debian.org/debian bookworm-backports main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian bookworm-backports main contrib non-free non-free-firmware
```

Run:

```shell
sudo apt update
```

</br>

## Add APT Repositories (_That's my personal preference_)

### VS Code

```shell
sudo apt install wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg
```

### Spotify

```shell
sudo apt install curl
curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb http://repository.spotify.com/ stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
```

Install both:

```shell
sudo apt update && sudo apt install apt-transport-https code spotify-client
```

</br>

## Update Thunderbolt Firmware (Highly recommended)

If you haven’t done this yet, run the following command

```shell
sudo sh -c 'fwupdmgr refresh && fwupdmgr update'
```

The command below is used to check if you are on the **current version 23.00:**

```shell
fwupdmgr get-devices
```

</br>

## Install Pipewire (Audio and Bluetooth Support)

Install Pipewire metapackage:

```shell
sudo apt install pipewire-audio wireplumber pipewire-pulse pipewire-alsa libspa-0.2-bluetooth
```

Enable WirePlumber in `systemd` to ensure it runs on boot:

```shell
sudo systemctl --user --now enable wireplumber.service
```

Reboot to apply the changes:

```shell
sudo reboot
```

After reboot, display the complete information using:

```shell
pw-dump
```

</br>

## Fingerprint Authentication

```shell
sudo apt remove fprintd
```

Download python-validity, fprintd-clients and open-fprintd (for Jammy) from **[PPA direct link](https://launchpad.net/~uunicorn/+archive/ubuntu/open-fprintd/+packages)**.

Go the folder where the downloaded `.deb` files are located `(e.g., cd Downloads)` and install them::

```shell
sudo dpkg -i python-validity*.deb fprintd-clients*.deb open-fprintd*.deb
```

Fix Dependencies:

```shell
apt install --fix-broken
```

### Enroll Fingerprint

```shell
fprintd-enroll
```

### Update PAM Configuration:

```shell
sudo pam-auth-update
```

**If fingerprint not working after waking up from suspend, fix it changing `open-fprintd-resume.service`:**

Using a text editor

```shell
sudo nano /usr/lib/systemd/system/open-fprintd-resume.service
```

in the `[Service]` section, comment out this line by adding `#` at the beginning

```plaintext
#ExecStart=/usr/lib/open-fprintd/resume.py
```

and add this new line to restart the services when resuming:

```plaintext
ExecStart=systemctl restart open-fprintd.service python3-validity.service
```

### Add to SDDM:

To enable fingerprint authentication in the SDDM login manager, open the PAM configuration file

```shell
sudo nano /etc/pam.d/sddm
```

add the following lines to the top of the file:

```plaintext
auth    [success=1 new_authtok_reqd=1 default=ignore]   pam_unix.so try_first_pass likeauth nullok``
auth    sufficient  pam_fprintd.so
```

</br>

## ZSH + Oh My Zsh

```shell
sudo apt install zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

Set a Custom Theme using a text editor:

```shell
nano ~/.zshrc
```

```plaintext
`ZSH_THEME="minimal"` # My favorite theme
```

</br>

## Uncomplicated Firewall (ufw) + Plasma Firewall (GUI)

```shell
sudo apt install ufw plasma-firewall
```

**Allows SSH connections:**

```shell
ufw allow ssh
```

**Port range if you are using KDE Connect:**

```shell
sudo ufw allow 1714:1764/udp
sudo ufw allow 1714:1764/tcp
sudo ufw reload
```

</br>

## Add Flatpak support

```shell
sudo apt install flatpak plasma-discover-backend-flatpak
```

```shell
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

Some of my preferred Flatpak apps, these include a variety of useful tools for productivity, media, and gaming:

```shell
flatpak install flathub \
    com.github.tchx84.Flatseal \
    org.mozilla.Thunderbird \
    org.telegram.desktop \
    org.duckstation.DuckStation \
    com.stremio.Stremio \
    com.bitwarden.desktop \
    org.qbittorrent.qBittorrent \
    com.obsproject.Studio \
    com.heroicgameslauncher.hgl \
    org.flameshot.Flameshot \
    com.steamgriddb.SGDBoop
```

</br>

## Ready and installing Steam

Enable Multi-Arch for amd64 (64-bit) systems

```shell
dpkg --add-architecture i386
```

and nstall Steam client and additional libraries need to be installed for Vulkan and 32-bit titles:

```shell
sudo apt update && sudo apt install steam-installer mesa-vulkan-drivers libglx-mesa0:i386 mesa-vulkan-drivers:i386 libgl1-mesa-dri:i386
```

</br>

## Install TLP (Optimize Linux Laptop Battery Life)

For Debian backports:

```shell
apt -t bookworm-backports install tlp tlp-rdw
```

**Manually start:**

```shell
sudo tlp start
```

</br>

## Install Throttled (Fix Intel CPU Throttling on Linux)

```shell
sudo apt install git build-essential python3-dev libdbus-glib-1-dev libgirepository1.0-dev libcairo2-dev python3-cairo-dev python3-venv python3-wheel
git clone https://github.com/erpalma/throttled.git
sudo ./throttled/install.sh
```

Disable `thermald` Service (If Needed):

```shell
sudo systemctl stop thermald.service
sudo systemctl disable thermald.service
```

**If you want to permanently disable `thermald`, you can mask the service:**

```shell
sudo systemctl mask thermald.service
```

Verify `throttled` Service:

```shell
systemctl status throttled
```

</br>

## Install Anki (Flash Cards)

Install the necessary dependencies required by Anki:

```shell
sudo apt install libxcb-xinerama0 libxcb-cursor0 libnss3 zstd
```

Download and Install Anki:

[Anki download page](https://apps.ankiweb.net/)

```shell
tar xaf Downloads/anki-2XXX-linux-qt6.tar.zst
cd anki-2XXX-linux-qt6
sudo ./install.sh
```

</br>

## Install Microsoft Fonts

```shell
sudo apt install ttf-mscorefonts-installer
```

</br>

## Skip GRUB menu (For a faster boot time)

Open the GRUB configuration file with a text editor and locate the line that says `GRUB_TIMEOUT=10` and change it to `GRUB_TIMEOUT=0` to skip the GRUB menu entirely:

```shell
sudo nano /etc/default/grub
```

Run the following command to apply the new settings:

```shell
sudo update-grub
```
