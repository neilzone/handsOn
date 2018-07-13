#!/usr/bin/env bash
# -*- coding: utf-8; mode: sh -*-
# ----------------------------------------------------------------------------
# Purpose:     Desktop Setup
# ----------------------------------------------------------------------------

source $(dirname ${BASH_SOURCE[0]})/setup.sh
sudoOrExit

# ----------------------------------------------------------------------------
# Config
# ----------------------------------------------------------------------------

GNOME3_PPA="ppa:gnome3-team/gnome3"
GNOME_SHELL_EXTENSIONS="/usr/share/gnome-shell/extensions"

GNOME3_PACKAGES="\
 language-pack-gnome-de \
 gnome-core gnome-screenshot\
 gnome-session \
 gnome-getting-started-docs-de \
 gnome-power-manager gnome-tweak-tool gconf-editor \
 gnome-packagekit gnome-packagekit-session \
 vanilla-gnome-desktop \
 elementary-icon-theme \
 gir1.2-gtop-2.0 gir1.2-networkmanager-1.0 \
"
# ubuntu-gnome-default-settings \

DISPLAY_MANAGER_PACKAGES="\
  gdm3 \
  lightdm lightdm-webkit-greeter \
"
#  sddm \
#  kdm \
#  ldm \

CINNAMON_PACKAGES="cinnamon-desktop-environment"
MATE_PACKAGES="\
  mate-desktop mate-desktop-common mate-desktop-environment-core\
  mate-notification-daemon-common\
  mate-polkit-common"

UNITY_REMOVE_PACKAGES="$(dpkg-query -f '${binary:Package} ' -W 'unity*')  ubuntu-gnome-desktop \
 ubuntu-gnome-wallpapers \
"

# elementary
# ----------
#
# Die Installation ist nicht mit ubuntu 15.04 oder 15.10 möglich. Erst ab 16.04
# scheint es wieder einen Support in dem PPA zu geben (zumindest in daily
# scheint was vorgesehen).
#
# Bevor man das PPA wechselt sollte man zuvor remove_elementary aufgerufen
# haben. Ansonsten verbleiben ggf. noch *Paketreste* aus dem alten PPA.
#
# siehe https://launchpad.net/~elementary-os
#
#ELEMENTARY_PPA="ppa:elementary-os/stable"
#ELEMENTARY_PPA="ppa:elementary-os/daily"
ELEMENTARY_PPA="ppa:elementary-os/staging"

usage(){
    cat <<EOF

$1

usage:
  $(basename $0) [chooseDM]
  $(basename $0) install [GNOME|GNOME3-PPA|elementary|cinnamon|mate]
  $(basename $0) remove  [unity|GNOME3-PPA|elementary|cinnamon|mate]

- GNOME: GNOME3 shell https://wiki.gnome.org/Projects/GnomeShell
- GNOME3-PPA: PPA für GNOME3, ab ubuntu 18.04 nicht mehr erforderlich
- elementary: Desktop des elementary-OS https://elementary.io/#desktop-development
- cinnamon: Alter GNOME-Desktop, der von Linux-Mint weiter entwickelt wird
- mate: Mate-Desktop https://mate-desktop.org/
EOF
}




# ----------------------------------------------------------------------------
main(){
    rstHeading "Desktop System" part
# ----------------------------------------------------------------------------

    sudoOrExit
    case $1 in
        chooseDM) chooseDM ;;
        install)
            case $2 in
                GNOME3-PPA)   install_gnome3_ppa   ;;
                GNOME)        install_gnomeShell   ;;
                elementary)   install_elementary   ;;
	        cinnamon)     TITLE="Installation Cinnamon-Desktop" aptInstallPackages ${CINNAMON_PACKAGES}    ;;
	        mate)         TITLE="Installation Mate-Desktop"  aptInstallPackages ${MATE_PACKAGES}           ;;
                *)            usage "${BRed}ERROR:${_color_Off} unknown or missing install command $2"; exit 42          ;;
            esac  ;;
        remove)
            case $2 in
                GNOME3-PPA)   remove_gnome3_ppa   ;;
                elementary)   remove_elementary   ;;
                unity)        remove_unity ;;
                cinnamon)     TITLE="De-Installation Cinnamon-Desktop" aptPurgePackages ${CINNAMON_PACKAGES}   ;;
                mate)         TITLE="De-Installation Mate-Desktop" aptPurgePackages ${MATE_PACKAGES}           ;;
                *)            usage "${BRed}ERROR:${_color_Off} unknown or missing remove command $2"; exit 42           ;;
            esac  ;;
        *) usage "${BRed}ERROR:${_color_Off} unknown or missing command $1"; exit 42
	   ;;
    esac
}


# ----------------------------------------------------------------------------
chooseDM() {
    rstHeading "Auswahl eines DISPLAY Managers"
# ----------------------------------------------------------------------------
    echo
    apt-get install -y ${DISPLAY_MANAGER_PACKAGES}
    dpkg-reconfigure lightdm

    # FIXME: in 1510 funktioniert das lightdm-webkit-greeter Paket nicht. Man
    # muss es mit *irgendwelchen* anderen Paketen installieren. Welche Pakete
    # das sind weiß ich nicht. Ich merke nur, dass es mal funktioniert mal nicht
    # und ich sehe in den LOGs (/var/log/lightdm/), dass da noch was ziemlich
    # buggy zu sein scheint. Z.B. wird ein LOG-Ordner unter
    # /var/log/lightdm/<user-name> angelegt. Der *Greeter* selber versucht dann
    # aber unter /var/lib/lightdm/ seine Daten abzulegen, was am Ende scheitert.

    mkdir -p /var/lib/lightdm
    chown lightdm:lightdm /var/lib/lightdm

    # Diese kleine Workaround reicht allerdings noch nicht. Ich gebe das an
    # dieser Stelle auf, mit scheint das Paket einfach nur Buggy zu sein.  Siehe
    # https://launchpad.net/lightdm-webkit-greeter/trunk In Ubuntu 1504 wird
    # Version 0.1.2 genutzt, das ist von 2012. Inzwischen gibt es *volle*
    # Versionsnummern, z.B 1.0.0 vom Oktober 2015 und 2.0.0 vom Jan. 2016. Beide
    # haben es aber in noch keine Distro geschafft, selbst in 1604 ist momentan
    # noch
    #
    # * https://launchpad.net/lightdm-webkit-greeter/trunk
    # * https://launchpad.net/ubuntu/xenial/+source/lightdm-webkit-greeter

    waitKEY
}


# ----------------------------------------------------------------------------
install_elementary() {
    rstHeading "Installation elementary"
# ----------------------------------------------------------------------------

    rstBlock ".. hint::

  Die Installation ist nicht mit ubuntu 15.04 oder 15.10 möglich. Erst
  ab 16.04 scheint es wieder einen Support in dem PPA zu geben."

    if askYn "Soll die Installation durchgeführt werden?"; then
        echo
        rstBlock "deinstaliere ggf. vorhandene Pakete"
        apt-get purge elementary-desktop
        waitKEY

        rstBlock "add PPA: ${Yellow}${ELEMENTARY_PPA}${_color_Off}"
        add-apt-repository --yes "${ELEMENTARY_PPA}"
        waitKEY

        apt-get update
        apt-get install elementary-desktop
    else
        rstBlock "Installation von elementary-desktop abgebrochen."
    fi
    waitKEY
}

# ----------------------------------------------------------------------------
remove_elementary() {
    rstHeading "De-Installation elementary"
# ----------------------------------------------------------------------------

    rstBlock "deinstaliere ggf. vorhandene Pakete"
    apt-get purge elementary-desktop
    waitKEY
    rstBlock "remove PPA: ${Yellow}${ELEMENTARY_PPA}${_color_Off}"
    add-apt-repository --yes --remove "${ELEMENTARY_PPA}"
    apt-get update
    waitKEY
}

install_gnome3_ppa() {
# ----------------------------------------------------------------------------
    rstHeading "GNOME3 Team PPA"
# ----------------------------------------------------------------------------

    rstBlock ".. hint::

  Die Installation des PPA für die GNOME3 Shell ist mit ubuntu 18.04 nicht mehr
erforderlich."

    if askYn "Soll gnome3 PPA eingerichtet werden?"; then
        apt-get install -y ppa-purge
	ppa-purge ${GNOME3_PPA}
        add-apt-repository --yes "${GNOME3_PPA}"
        waitKEY
        apt-get update
    else
        rstBlock "Setup des PPA abgebrochen."
    fi
    waitKEY
}

remove_gnome3_ppa() {
# ----------------------------------------------------------------------------
    rstHeading "Deinstallation GNOME3 Team PPA"
# ----------------------------------------------------------------------------

    echo
    if askYn "Soll gnome3 ppa entfernt werden?"; then
        apt-get install -y ppa-purge
	ppa-purge ${GNOME3_PPA}
        add-apt-repository --yes --remove "${GNOME3_PPA}"
        waitKEY
        apt-get update
    else
        rstBlock "Emtfernen des PPA wurde abgebrochen."
    fi
    waitKEY
}

# ----------------------------------------------------------------------------
remove_unity(){
    rstHeading "De-Installation von Unity"
# ----------------------------------------------------------------------------

    rstPkgList ${UNITY_REMOVE_PACKAGES}
    if askYn "Soll Unity komplett deinstalliert werden?"; then
        apt-get purge --ignore-missing -y ${UNITY_REMOVE_PACKAGES}
        apt-get -y autoremove
    fi
}


# ----------------------------------------------------------------------------
install_gnomeShell(){
    rstHeading "Gnome-Shell"
# ----------------------------------------------------------------------------

    rstPkgList ${GNOME3_PACKAGES}

    if ! askYn "Sollen die Gnome-Shell Pakete installiert werden?"; then
        return 42
    fi
    echo
    apt-get install -y ${GNOME3_PACKAGES}
    rstHeading "Installation der Gnome-Shell Extensions"

    # https://github.com/paradoxxxzero/gnome-shell-system-monitor-applet

    rstHeading "gnome-shell: system-monitor" section
    echo

    local _gitUrl="https://github.com/paradoxxxzero/gnome-shell-system-monitor-applet.git"
    local _folder="gnome-shell-system-monitor-applet"
    local _dst="${GNOME_SHELL_EXTENSIONS}/system-monitor@paradoxxx.zero.gmail.com"
    cloneGitRepository \
        "$_gitUrl" \
        "$_folder"
    rstBlock "install extension into $_dst"
    rm -rf "$_dst"
    cp -r "${CACHE}/${_folder}/system-monitor@paradoxxx.zero.gmail.com" "${GNOME_SHELL_EXTENSIONS}"
    waitKEY

    rstHeading "Deinstallation Unity"

    rstBlock "Es wurde der Gnome-Shell Desktop installiert. Der Desktop Unity
ist damit nicht weiter erforderlich. Unity kann mit allen seinen Komponenten
deinstalliert werden."

    remove_unity
}

# ----------------------------------------------------------------------------
main "$@"
# ----------------------------------------------------------------------------
