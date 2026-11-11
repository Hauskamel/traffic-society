# Git-Arbeitsablauf

## Branches

- `main`: stabiler, geprüfter Stand. Enthält zu Beginn den hochgeladenen spielbaren Ausgangsstand und die Dokumentation.
- `develop`: Integration der laufenden Entwicklung.
- `feature/<name>`: einzelne abgestimmte Funktionen, jeweils von `develop` abgeleitet.
- `fix/<name>`: gezielte Fehlerbehebungen, normalerweise ebenfalls von `develop` abgeleitet.

Ein zusätzlicher `master`-Branch wird nicht verwendet.

## Ablauf

1. Umfang einer Änderung gemeinsam festlegen.
2. `develop` aktualisieren und einen passenden Feature-Branch erstellen.
3. Änderung implementieren, im Spiel prüfen und Entwicklungsschritte dokumentieren.
4. Pull Request nach `develop` erstellen und nach Prüfung übernehmen.
5. Einen gemeinsam geprüften spielbaren Stand von `develop` nach `main` übernehmen.

Beispiel für einen später freigegebenen Schritt:

```sh
git switch develop
git pull --ff-only origin develop
git switch -c feature/erstes-fahrzeug
```

## Dateien

Quellcode, Szenen, Modelle und Godot-UID-Dateien gehören ins Repository. Der generierte `.godot`-Cache, lokale Exportdateien, temporäre Dateien und Zugangsdaten gehören nicht hinein. Bei `export_presets.cfg` vor dem Commit sicherstellen, dass keine lokalen vertraulichen Werte enthalten sind.

Große Binärdateien können bei Bedarf später über Git LFS verwaltet werden. Der aktuelle Prototyp benötigt das noch nicht.

## Erster Projektimport – durchgeführt

Der funktionierende Windows-Stand wurde mit `project.godot`, `main.tscn`, `main.gd` und `main.gd.uid` übernommen. Generierte Inhalte aus `.godot` wurden ausgeschlossen. `main` und `develop` starten am selben Commit. Zukünftige Änderungen erfolgen nach dem oben beschriebenen Ablauf.

## Aktueller Entwicklungszweig

PR #1, PR #2 und PR #4 wurden nach `develop` übernommen. Der aktive Branch `feature/vehicleDamage` enthält die Fahrzeugschäden und den daraus aktualisierten `develop`-Stand einschließlich direkter Ladungsauswahl und Kühlboxen. PR #3 bleibt der separate Vorschlag zur Übernahme der Fahrzeugschäden nach `develop`. `main` bleibt unverändert.
