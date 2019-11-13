.. -*- coding: utf-8; mode: rst -*-
.. include:: ../print_scan_refs.txt

.. _cups:

===============
CUPS Grundlagen
===============

Die Drucker-Verwaltung unter Linux ist das Common Unix Printer System `CUPS
(wiki)`_ [`git <https://github.com/apple/cups>`_], welche i.d.R. in jedem Linux
Desktop-System bereits vorinstalliert ist.  CUPS unterstützt 2D (Papier) und ab
V2.1 auch 3D Druck (s.a `IPP 3D`_).  Wie das **S**\ *ystem* in CUP\ **S**
bereits andeutet handelt es nicht um einen *schlichten* Drucker Treiber sondern
um ein *Druck-System*, das Dienste rund um das Thema "Drucken" im Netzwerk
bereit stellt.  Auf Server Systemen ist CUPS ggf. noch nicht installiert, kann
aber recht einfach installiert werden::

   sudo -H apt-get install cups cups-client cups-bsd

CUPS wird grundsätzlich immer als Dienst (http://localhost:631) eingerichtet,
d.h. es läuft nicht im Kontext eines bestimmten Benutzers, sondern kann von
allen Benutzern des Systems genutzt werden (*logisch*).

  Die *Idee von CUPS* ist, dass alle Drucker (-Funktionen) in einem Dienst, auf
  einem Host (*dem zentralen CUPS Server*) vereint werden.  Die Clients (Desktop
  Systeme, mobile Geräte etc.) können über *den zentralen CUPS Server* ihre
  Druck-Anforderungen abwickeln, ohne das dazu auf jedem dieser Geräte ein
  Druckertreiber oder eine spezielle Druckfunktion installiert werden muss.

Im Kapitel ":ref:`printer_setup`" wird der Umgang mit der GUI
(:ref:`system-config-printer <figure-cups-system-config-printer-gui>` )
beschrieben.  Dort wird auch erläutert, dass nur Nutzer der Gruppe ``lpadmin``
Änderungen an den Druckereinstellungen vornehmen können, weshalb man sich selbst
am besten noch zu der Gruppe ``lpadmin`` hinzufügt::

  $ sudo -H gpasswd -a <benutzername> lpadmin
  $ sudo -H gpasswd -a <benutzername> lp

Gespeichert werden die Druckereinstellungen in den PPD Dateien, siehe Kapitel
":ref:`ppd_spec`".

CUPS-Backend
  Im Backend des CUPS, werden die Druckertreiber registriert.  Da bietet CUPS
  z.T. generische Treiber an, die i.d.R. schon sehr gut funktionieren.  Alle
  halbwegs modernen Netzwerk-Drucker unterstützen das IPP_, welches auch in CUPS
  *integriert* ist, darauf basierend wird dann auch ":ref:`driverless-printing`"
  in CUPS ermöglicht.

CUPS-Filter
  Vor dem Backend, also *auf dem Weg hin zu den Druckern* gibt es sogenannte
  CUPS-Filter, welche die Druck-Daten der Clients so aufbereiten, das der
  Drucker sie verarbeiten kann (siehe auch Kapitel ":ref:`debug_dump_to_file`").

  Hier in diesem Artikel wird beispielsweise ein Canon Drucker eingerichtet, der
  bietet zwar das IPP_, *spricht* aber weder `Postscript (wiki)`_ noch PDF_.
  Als *Seitenbeschreibungssprache* `PDL (wiki)`_ kennt der nur UFR-II
  (:ref:`figure-MF623Cn-printer-spec`).  Im Kapitel ":ref:`IPP_intro`" wird
  erläutert, wie mit dem ``image/pwg-raster`` Format (das alle IPP-fähigen
  Drucker anbieten müssen) dennoch auf diesem Drucker mittels CUPS Filter und
  einem generischen Druckertreiber gedruckt werden kann.

.. note::

   `CUPS (git)`_ wird von Apple entwickelt, mit der Version 1.6. hat sich Apple
   entschieden einige der Funktionen (CUPS-Filter) zu entfernen, die in auf
   macOS nicht genutzt werden.  Die Weiterentwicklung dieser Komponenten findet
   nun im `cups-filters`_ Projekt statt.  Auf einem Linux Desktop ist das Paket
   :deb:`cups-filters` i.d.R. bereits installiert::

	  sudo -H apt install cups-filters

   Das Kommando :man:`cupsfilter` mit dem auch Tests vorgenommen werden können
   :ref:`[ref] <cupsfilter-command>` gehört zu den Basis-Kommandos und ist nach
   wie vor im `CUPS (git)`_ resp im Paket :deb:`cups` enthalten .
