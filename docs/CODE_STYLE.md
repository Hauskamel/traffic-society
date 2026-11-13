# Code- und Dokumentationskonventionen

## Formatierung

- GDScript folgt dem fest versionierten **gdtoolkit 4.5.0 / gdformat**-Format.
- Tabs für Einrückung, Anzeige mit vier Zeichen Breite; maximal 100 Zeichen pro Codezeile, soweit der Formatter den Ausdruck umbrechen kann.
- Zwei Leerzeilen zwischen Funktionen, Leerzeichen um Operatoren, mehrzeilige lange Aufrufe statt komprimierter Einzeiler.
- UTF-8, LF-Zeilenenden und eine abschließende Leerzeile. `.editorconfig` beschreibt diese Regeln für kompatible Editoren.
- Dateien, Funktionen und Variablen in `snake_case`; Konstanten in `UPPER_SNAKE_CASE`. Bestehende öffentliche Bezeichner bleiben bei einer reinen Umordnung erhalten.
- Für neue Schnittstellen Rückgabe- und Parametertypen angeben, soweit sie bekannt sind. Dynamische Szenenverbindungen nicht allein für eine Formatierungsänderung funktional umbauen.

## Dokumentation im GDScript

Die neue Skript- und Funktionsdokumentation ist deutsch; Bezeichner bleiben englisch. Vor jedem Laufzeitskript steht ein kurzer `##`-Block mit Aufgabe und Verantwortungsgrenze. Funktionen erhalten direkt davor `##`-Kommentare, damit Godot sie als Dokumentationskommentare erkennen kann.

- **Hauptfunktionen:** Zweck, relevante Zustandsänderungen und wichtige Voraussetzungen beschreiben. Bei komplexen Schnittstellen Rückgabe, Einheiten oder Aufräumpflichten ergänzen.
- **Hilfsfunktionen:** Ein kurzer Satz zum Zweck genügt. Nicht bloß den Namen umformulieren oder jeden Parameter wiederholen.
- **Godot-Callbacks:** Beschreiben, was dieses Skript dort tut; nicht nur erklären, dass `_ready` beim Start aufgerufen wird.
- **Interne `#`-Kommentare:** Begründen nicht offensichtliche Entscheidungen, Grenzfälle und bewusste Vereinfachungen. Bestehende technische Hinweise dürfen erhalten bleiben.
- **Tests:** Zweck des Tests und der Hilfsfunktionen beschreiben; nicht jede einzelne Assertion kommentieren.

Beispiel einer kurzen Abfrage:

```gdscript
## Meldet den tödlichen Zustand des zugehörigen Physikkörpers.
func is_dead() -> bool:
	return is_injured() and physical_actor.dead
```

Bei einer zustandsändernden Funktion gehört die wichtige Nebenwirkung in die Beschreibung: `driver_actor.receive_hit` erzeugt den Körper nur beim ersten Treffer und entscheidet ein mögliches Herausfallen nur einmal. `item_inventory.transfer_to` verändert beide Inventare erst nach erfolgreicher Prüfung. `projectile_trace.trace` beschädigt Glas; eine reine Sichtabfrage darf sie deshalb nicht verwenden.

Eine Dokumentation darf vereinfachtes Gameplay nicht als medizinische oder physikalisch kalibrierte Simulation ausgeben. Änderungen am Verhalten müssen die betroffenen Kommentare und den passenden Entwicklungsschritt mit aktualisieren.

## Formatter benutzen

Python 3.10 oder neuer und eine eigene virtuelle Umgebung verwenden. Die Godot-Anwendung benötigt diese Werkzeuge nicht.

Windows PowerShell, im Projektordner:

```powershell
py -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r tools/requirements-dev.txt
.\.venv\Scripts\python.exe tools/format_code.py
.\.venv\Scripts\python.exe tools/format_code.py --check
```

Linux/macOS:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r tools/requirements-dev.txt
.venv/bin/python tools/format_code.py
.venv/bin/python tools/format_code.py --check
```

Der Wrapper formatiert GDScript unter `game/`, `prototypes/` und `tests/`. Er prüft dabei Syntaxbaum, Kommentarerhalt und Formatierungsstabilität mit den Sicherheitsprüfungen des Formatters. `--check` schreibt nichts und liefert Exitcode 1 bei abweichendem Format. Lokale Parserdaten bleiben unter `.godot/formatter`, statt fremde Verzeichnisse zu benötigen.

## Ressourcen und Dokumentation prüfen

```bash
python tools/check_project.py
```

Die Prüfung benötigt keine zusätzlichen Pakete. Sie kontrolliert feste `res://`-Verweise, vorhandene und eindeutige Skript-UIDs sowie Skript-/Funktionskommentare. Nach neuen Skripten zuerst Godot importieren lassen, damit die `.gd.uid` entsteht. Die Prüfung bewertet nicht die inhaltliche Qualität eines Kommentars und ersetzt keine Spieltests.

## Commits und neue Funktionen

Kurze Commit-Betreffzeilen verwenden, etwa `Projekt geordnet` oder `Türprüfung korrigiert`. Technische Einzelheiten gehören in diese Dokumentation beziehungsweise die PR-Beschreibung. Neue Features beginnen von `develop`; Prototypen bleiben getrennt von allgemeiner Spiellogik. Siehe [Projektstruktur](PROJECT_STRUCTURE.md) und [Git-Arbeitsablauf](GIT-WORKFLOW.md).
