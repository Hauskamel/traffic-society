# Traffic Society

Ein kompakter 3D-Prototyp für ein Polizeikontrollspiel: Verkehr aus der Vogelperspektive beobachten und Kontrollen später in der Ego-Perspektive durchführen.

## Technik

- Godot 4 mit GDScript; Standardausgabe, kein .NET erforderlich.
- Renderer: GL Compatibility.
- Einfache Low-Poly-Geometrie aus Godot-Meshes; Blender und glTF/GLB sind für spätere individuelle Modelle vorgesehen.
- Entwicklungsplattform des bisherigen Prototyps: Windows, Godot 4.7.2 laut Editor-Screenshot.
- Das Projekt deklariert Godot 4.7; für die Weiterentwicklung dieselbe Version verwenden.
- Lokales Arbeitsverzeichnis: `E:\godot-projects`.

## Projektstatus

Auf `feature/fundamentals` ist Schritt 2 umgesetzt: Ein festes Fahrzeug mit Bobby Mayer fährt vorbei, lässt sich in die Parkbucht holen und am Fahrerfenster wieder freigeben. `main` und `develop` bleiben bis zur Übernahme auf dem Ausgangsstand von Schritt 1.

Fahrer aussteigen lassen, Dokumente, Durchsuchungen und mehrere Fahrzeuge gehören noch nicht zu dieser Version.

Der Ausgangsstand wurde beim Import mit Godot 4.6.3 im Headless-Modus geprüft. Für Schritt 2 gibt es einen wiederholbaren Ablauf-Test; Prüfungen und Einschränkungen stehen in der Entwicklungsdokumentation. Ein Windows-Test unter Godot 4.7.2 steht noch aus.

## Spiel starten

`project.godot` im Godot-Projektmanager importieren, öffnen und F5 drücken. Die Umgebung wird beim Start vom Skript aufgebaut; eine leere 3D-Ansicht im Editor ist daher zunächst normal.

| Eingabe | Funktion |
| --- | --- |
| Tab | Vogelperspektive / Ego-Ansicht |
| WASD oder Pfeiltasten | Bewegen |
| Maus | In der Ego-Ansicht umsehen |
| Shift | Schneller gehen |
| Mausrad | Übersicht zoomen |
| Escape | Maus freigeben |
| Linksklick | In der Ego-Ansicht Maus wieder einfangen |
| R | Spielerposition zurücksetzen |
| Linksklick auf Auto / Schaltfläche | In der Übersicht Kontrolle anfordern, solange die Einfahrt noch nicht passiert wurde |
| E | In Ego-Ansicht am linken Fahrerfenster weiterfahren lassen |
| N | Nach Abfahrt eine neue Testfahrt starten |

## Dokumentation

- [Entwicklungsschritte](docs/ENTWICKLUNG.md): Umsetzung, Probleme und nächster geplanter Umfang.
- [Git-Arbeitsablauf](docs/GIT-WORKFLOW.md): Branches und Änderungen.

Zukünftige Spielfunktionen werden erst nach gemeinsamer Abstimmung umgesetzt.

## Repository unter Windows beziehen

Mit installiertem Git:

```powershell
Set-Location E:\godot-projects
git clone https://github.com/Hauskamel/traffic-society.git
Set-Location traffic-society
git switch --track origin/feature/fundamentals
```

Alternativ auf GitHub zuerst den Branch **feature/fundamentals** auswählen und unter **Code → Download ZIP** herunterladen und unter `E:\godot-projects` entpacken. Eine ZIP ist eine Momentaufnahme ohne lokale Git-Historie.

## Schritt 2 ausprobieren

1. F5 drücken und in der Übersicht das Auto anklicken oder **Zur Kontrolle anhalten** wählen. Das geht nur vor der Einfahrt. Bei verpasster Einfahrt bis zur Abfahrt warten und mit N neu starten.
2. Warten, bis der Wagen in der Bucht steht. Mit Tab in die Ego-Ansicht wechseln.
3. Auf die linke Fahrzeugseite gehen und aus kurzer Entfernung auf das Fahrerfenster schauen.
4. Wenn der Hinweis erscheint, E drücken. Der Wagen fährt aus der Bucht und verlässt die Straße.
5. Mit N oder der Schaltfläche eine neue Testfahrt starten.

## Automatischer Ablauf-Test

```sh
godot --headless --path . --script res://tests/fundamentals_test.gd
```

Unter Windows gegebenenfalls den vollständigen Pfad zur Godot-Konsolen-EXE verwenden. Der Test prüft unter anderem Einparken, Kollision, Abfahrt, verpasste Einfahrt und Wiederholung; Mausinteraktion braucht zusätzlich einen grafischen Test.

Grafischer Interaktionstest (benötigt ein Fenster/Display):

```sh
godot --path . --script res://tests/fundamentals_interaction_test.gd
```

Er prüft die Fahrzeugauswahl per Physikstrahl, Kamerawechsel und die Freigabe mit E samt Blick- und Seitenprüfung. Vorschau-Screenshots werden im Godot-Benutzerdatenordner (`user://`) gespeichert. Beide Tests wurden mit Godot 4.6.3 ausgeführt; der Windows-Test mit 4.7.2 bleibt offen.
