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

Schritt 1 ist umgesetzt. Der vom Nutzer bereitgestellte, unter Windows funktionierende Projektstand wurde aus der ZIP übernommen. Fahrzeuge und Kontrollen sind noch nicht implementiert.

Prüfung beim Import: Szenenstart mit Godot 4.6.3 im Headless-Modus über 120 Frames ohne Skript- oder Laufzeitfehler. Die grafische Bedienung unter Godot 4.7.2 wurde hier nicht erneut geprüft.

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
git switch develop
```

Alternativ auf GitHub unter **Code → Download ZIP** herunterladen und unter `E:\godot-projects` entpacken. Eine ZIP ist eine Momentaufnahme ohne lokale Git-Historie.
