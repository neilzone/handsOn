#!/usr/bin/env bash
# -*- coding: utf-8; mode: sh -*-
# ----------------------------------------------------------------------------
# Purpose:     Glances / cross-platform system monitoring (apache)
# ----------------------------------------------------------------------------

source $(dirname ${BASH_SOURCE[0]})/setup.sh
#setupInfo
sudoOrExit

# Rverse Proxy with prefix URL e.g.: https:/myhost.org/glances did not work?
#
# https://github.com/nicolargo/glances/wiki/Start-Glances-through-Systemd
# https://github.com/nicolargo/glances/wiki/Reverse-proxy-to-the-Glances-Web-UI

# ----------------------------------------------------------------------------
# Config
# ----------------------------------------------------------------------------

WSGI_APPS="${WWW_FOLDER}/pyApps"
PYENV=pyenv

PYPI_PACKAGES="Glances Bottle"

# ----------------------------------------------------------------------------
main(){
    rstHeading "Glances" part
# ----------------------------------------------------------------------------

    case $1 in
	install)
            install_glances
	    ;;
	deinstall)
            deinstall_glances
	    ;;
	*)
            echo
	    echo "usage $0 [(de)install]"
            echo
            ;;
    esac
}
# ----------------------------------------------------------------------------
install_glances(){
    rstHeading "Installation Glances"
# ----------------------------------------------------------------------------

    rstBlock "Die Installation des Monitoring Werkzeugs Glances ${BRed}wird nur
im Intranet empfohlen${_color_Off}."

    if ! askYn "Soll Glances installiert werden?"; then
        return 42
    fi
    systemctl stop glances.service 2>&1 >/dev/null

    rstHeading "Benutzer glances" section
    echo
    TEE_stderr <<EOF | bash | prefix_stdout
    adduser glances --disabled-password --gecos "" \
           --shell /usr/sbin/nologin 2>&1 >/dev/null
EOF
    waitKEY

    rstHeading "Benötigte System Pakete" section
    rstPkgList            virtualenv python3
    echo
    apt-get install -y    virtualenv python3
    waitKEY

    rstHeading "Benötigte Python Pakete" section
    rstPkgList  ${PYPI_PACKAGES}
    echo

    export HOME=~glances
    TEE_stderr <<EOF | bash | prefix_stdout
    cd $HOME
    virtualenv --python=python3 py3
    source ~glances/py3/bin/activate
    pip install ${PYPI_PACKAGES}
EOF
    waitKEY

    rstHeading "Dienst glances.service" section
    TEMPLATES_InstallOrMerge /lib/systemd/system/glances.service root root 644
    systemctl enable glances.service
    systemctl start glances.service

    rstBlock "Dienst ist eingerichtet ..."

    rstBlock "  --> http://$HOSTNAME:61208"

    rstBlock "Die Refresh-Rate kann in Sekunden angegeben werden (default 10).
Um z.B. alle 3 Sekunden zu aktualisieren::

  --> http://$HOSTNAME:61208/3

Die Spalten mit den Prozessen können sortiert werden, dazu mit der Maus auf
z.B. 'CPU' oder 'MEM%' klicken (nicht alle Spalten können sortiert werden).
"
}

# ----------------------------------------------------------------------------
deinstall_glances(){
    rstHeading "De-Installation Glances"
# ----------------------------------------------------------------------------

    rstBlock "${BRed}ACHTUNG:${_color_Off}"
    if ! askNy "  wollen sie Glances deinstallieren?"; then
        return 42
    fi
    rstHeading "Dienst glances.service" section
    echo
    systemctl stop glances.service
    systemctl disable glances.service
    rm /lib/systemd/system/glances.service

    rstHeading "Benutzer glances" section
    echo
    userdel -r -f glances
}

# ----------------------------------------------------------------------------
main "$@"
# ----------------------------------------------------------------------------
