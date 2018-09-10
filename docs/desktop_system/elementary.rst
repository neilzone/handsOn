.. -*- coding: utf-8; mode: rst -*-

.. include:: ../desktop_system_refs.txt

.. _xref_elementary:

================================================================================
                             Elementary OS Desktop
================================================================================

.. todo::

   Dieser Artikel wurde noch nicht mit Ubuntu 18.04 getestet. Siehe PPA:

   - https://launchpad.net/~elementary-os/+archive/ubuntu/stable

Die Desktop-Umgebung des `elementary OS`_ Betriebsystems kann auch in den Ubuntu
Derivaten installiert werden. In den aktuellen Paketquellen ist `elementary OS
(wiki)`_ Desktop jedoch nicht enthalten. Das `elementary-os team`_ stellt
hierfür PPAs bereit.

Die PPAs vom `elementary-os team`_ paketieren jedoch nichts für Ubuntu 15.04 und
15.10. Erst mit *xenial* (16.04) scheint es wieder einen Support zu geben.
Zumindest kann man aktuell (Stand 02/2016) sehen, dass sich was in den PPAs tut.


Installation
============

In dem ``${SCRIPT_FOLDER}`` Ordner befindet sich ein Skript, mit dem die das PPA
und der elementary Desktop Umgebung installiert werden kann::

  $ sudo ./scripts/desktop_system.sh install elementary

Mit dem Skript wird auch ein PPA eingerichtet (:man:`add-apt-repository`). Das
PPA sollte nicht gelöscht werden, solange noch Pakete aus dem PPA installiert
sind. Zur vollständigen De-Installation empfiehlt sich daher das Kommando
``desktop_system.sh remove elementary``.

De-Installation
===============

Zur vollständigen De-Installation eignet sich::

  $ sudo ./scripts/desktop_system.sh remove elementary

Das Kommando deinstalliert zuerst die elementary OS Desktop-Umgebung und löscht
dann das PPA.
