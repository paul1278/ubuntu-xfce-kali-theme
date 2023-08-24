#!/bin/bash
BASE=`dirname $0`
source $BASE/sources

function execq {
    "$@"
    if [ $? -ne 0 ]; then
        error "Failed to execute $1"
        exit 1
    fi
}

function execm {
    ok "$@"
    "$@" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        error "Failed to execute $1"
        exit 1
    fi
}

function exec {
    ok "$@"
    execq "$@"
}

function pref {
    printf "[$1$2\e[0m] "
}
    
function ask {
    read -p "[?] $1" LINE
    echo "$LINE"
}

function error {
    pref "\e[91m" "-"
    echo "$1"
}

function ok {
    pref "\e[92m" "+"
    echo "$@"
}

if [ `whoami` != "root" ]; then
    error "Please run as root"
    exit 1
fi

execm apt update

if ! [ "$XDG_CURRENT_DESKTOP" = "XFCE" ]; then
    error "You are not using xfce4"
    ask "Install xfce4? [Y/n] " | grep -qi "n" && exit 0
    ok "Installing xfce4"
    ask "The installer will ask you, if you want to use lightdm or gdm3, select lightdm [ENTER] "
    exec apt install -y xfce4 lightdm
fi

ok "Installing deps"
execm apt install -y gir1.2-libxfce4ui-2.0 fonts-firacode fonts-cantarell python3-newt libdpkg-perl libfile-fcntllock-perl python3-psutil
execm apt purge -y xterm xubuntu-core gnome-*
ok "Updating some settings"
execq gsettings set org.gnome.desktop.interface color-scheme prefer-dark
ok "Updating keyboard shortcuts"
rm /etc/xdg/autostart/xcape-super-key-bind.desktop 2>/dev/null
rm /etc/xdg/xdg-xubuntu/autostart/xcape-super-binding.desktop 2>/dev/null
find /home -wholename '*.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml' -delete

cat <<EOF > /etc/xdg/autostart/xcape-super-key-bind.desktop
[Desktop Entry]
Type=Application
Name=Xcape Super Key Bind
Exec=xcape -e 'Super_L=Control_L|Escape'
Terminal=false
OnlyShowIn=XFCE;
EOF

ok "Downloading dependencies"
mkdir $BASE/tmp
cd tmp

execm wget $GIT_THEMES
execm tar -xvf kali-themes-kali-master.tar.gz
rm kali-themes-kali-master.tar.gz
execm wget $DEB_DESKTOP_BASE
execm wget $DEB_THEMES_COMMON
execm wget $DEB_WALLPAPERS
execm wget $DEB_DEFAULTS
execm wget $DEB_TWEAKS
execm wget $DEB_MENU
execm wget $DEB_XFCE4_PANEL_PROFILES
execm wget $DEB_THEMES_ALL
execm wget $DEB_DESKTOP

dpkg -i *.deb
execm apt install -y --fix-broken
execm apt install -y lightdm-gtk-greeter-settings xfce4-goodies
cd kali-themes-kali-master
exec cp -r etc/* /etc
exec cp face-root.svg /usr/share/kali-themes
execm apt autoremove -y
execm xfce4-panel-profiles load /usr/share/xfce4-panel-profiles/layouts/Kali.tar.bz2
cd ../../

rm tmp -rf
execm reboot
