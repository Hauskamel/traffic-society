# Projektstruktur

Das Projekt ist nach Spielsystemen gegliedert. Szenen, Skripte und eng zugehörige Darstellung eines Systems liegen zusammen. Dadurch bleibt beispielsweise die Fahrzeuglogik an einem Ort, statt zwischen einem globalen Skript- und Szenenordner verteilt zu sein.

## Verzeichnisse

```text
traffic-society/
├── project.godot                 # Godot-Projekt und Startszene
├── README.md                     # Einstieg, Bedienung und Funktionsstand
├── .editorconfig                 # Editorübergreifende Textregeln
├── game/                         # Wiederverwendbare Spielfunktionen
│   ├── world/                    # main.tscn + main.gd: Kontrollplatz und Koordination
│   ├── config/                   # Geschwindigkeiten und Interaktionszeiten
│   ├── actors/
│   │   ├── npc/                  # Fahrer, Aufgabe und Personeninteraktionen
│   │   └── physics/              # Gemeinsame Körperphysik
│   ├── player/                   # Ausrüstung, Gesundheit und Klettern
│   ├── weapons/                  # Waffenmodelle, Schüsse und Projektilverfolgung
│   ├── traffic/                  # Begegnungsbestand, Abstände und Parkreservierung
│   ├── vehicles/                 # Fahrzeuge, Öffnungen und Fahrzeugschäden
│   ├── inventory/                # Inventardaten, Oberfläche und Gegenstandsvorschau
│   ├── inspection/               # Ladungsziele, Behältermodelle und Untersuchung
│   ├── documents/                # Dokumentdaten, Karten und Prüfungsmodus
│   └── police/                   # Streifenabholung und Polizeidarstellung
├── prototypes/                   # Isolierte Entwicklungsumgebungen
│   ├── body_physics/             # Physiklabor mit eigener Szene und Steuerung
│   └── combat/                   # Ego-Konfrontation und fester Testgegner-Ablauf
├── assets/
│   ├── audio/                    # Tondateien
│   ├── effects/                  # Effekttexturen
│   └── items/                    # Gegenstandssymbole
├── tests/                        # Nach Spielsystem gruppierte Integrationsprüfungen
├── tools/                        # Entwicklungswerkzeuge, nicht vom Spiel geladen
└── docs/                         # Struktur, Konventionen, Entwicklung und Git-Verlauf
```

Es werden keine leeren Ordner für noch unentwickelte Missionen, Rettungsdienste oder Open-World-Verwaltung angelegt. Sobald ein solches System entsteht, erhält es einen passenden Ordner unter `game/` und Prüfungen unter `tests/`.

## Einstieg und wichtige Verantwortlichkeiten

| Aufgabe | Einstieg |
| --- | --- |
| Normales Spiel starten | `project.godot` → `game/world/main.tscn` |
| Welt, Spieler und bestehende Systeme verbinden | `game/world/main.gd` |
| NPC-Pose, Verletzungen und Sitzübergänge | `game/actors/npc/driver_actor.gd` |
| Gelenke, Kräfte und regionale Schwächung | `game/actors/physics/active_body.gd` |
| Fahrzeuge erzeugen und Kontrollplatz reservieren | `game/traffic/traffic_manager.gd` |
| Fahrzeugroute, Öffnungen, Beladung und Ausrollen | `game/vehicles/traffic_car.gd` |
| Magazinverwaltung und Spieler-Schüsse | `game/weapons/pistol_action.gd` |
| Gemeinsame Glasdurchdringung | `game/weapons/projectile_trace.gd` |
| Inventare und atomare Übertragungen | `game/inventory/item_inventory.gd` |
| Detailsuche in Behältern | `game/inspection/toolbox_inspection.gd` |
| Physiklabor, F9 | `prototypes/body_physics/body_lab.tscn` |
| Konfrontationstest, F10 | `prototypes/combat/combat_test.tscn` |

`game/world/main.gd` ist weiterhin ein größerer Koordinator. Dieser Schritt ordnet Dateien und dokumentiert Schnittstellen; er erfindet keine neue Spiellogik und löst noch nicht die gesamte Szenenerzeugung aus diesem Skript heraus. Ein späterer Schritt kann Weltaufbau, Spielerbewegung und Interaktions-HUD gezielt in eigene Komponenten auslagern.

## Abhängigkeiten und Erweiterung

- Allgemeine Spiellogik gehört nach `game/`. Ein fest vorgegebener Testgegner wie `npc_gunfight.gd` gehört nach `prototypes/combat/`, bis eine allgemeine Kampfsteuerung daraus entsteht.
- Gemeinsame Werte bleiben in `game/config/`. Geschwindigkeiten sind dort in km/h beschrieben, Kräfte und Impulse in der Körperphysik in N beziehungsweise N·s.
- Inventarzustand liegt im Datenmodell; die Oberfläche zeigt ihn an und ruft definierte Übertragungsfunktionen auf. Das ist der Ausgangspunkt für spätere Speicherung und Missionen.
- Ein neues System erhält erst dann eigene Unterordner für Daten, UI oder Modelle, wenn mehrere zusammengehörige Dateien sie benötigen. Keine pauschalen `misc`-/`helpers`-Sammelordner.
- Die Hauptszene enthält bewusst F9/F10-Einstiege in Entwicklungsumgebungen. Diese Verknüpfung ist keine allgemeine Abhängigkeit der Fahrzeug-, Inventar- oder Körperphysik von Prototypen.
- Die Struktur allein erhöht keine FPS. Sie erleichtert spätere Profilierung und das gezielte Aktivieren beziehungsweise Vereinfachen einzelner Systeme.

## Godot-Ressourcen sicher verschieben

Dateien möglichst über Godots Dateisystemansicht verschieben. Beim Verschieben außerhalb des Editors müssen `preload`, `load`, `extends`, Szenenverweise, Projektstart und Testpfade angepasst werden. Jede vorhandene `.gd.uid` bleibt beim zugehörigen Skript und wird nicht neu erzeugt. Den generierten `.godot/`-Ordner nicht versionieren.

Die bisherige Startszene `main.tscn` liegt jetzt unter `game/world/main.tscn`; `project.godot` bleibt im Projektwurzelordner. Die alten Sammelordner `scripts/` und `scenes/` sind vollständig ersetzt. Funktionsnamen, gespeicherte Gegenstands-IDs und Bedienung bleiben erhalten. Pfadangaben in der bestehenden Dokumentation wurden auf die aktuelle Struktur umgestellt.

## Tests und Formatierung

Tests liegen nach Fachbereich unter `tests/<system>/`. Testfälle, die mehrere Systeme verbinden, liegen beim fachlichen Schwerpunkt. Ein Headless-Test kann echte Physik prüfen; Fensterfokus, Mausaufnahme und Screenshots müssen grafisch geprüft werden.

```bash
godot --headless --path . --editor --import --quit
godot --headless --fixed-fps 60 --path . --script res://tests/traffic/traffic_test.gd
godot --headless --fixed-fps 60 --path . --script res://tests/weapons/glass_penetration_test.gd
godot --fixed-fps 60 --path . --script res://tests/prototypes/combat_test.gd
```

Entwicklungsabhängigkeiten und reproduzierbare Formatierung sind in [CODE_STYLE.md](CODE_STYLE.md) beschrieben. Python und der Formatter werden nur für Entwicklungsarbeiten benötigt, nicht zum Starten des Godot-Spiels.
