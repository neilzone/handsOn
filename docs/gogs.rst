.. -*- coding: utf-8; mode: rst -*-

.. include:: gogs_refs.txt
.. _xref_gogs:

=====================
Gogs / Go Git Service
=====================

Gogs_ darf sich zurecht den Titel *"A painless self-hosted Git service."* geben.
Einmal eingerichtet hat man einen recht leichtgewichtigen und komfortablen Git
Server mit überschaubaren aber praxisgerechten Team- und Zugriffs-Konzepten,
Issue-Tracker, Wiki und anderem *Klimbim*. Die Architektur scheint ebenfalls
recht sauber und entspricht in Umfang und Funktionen gängigen Standards. So gibt
es verschiedene Datenbank-Backends (SQLite, MySQL, PostgreSQL, ...) und
Authentifizierungen sind über den Austausch von Schlüsseln (SSH) sowie über
externe `Authentifizierer <https://gogs.io/docs/features/authentication>`_
möglich.

Die Installation von Gogs kann aus Paketen (APT), in vor-kompilierter /
ausführbarer Form (binary) oder aus dem Quellcode erfolgen.  Die Paket-Anbieter
wie Debian hinken jedoch meist hinter-her oder die Pakete haben Einschränkungen,
wie z.B. kein SQLite Backend. Letzteres gilt auch für eine Installation der
ausführbaren/kompilierten Programme.

Kurzum, will man eine möglichst aktuelle Lösung für einen Gogs-Server, dann muss
man sich aus den Sourcen einen eigenen Build machen. Um den Build zu erstellen,
braucht man aber wiederum eine möglichst aktuelle Go Installation. Die Go Pakete
sind z.T. aber auch sehr veraltet (z.B. bei Debian).  Zumindest muss in LTS
Versionen damit gerechnet werden, dass immer eine möglichst *aktuelle und
gekapselte* Go Installation erforderlich sein kann .. das klingt dann schon
alles nicht mehr so *painless*. Aber geht man die Sache einmal an, so merkt man
bald, dass das auch alles möglich und auch gar nicht so schwierig ist.

Hier in der Installation wird der Gogs Server, samt aller seiner Voraussetzungen
-- wie Beispielsweise die aktuelle Go (golang_) Installation -- im HOME Ordner
des Benutzers untergebracht. Dort werden auch alle Nutzdaten wie die SQLite
Datenbank abgelegt. Backup und auch Rückbau der Installation und Daten
beschränkt sich damit weitestgehend auf die Installation oder Deinstallation des
Benutzers ``gogs``.

Die hier vorgestellte Installation weist sich durch folgende besondere
Eigenschaften aus:

- komplette Installation nach ``~gogs``

- SQLite Datenbank

- PAM Authentifizierung

  .. todo::

     https://discuss.gogs.io/t/pam-authentication-fails/602/4

- Gogs Server wird hinter einer (Apache-) URL ``https://<hostname>/gogs``
  betrieben (s.a. :origin:`gogs.conf
  <templates/etc/apache2/sites-available/gogs.conf>` & `ProxyPass
  <http://httpd.apache.org/docs/2.2/mod/mod_proxy.html#ProxyPass>`_).

Zur Installation existiert ein Script, das alle Setups vornimmt::

   $ ${SCRIPT_FOLDER}/gogs.sh install server

Im Einzelnen führt das Skript in etwa folgende Schritte aus:

1. Es werden die erforderlichen Systempakete installiert. Für PAM
   ``libpam0g-dev`` und für SQLite ``libsqlite3-0``::

     sudo apt install libpam0g-dev libsqlite3-0

2. Es wird der Benutzer ``$GOGS_USER`` (``gogs``) angelegt. Sein ``$HOME`` ist
   ``/home/gogs`` und in diesen Ordner wird alles weitere installiert.::

     GOGS_HOME=/home/gogs
     sudo adduser --shell /bin/bash --system --home $GOGS_HOME \
                  --group --gecos 'Gogs' $GOGS_USER

   Für die Go & Gogs Umgebung wird eine ``$GOGS_HOME/.env_gogs`` Datei angelegt,
   die bei Bedarf eingelesen (``source``) werden kann. Die Installationen zu den
   Go & Gogs Pfaden (``local/go/bin`` & ``local/gogs``) werden folgend dann noch
   vorgenommen::

     export PATH=$PATH:$HOME/local/go/bin:$HOME/local/gogs
     export GOPATH=$HOME/go-apps

3. Die Go Installation (s.a. go-linux_ && goX.YY.linux-amd64.tar.gz_) erfolgt
   nach nach ``$HOME/local``::

     GO_TAR=go1.11.linux-amd64.tar.gz
     wget https://dl.google.com/go/${GO_TAR}
     mkdir -p $HOME/local
     rm -rf $HOME/local/go
     tar -C $HOME/local -xzf ${GO_TAR}

   Dann noch ein einfacher Test der Go Umgebung::

     sudo -i -u $GOGS_USER
     source ~/.env_gogs
     env
     ! which go &&  echo "Go Installation not found in PATH!?!"
     which go &&  echo "congratulations, Go Installation OK :)"

4. Mittels ``go get`` werden im $HOME die Quellen von Gogs heruntergeladen
   (s.a. Go-VCS-Projects_)::

     sudo -i -u $GOGS_USER
     source ~/.env_gogs
     mkdir -p "${GOPATH}"

     GOGS_URI=github.com/gogs/gogs
     go get -v -u -tags "sqlite pam" $GOGS_URI

   .. hint::

      Die URI muss sein ``github.com/gogs/gogs`` und nicht mehr
      ``github.com/gogits/gogs`` (gogits ist falsch!), wie in einigen älteren
      Dokumentationen noch häufig zu finden (ChangeLog `0.11.53@2018-06-05
      <https://gogs.io/docs/intro/change_log#0.11.53-%40-2018-06-05>`_).

5. Es wird ein Build der Gogs Sourcen im ``$HOME`` erzeugt::

     cd "${GOPATH}/src/$GOGS_URI"
     go build -v -tags "sqlite pam"

6. Der *build*, die gebaute Gogs-Software wird nach ``$HOME/local`` installiert.::

     rm -rf $HOME/local/gogs
     cp -fr gogs LICENSE public README.md README_ZH.md scripts templates $HOME/local/gogs

   Das Basis-Konfiguration der Gogs Instanz wird in einer :origin:`app.ini
   <templates/home/gogs/local/gogs/custom/conf/app.ini>` Datei vorgenommen.
   Ersetzungen::

     # Domain in welcher der Gogs Server lauscht:
     GOGS_DOMAIN=127.0.0.1
     GOGS_PORT=3000

   Eine vollständige Auflistung der Konfigurationen gibt das `Gogs Configuration
   Cheat Sheet`_. Im Default erwartet Gogs die ``app.ini`` im Ordner::

     mkdir -p $HOME/local/gogs/custom/conf

7. Es wird ein rudimentärer Test der Gogs-Installation durchgeführt. In der
   app.ini ist die Domain und der Port des Gogs Servers definiert, gegen den wir
   uns nun von der Client-Seite aus verbinden wollen::

     timeout 20 $HOME/local/gogs/gogs web
     sleep 5
     curl --location --verbose --head --insecure http://$GOGS_DOMAIN:$GOGS_PORT 2>&1

8. Die Gogs Installation wird mit der Service-Unit_ Datei
   :origin:`/lib/systemd/system/gogs.service <templates/lib/systemd/system/gogs.service>`
   im systemd_ eingerichtet::

     sudo systemctl enable gogs.service
     sudo systemctl restart gogs.service

9. Apache Site :origin:`/etc/apache2/sites-available/gogs.conf
   <templates/etc/apache2/sites-available/gogs.conf>` mit ProxyPass_
   einrichten. Ersetzungen::

     # Apache Redirect URL
     GOGS_APACHE_DOMAIN="$(uname -n)"
     GOGS_APACHE_URL="/gogs"

   Proxy und gogs.conf aktivieren::

     sudo a2enmod proxy_http
     sudo a2ensite -q gogs
     sudo apachectl configtest
     sudo service apache2 force-reload

.. hint::

   Der Gogs-Dienst ist nun vollständig eingerichtet und steht im Internet zur
   Verfügung::

      xdg-open https://$(uname -n)/gogs

   Gogs muss **JETZT online** eingerichtet werden!!!

     Das erste Login ist ein Admin Login ... oder wie ist das genau!?!?!?!





