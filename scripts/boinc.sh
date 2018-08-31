#!/usr/bin/env bash
# -*- coding: utf-8; mode: sh -*-
# ----------------------------------------------------------------------------
# --                             --  File:     boink.sh
# -- Copyright (C) 2015 darmarIT --  Author:   Markus Heiser
# --     All rights reserved     --  mail:     markus.heiser@darmarIT.de
# --                             --  http://www.darmarIT.de
# ----------------------------------------------------------------------------
# Purpose:     install cannon MX860 printer/scanner
# ----------------------------------------------------------------------------

source $(dirname ${BASH_SOURCE[0]})/setup.sh
#setupInfo
sudoOrExit

# ----------------------------------------------------------------------------
# Config
# ----------------------------------------------------------------------------

# 'boinc' ist nur ein Meta-Paket. Für die vollständige Deinstallation müssen die
# Pakete boinc-[manager|client] expliziet aufgelistet werden

BOINC_PACKAGES="\
 boinc boinc-manager boinc-client \
"

# This is the data directory of the BOINC core client.
BOINC_DIR="/var/lib/boinc-client"

if [ -e $BOINC_INIT_DEFAULTS ]; then
    . $BOINC_INIT_DEFAULTS
fi

BOINC_INIT_DEFAULTS=/etc/default/boinc-client

CONFIG_BACKUP=(
    "$BOINC_INIT_DEFAULTS"
    "/etc/init.d/boinc-client"
    "/etc/boinc-client/gui_rpc_auth.cfg"
    "/etc/boinc-client/remote_hosts.cfg"
)

CONFIG_BACKUP_ENCRYPTED=(
)


# ----------------------------------------------------------------------------
usage(){
# ----------------------------------------------------------------------------
    cat <<EOF

$1

usage:
  $(basename $0) install    [boinc]
  $(basename $0) remove     [boinc]
  $(basename $0) activate   [boinc-client]
  $(basename $0) deactivate [boinc-client]

EOF
}

# ----------------------------------------------------------------------------
main(){
    rstHeading "BOINC" part
# ----------------------------------------------------------------------------

    case $1 in
        install)
            sudoOrExit
            case $2 in
                boinc)    install_boinc ;;
                *)       usage "${BRed}ERROR:${_color_Off} unknown or missing install command $2"; exit 42;;
            esac ;;
        remove)
            sudoOrExit
            case $2 in
                boinc)    remove_boinc ;;
                *)       usage "${BRed}ERROR:${_color_Off} unknown or missing install command $2"; exit 42;;
            esac ;;
        activate)
            sudoOrExit
            case $2 in
                boinc-client)  activate_boinc_client ;;
                *)       usage "${BRed}ERROR:${_color_Off} unknown or missing install command $2"; exit 42;;
            esac ;;
        deactivate)
            sudoOrExit
            case $2 in
                boinc-client)  deactivate_boinc_client ;;
                *)       usage "${BRed}ERROR:${_color_Off} unknown or missing install command $2"; exit 42;;
            esac ;;
        *) usage "${BRed}ERROR:${_color_Off} unknown or missing command $1"; exit 42
    esac
}

# ----------------------------------------------------------------------------
activate_boinc_client () {
    rstHeading "Aktivieren des BOINC-Client (service)" section
# ----------------------------------------------------------------------------
    echo ""
    if [ "$ENABLED" != "1" ]; then
        err_msg "BOINC client is not enabled ($BOINC_INIT_DEFAULTS)"
      exit 1
    fi
    TEE_stderr <<EOF | bash 2>&1 | prefix_stdout
systemctl enable boinc-client.service
systemctl restart boinc-client.service
EOF
    TEE_stderr <<EOF | bash 2>&1 | prefix_stdout
systemctl status boinc-client.service
EOF
    #_dump_ps
}

# ----------------------------------------------------------------------------
deactivate_boinc_client () {
    rstHeading "De-Aktivieren des BOINC-Client (service)" section
# ----------------------------------------------------------------------------
    echo ""

    TEE_stderr <<EOF | bash 2>&1 | prefix_stdout
systemctl stop boinc-client.service
systemctl disable boinc-client.service
EOF
    if [ "$ENABLED" == "0" ]; then
        err_msg "BOINC client is already enabled see ENABLED in $BOINC_INIT_DEFAULTS"
      exit 1
    fi
    #_dump_ps
}


# ----------------------------------------------------------------------------
install_boinc(){
# ----------------------------------------------------------------------------

    rstHeading "Installation BOINC"

    rstBlock_stdin <<EOF
Für die BOINC Installation werden folgende Pakete installiert.
EOF
    rstPkgList ${BOINC_PACKAGES}
    waitKEY 10
    apt-get install -y ${BOINC_PACKAGES}

    rstHeading "BOINC Einstellungen" section

    TEMPLATES_InstallOrMerge /etc/boinc-client/gui_rpc_auth.cfg root boinc 640
    waitKEY
    TEMPLATES_InstallOrMerge /etc/boinc-client/remote_hosts.cfg root boinc 644
    waitKEY

    rstHeading "BOINC (client) Dienst" section

    # revert des Pull_Requests:
    #   https://github.com/BOINC/boinc/pull/2260/commits
    #
    echo -e "
Die Installation des BOINC Dienst (boinc-client) ist etwas durcheinander. Es
werden sowohl die System-D Unit 'boinc-client.service' als auch das System-V
init.d-Skript (/etc/init.d/boinc-client) installiert.  Zumindest wenn ein
/etc/init.d Ordner existiert, was auf den meisten Systemen der Fall sein
dürfte. Lediglich das System-V init.d-Skript liest das init.d-Setup in der Datei
/etc/default/boinc-client aus. Die System-D Unit 'boinc-client.service'
ignoriert das init.d-Setup (in /etc/default/boinc-client) [1].

Die System-D Unit 'boinc-client.service' ist kein gleichwertiger Ersatz für das
System-V init.d-Skript, da sie nicht das init.d-Setup auswertet, in dem man
ggf. Einstellungen vornehmen möchte, wie z.B::
${BYellow}
    BOINC_OPTS=\"--allow_remote_gui_rpc\"
${_color_Off}
Ich empfehle deshalb die System-D Unit 'boinc-client.service' ganz zu
deinstallieren::
${BYellow}
    $ sudo systemctl disable boinc-client.service
    $ sudo mv -f /lib/systemd/system/boinc-client.service /lib/systemd/system/boinc-client.service.bak
    $ sudo systemctl daemon-reload
${_color_Off}
Wenn es keine System-D Unit für den boinc-client gibt, wird über das System-D
mit dem 'systemd-sysv-generator' [2] das init.d-Skript automatisch als Dienst
(System-D Unit) angeboten, dieses wertet dann auch wieder das init.d-Setup aus::
${BYellow}
    $ systemctl start boinc-client.service
    $ systemctl status boinc-client.service
${_color_Off}
[1] https://unix.stackexchange.com/questions/203987/debian-services-not-running/204075#204075
[2] https://www.freedesktop.org/software/systemd/man/systemd-sysv-generator.html"
    waitKEY

    rstHeading "System-D Unit 'boinc-client.service' deinstallieren" section
    echo
    TEE_stderr 3 <<EOF | bash 2>&1 | prefix_stdout
systemctl stop boinc-client.service
systemctl disable boinc-client.service
killall -9 boinc
mv -f /lib/systemd/system/boinc-client.service /lib/systemd/system/boinc-client.service.bak
EOF

    rstHeading "System-V init.d-Script reparieren/austaschen"

    rstBlock "Leider ist auch das init.d-Skript noch etwas fehlerhaft. Weshalb
dieses auch gleich mit ausgetauscht wird."

    TEMPLATES_InstallOrMerge /etc/init.d/boinc-client root root 755

    ## mkdir $BOINC_DIR 2>/dev/null || true
    ## chown -h boinc:boinc $BOINC_DIR 2>/dev/null || true
    systemctl daemon-reload
    waitKEY

    rstBlock "Es wird das init.d-Setup eingespielt"
    TEMPLATES_InstallOrMerge /etc/default/boinc-client root root 644
    waitKEY

    rstBlock "Nun kann der BOINC (client) Dienst gestartet werden"
    TEE_stderr <<EOF | bash 2>&1 | prefix_stdout
systemctl daemon-reload
systemctl start boinc-client.service
systemctl status boinc-client.service
EOF
    #_dump_ps
    waitKEY
}

# ----------------------------------------------------------------------------
remove_boinc() {
# ----------------------------------------------------------------------------

    rstHeading "De-Installation BOINC"

    if ! askYn "Soll BOINC deinstalliert werden?"; then
        return
    fi

    deactivate_boinc_client
    aptPurgePackages ${BOINC_PACKAGES}
    #_dump_ps
    waitKey
}


_dump_ps() {
    rstHeading "laufende BOINC Prozesse ..." section
    TEE_stderr <<EOF | bash 2>&1 | prefix_stdout
ps -e -o pid,ppid,user,%cpu,%mem,args | grep boinc
EOF
    waitKEY
}

# ----------------------------------------------------------------------------
main "$@"
# ----------------------------------------------------------------------------
