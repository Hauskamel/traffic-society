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

Auf `feature/fundamentals` sind Schritt 2 und die Verkehrserweiterung 2a umgesetzt: Laufend fahren vorbereitete Fahrzeuge an der Bucht vorbei. Ein Fahrzeug lässt sich in der Übersicht auswählen und ausdrücklich zur Kontrolle anhalten. Am Fahrerfenster kann es wieder freigegeben werden. `main` und `develop` bleiben bis zur Übernahme auf dem Ausgangsstand von Schritt 1.

Fahrer aussteigen lassen, Dokumente und Durchsuchungen gehören noch nicht zu dieser Version. Der Verkehr nutzt zunächst nur eine Fahrtrichtung und eine gleichzeitig belegbare Kontrollbucht.

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
| Linksklick auf Auto | In der Übersicht auswählen; hält das Fahrzeug noch nicht an |
| Zur Kontrolle anhalten | Ausgewähltes Fahrzeug ausdrücklich in die freie Bucht holen |
| E | In Ego-Ansicht am linken Fahrerfenster weiterfahren lassen |

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

## Verkehr und Kontrolle ausprobieren

1. F5 drücken. Vier verschiedene Fahrzeugformen sind im Verkehr; weitere Fahrten erscheinen automatisch.
2. In der Übersicht ein Auto vor der Einfahrt anklicken. Die Auswahl zeigt Fahrer, Modell und Kennzeichen. Die Auswahl allein hält niemanden an.
3. **Zur Kontrolle anhalten** drücken. Nur dieses Auto fährt in die freie Bucht. Die übrigen Fahrzeuge fahren vorbei. Bei verpasster Einfahrt ein anderes Auto auswählen.
4. Sobald das Auto steht, mit Tab zur Ego-Ansicht wechseln und zum linken Fahrerfenster gehen.
5. Auf das Fenster schauen und bei sichtbarem Hinweis E drücken. Das Fahrzeug fährt ab und fädelt unter Berücksichtigung des übrigen Verkehrs ein.
6. Nach seiner Abfahrt ist die Bucht wieder frei. Kein manueller Neustart mit N ist mehr nötig.

### Vorbereitete Fahrzeuge

| Fahrer | Modell | Kennzeichen | Optik |
| --- | --- | --- | --- |
| Bobby Mayer | Limousine | TS BM 104 | Türkis, längere Karosserie |
| Nora Beck | Kleinwagen | TS NB 217 | Gelb, kurze Karosserie |
| Erik Sommer | Transporter | TS ES 308 | Heller, hoher geschlossener Laderaum |
| Mara Wolf | Pickup | TS MW 412 | Rot, offene Ladefläche |

Die Fahrer sind fest definiert. Dieselbe Figur erscheint nicht gleichzeitig in mehreren Fahrzeugen. Nach einer vollständigen Durchfahrt kann sie später erneut auftauchen; eine zusammenhängende Schicht mit einmaligen Story-Begegnungen folgt erst später.

## Automatischer Ablauf-Test

```sh
godot --headless --path . --script res://tests/fundamentals_test.gd
```

Unter Windows gegebenenfalls den vollständigen Pfad zur Godot-Konsolen-EXE verwenden. Der Test prüft unter anderem Einparken, Kollision, Abfahrt, verpasste Einfahrt und Wiederholung; Mausinteraktion braucht zusätzlich einen grafischen Test.

Zusätzlicher Verkehrstest:

```sh
godot --headless --path . --script res://tests/traffic_test.gd
```

Er simuliert mehrere Minuten Verkehr ohne Anhalteauftrag sowie Kontrollen aller vier Modelle bei unterschiedlichen Verkehrsphasen. Er prüft Nachschub, feste Identitäten, Auswahl ohne Anhalten, Abstände, die Reservierung der Bucht und das Wiedereinfädeln.

Grafischer Interaktionstest (benötigt ein Fenster/Display):

```sh
godot --path . --script res://tests/fundamentals_interaction_test.gd
```

Er prüft die Fahrzeugauswahl per Physikstrahl, Kamerawechsel und die Freigabe mit E samt Blick- und Seitenprüfung. Vorschau-Screenshots werden im Godot-Benutzerdatenordner (`user://`) gespeichert. Alle drei Tests wurden mit Godot 4.6.3 ausgeführt; der Windows-Test mit 4.7.2 bleibt offen.
