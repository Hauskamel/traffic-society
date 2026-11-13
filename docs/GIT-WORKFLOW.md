# Git-Arbeitsablauf

[Git-Branches als visuelle Buslinie](BRANCHES.md) · Abzweigungen, Merges und aktueller Branch-Status.

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

Der funktionierende Windows-Stand wurde mit `project.godot`, `game/world/main.tscn`, `game/world/main.gd` und `game/world/main.gd.uid` übernommen. Generierte Inhalte aus `.godot` wurden ausgeschlossen. `main` und `develop` starten am selben Commit. Zukünftige Änderungen erfolgen nach dem oben beschriebenen Ablauf.

## Aktueller Entwicklungszweig

PR #1, PR #2 und PR #4 wurden nach `develop` übernommen. Der aktive Branch `feature/vehicleDamage` enthält die Fahrzeugschäden und den daraus aktualisierten `develop`-Stand einschließlich direkter Ladungsauswahl und Kühlboxen. PR #3 bleibt der separate Vorschlag zur Übernahme der Fahrzeugschäden nach `develop`. `main` bleibt unverändert.

## Körperphysik-Labor

Nach Übernahme von PR #3 enthält `develop` sowohl die erweiterte Fahrzeugdurchsuchung als auch die Fahrzeugschäden. `feature/bodPhysics` wurde von diesem Stand erstellt und ergänzt ein separates aktives Ragdoll-Testlabor. Änderungen werden separat nach `develop` vorgeschlagen.

## Körperphysik übernommen

PR #5 ist mit „Merge Körperphysik“ nach `develop` zusammengeführt. Künftige Features starten von diesem aktualisierten Stand. Commit-Betreffzeilen bleiben kurz und beschreiben die Änderung; Einzelheiten gehören in die Dokumentation oder PR-Beschreibung.

## Strukturüberarbeitung

`feature/projectStructure` startet vom aktualisierten `develop`. Verschiebungen und Ressourcenpfade sind im kurzen Commit „Projekt geordnet“ getrennt von Kommentaren und Formatierung nachvollziehbar. Der Branch enthält keine neuen Spielfunktionen.

## Funkgerät-Vorschau

`feature/policeWalkieTalkie` basiert auf dem strukturierten `develop`. Der Branch enthält LCD und drei verbundene Einsatzknöpfe mit begrenzten Anforderungen, verzögertem Spawn sowie Fahrzeugen/Besatzungen. Die Einsatzkräfte steigen aus und laufen umher; fachliche Aufgaben folgen später.
