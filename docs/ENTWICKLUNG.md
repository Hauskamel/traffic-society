# Entwicklungsschritte

## Schritt 0 – Konzept und Technikwahl · abgeschlossen

Ziel ist ein kleines Polizeikontrollspiel mit einer Verkehrsübersicht und begehbaren Kontrollen in der Ego-Perspektive. Figuren sollen vorbereitet sein und kleine eigene Geschichten besitzen. Zufällig erzeugte NPCs sind nicht vorgesehen.

Gewählt wurden Godot 4, GDScript und ein einfacher Low-Poly-Stil. Blender ist für spätere Modellbearbeitung vorgesehen; bisher werden keine Blender-Dateien benötigt. Der Umfang bleibt zunächst bei einem einzelnen Kontrollplatz.

## Schritt 1 – Begehbarer Kontrollplatz · lokal abgeschlossen

### Umsetzung

- Straße mit Mittel- und Randmarkierungen.
- Seitliche Parkbucht mit drei Stellflächen, Ein- und Ausfahrt sowie Bordstein.
- Leitpfosten, Parkschild und einfache Low-Poly-Bäume.
- Spieler mit Ego-Kamera, Mausblick, Laufbewegung und schnellerem Gehen.
- Vogelperspektive mit Kamerabewegung und Zoom; Umschalten mit Tab.
- Kollisionen am Boden und an ausgewählten Hindernissen.
- Hinweise zur Steuerung und Rücksetzen der Spielerposition.

Die Szene wird zur Laufzeit aus einfachen Meshes aufgebaut. Der Prototyp verwendet `project.godot`, `main.tscn` und `main.gd`.

### Einrichtung und Fehlerbehebung

Die ursprüngliche Übergabe über einen Cloud-Workspace war auf dem Windows-PC nicht zugänglich. Daher wurde das Projekt über ein lokal gespeichertes PowerShell-Setup erzeugt.

Beim direkten Einfügen in die PowerShell gingen Einrückungen des GDScripts verloren. Das führte zu `Expected indented block after function declaration`. In einem weiteren Versuch war `$project` nicht gesetzt; die Dateien konnten dadurch nicht geschrieben werden. Der funktionierende Weg besteht darin, das vollständige Setup als `.ps1` im Windows-Editor zu speichern und als Datei auszuführen. Als Basisverzeichnis wurde `E:\godot-projects` festgelegt.

Der Hinweis auf die ältere Godot-Projektversion war nicht die Ursache des Einrückungsfehlers. Nach der Korrektur wurde der funktionierende Stand vom Nutzer bestätigt. Der exakte Projektstand wurde anschließend aus der vom Nutzer bereitgestellten ZIP übernommen. Der Szenenstart wurde hier mit Godot 4.6.3 im Headless-Modus über 120 Frames ohne Skript- oder Laufzeitfehler geprüft. Dies ersetzt keinen grafischen Test unter Godot 4.7.2.

### Bewusst noch nicht enthalten

Fahrzeuge, Verkehr, Fahrer, Dokumentenprüfung, Durchsuchungen und Missionen.

## Schritt 1a – GitHub und Dokumentation · abgeschlossen

Das vom Nutzer angelegte öffentliche Repository `Hauskamel/traffic-society` enthält den hochgeladenen Godot-Stand und die deutsche Dokumentation. Der stabile Branch `main` und der Entwicklungsbranch `develop` beginnen am selben Commit.

Übernommen wurden `project.godot`, `main.tscn`, `main.gd` und `main.gd.uid`. Die Spiellogik wurde nicht verändert. Git normalisiert Zeilenenden auf LF. Der generierte `.godot`-Cache bleibt lokal und wird ignoriert. README, Entwicklungsschritte und Git-Arbeitsablauf dokumentieren den aktuellen Stand; `.gitattributes` vereinheitlicht Textdateien.

Der in Schritt 1 genannte lokale Starttest wurde vor dem ersten Commit durchgeführt. Neue Spielfunktionen wurden in diesem Schritt nicht umgesetzt.

## Schritt 2 – Erstes Fahrzeug anhalten · auf `feature/fundamentals` umgesetzt

### Spielablauf

Ein einzelner vorbereiteter Wagen mit Fahrer Bobby Mayer und Kennzeichen `TS BM 104` startet automatisch auf der rechten Spur. In der Vogelperspektive kann er per Klick auf das Fahrzeug oder über **Zur Kontrolle anhalten** ausgewählt werden. Der Auftrag muss vor der Einfahrt erfolgen. Ist sie bereits passiert, fährt der Wagen weiter; nach dem Verlassen der Szene startet N eine neue Testfahrt.

Nach dem Auftrag fährt das Auto in die Parkbucht und bremst bis zum Stillstand. Mit Tab wechselt der Spieler zur Ego-Ansicht und geht zum linken Fahrerfenster. Aus kurzer Entfernung und mit Blick zum Fenster erscheint **[E] Bobby Mayer weiterfahren lassen**. Die Freigabe lässt das Auto über die Ausfahrt zurück auf die Straße fahren. Danach ist eine neue Testfahrt möglich. Der Fahrer bleibt sitzen.

### Technische Umsetzung

- Eigenes Fahrzeugsystem in `scripts/traffic_car.gd`, über `main.gd` in die bestehende Szene eingebunden.
- Zustände: unterwegs, fährt in die Bucht, geparkt, fährt weg, Testfahrt beendet. Doppelte oder unpassende Aufträge werden zurückgewiesen.
- Vorgegebene Kurvenrouten statt Verkehrssimulation oder Fahrzeugphysik. Langsames Fahren in der Bucht, Abbremsen vor dem Haltepunkt und Beschleunigen bei Abfahrt.
- Einfaches selbst erstelltes Low-Poly-Auto mit Karosserie, Scheiben, Spiegeln, Kennzeichen, vier rollenden Rädern, vereinfachtem Lenken und Bremslichtern. Ein fester sitzender Platzhalter stellt Bobby dar.
- Fahrzeugkollision auf eigener Ebene; der Spieler kann nicht durch den geparkten Wagen laufen. Auswahl per Kamerastrahl trifft die Fahrzeugkollision.
- Freigabe nur in Ego-Ansicht mit eingefangener Maus, geringer Entfernung, Blick zum Fahrerfenster und Position auf der Fahrerseite.
- Statusanzeige und kontextbezogene Schaltflächen. Schaltflächen erhalten keinen Tastaturfokus, damit Tab weiterhin die Kamera wechselt.
- `main` und `develop` bleiben unverändert. Weitere abgestimmte Grundlagen können auf diesem Feature-Branch folgen.

### Prüfung

Der automatische Test `tests/fundamentals_test.gd` prüft erfolgreichen und doppelten Anhalteauftrag, Parkposition, Stillstand, Kollision mit dem Spieler, ungültige Freigabe, Abfahrt, verpasste Einfahrt und mehrere wiederholte Begegnungen. Ausführung mit Godot 4.6.3 im Headless-Modus.

Der grafische Test `tests/fundamentals_interaction_test.gd` wurde mit Godot 4.6.3 unter Linux und Software-Rendering ausgeführt und bestanden: sichtbares Fahrzeug beim Start, Auswahl per Physikstrahl, Kamerwechsel, Freigabe am nahen Fahrerfenster und per E. Wegschauen und die Beifahrerseite verhindern die Interaktion. Screenshots von Übersicht, Parkposition und Fahrerfenster wurden visuell geprüft. Ein Test unter Windows mit Godot 4.7.2 bleibt durch den Nutzer erforderlich.

### Grenzen

Ein Fahrzeug und ein fester Fahrer. Keine freie Fahrphysik, allgemeine Hindernisvermeidung, Warteschlange oder Mehrfachkontrolle. Die Route wird nicht für dynamische Hindernisse neu geplant. Der Spieler sollte die Fahrbahn während der Bewegung freihalten. Kein Aussteigen, keine Dokumente und keine Durchsuchung. Der bisherige Kontrollplatz bleibt die Grundlage.

## Schritt 3 – Fahrer aussteigen lassen · Ausblick

Ein fester Fahrer erhält einen Körper, eine Sitzposition, einen freien Ausstiegspunkt und einen einfachen Ablauf zum Aussteigen. Die Aufforderung soll am Fahrerfenster erfolgen. Details und Animationen werden vor der Umsetzung besprochen.

## Schritt 4 – Erste Kontrolle · Ausblick

Dokumente anfordern und vergleichen sowie eine einfache persönliche Durchsuchung. Umfang, Bedienung und Darstellung sind noch offen.

## Dokumentationsregel

Jeder umgesetzte Schritt ergänzt diese Datei um Verhalten, relevante technische Entscheidungen, tatsächliche Prüfung und offene Punkte. Geplante Funktionen werden nicht als abgeschlossen dokumentiert.
