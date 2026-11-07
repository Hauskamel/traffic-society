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

## Schritt 2 – Erstes Fahrzeug anhalten · umgesetzt, Bedienung durch 2a erweitert

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

## Schritt 2a – Verkehr und Modellvarianten · auf `feature/fundamentals` umgesetzt

### Verhalten

Ein einfacher fortlaufender Verkehr fährt auf der rechten Spur von +Z nach -Z. Vier vorbereitete Begegnungen verwenden unterschiedliche Karosserien: Bobby Mayer in einer türkisen Limousine, Nora Beck im gelben Kleinwagen, Erik Sommer im hellen Transporter und Mara Wolf im roten Pickup. Unterschiedliche Länge, Dachhöhe, Kabine und Ladefläche machen die Varianten auch unabhängig von der Lackfarbe erkennbar.

**Kein Fahrzeug fährt von selbst zur Kontrolle in die Bucht.** Ein Klick in der Vogelperspektive wählt ein Auto zunächst nur aus. Erst die Schaltfläche **Zur Kontrolle anhalten** erteilt den Auftrag. Fahrer, Modell und Kennzeichen der Auswahl werden angezeigt. Eine verpasste Einfahrt kann nicht rückwärts angefahren werden.

Die Kontrollbucht hat vorerst genau einen Besitzer, vom Anhalteauftrag bis zur vollständigen Abfahrt. Weitere Anhalteaufträge werden währenddessen abgewiesen; der übrige Verkehr läuft weiter. Die Freigabe am linken Fahrerfenster bleibt erhalten. Ein einfacher Abstandsregler und eine Warteprüfung beim Einfädeln berücksichtigen andere Fahrzeuge. Verkehrsbedingtes Bremsen ist kein automatischer Kontrollauftrag.

### Umsetzung

- `scripts/traffic_manager.gd` verwaltet die feste Liste, Auswahl, Buchtreservierung und laufenden Nachschub.
- Vier Fahrzeuge starten mit Abstand auf derselben Spur. Nachschub wird frühestens im Abstand von elf Sekunden versucht; blockierte Spawnpunkte und bereits anwesende Fahrer werden übersprungen beziehungsweise abgewartet.
- Es gibt höchstens vier aktive Begegnungen. Eine feste Figur wird nicht dupliziert. Fahrzeuge am Streckenende werden entfernt; freie Identitäten können später wieder erscheinen.
- Das Fahrzeugskript baut Karosserie, Kollisionskörper, Räder, Kabine und Interaktionspunkt passend zur Variante auf.
- Automatische Nachfolgefahrten ersetzen die frühere Schaltfläche **Neue Testfahrt** und Taste N.
- Der bestehende Feature-Branch und Pull Request werden weitergeführt. Kein Merge nach `develop` oder `main`.

### Prüfung

Mit Godot 4.6.3 bestanden:

- Bisheriger Fundament-Test für Parken, Kollision, Abfahrt und Wiederholung, an den Verkehrsmanager angepasst.
- Neuer Verkehrstest: zwei simulierte Minuten ohne Anhalteauftrag, laufender Nachschub, höchstens vier Fahrzeuge, keine doppelte Fahreridentität und kein automatischer Kontrollhalt. Anschließend Buchtreservierung und Kontrollen aller vier Modelle bei unterschiedlichen Verkehrsphasen, inklusive Abfahrt und Prüfung auf Fahrzeugüberschneidungen.
- Grafischer Interaktionstest: Auswahl des angeklickten Autos hält es noch nicht an; erst die Schaltfläche löst die Kontrolle aus. Ego-Wechsel und Freigabe am Fahrerfenster funktionieren weiterhin. Übersicht und Ego-Ansicht wurden anhand von Screenshots visuell geprüft.

Der Nutzer hat den Verkehr und die Kontrolle anschließend unter Windows getestet und bestätigt.

### Grenzen

Eine Fahrtrichtung, feste Routen und einfache Abstandsregeln. Noch keine Kreuzungen, Gegenverkehr, Überholmanöver, allgemeine Hindernisvermeidung oder vollständige Verkehrs-KI. Die automatische Wiederkehr der festen Figuren dient dem Prototyp; Schichtplanung und Story-Fortschritt sind noch offen. Die Modelle sind bewusst einfache Platzhalter. Fahrer steigen weiterhin nicht aus.

## Schritt 3 – Interaktionsmenü und Fahrer aussteigen lassen · umgesetzt

### Bedienung

Der vorherige Verkehrsstand wurde vom Nutzer unter Windows bestätigt. Auf dessen Wunsch werden mehrere Aktionen per Mausrad ausgewählt.

E öffnet am linken Fahrerfenster das Menü **Aussteigen lassen / Weiterfahren lassen**. Mausrad hoch und runter wechselt die gelb hervorgehobene Auswahl, einschließlich Umlauf vom letzten zum ersten Eintrag. E bestätigt, Esc schließt. Während des Menüs sind Mausblick und Laufbewegung pausiert; die übrige Welt läuft weiter. In der Übersicht zoomt das Mausrad weiterhin. Kamerawechsel und Zurücksetzen schließen ein offenes Menü.

Nach dem Aussteigen wartet der Fahrer neben der linken Tür. Ansehen und E öffnet **Einsteigen lassen / Gespräch beenden**. Gespräch beenden schließt nur das Menü. Nach dem Wiedereinsteigen kann das Auto am Fenster freigegeben werden. Es fährt nur, wenn der Fahrer sitzt und die Tür vollständig geschlossen ist.

### Darstellung und Zustände

- `scripts/driver_actor.gd` enthält einen einfachen Low-Poly-Körper mit Kopf, Armen und Beinen sowie die Zustände sitzend, steigt aus, steht draußen und steigt ein.
- Eine kurze prozedurale Animation öffnet die Fahrertür, bewegt und dreht den Fahrer neben das Auto und schließt die Tür. Der Einstieg verwendet den umgekehrten Ablauf.
- Alle vier Karosserien erhalten einen separaten Türflügel mit Scharnier und Kollisionskörper. Fenster und Türöffnung werden aus einzelnen Teilen aufgebaut.
- Sitzhöhe und Türposition passen zur jeweiligen Kabine; der Fahrer steht draußen auf Bodenniveau.
- Ein wartender Fahrer hat eine Kollision. Die spätere Übernahme eines geriggten GLB-Modells bleibt möglich; die Animation ist bisher ein bewusst einfacher Platzhalter.

### Platzprüfung und Rückmeldungen

Eine Physikabfrage deckt Türschwenk und den kurzen Weg neben dem Auto ab. Bei einem blockierten Aus-/Einstieg wird die Aktion abgewiesen und ein Hinweis angezeigt. Der Spieler kann nach dem Schließen des Menüs zurücktreten und erneut anfragen. Tritt er während der Bewegung in den Bereich, pausiert die Animation, bis der Weg wieder frei ist. Eigene Fahrzeug-, Tür- und Fahrerkollisionen werden bei dieser Prüfung ausgeschlossen.

### Prüfung

Mit Godot 4.6.3 unter Linux:

- `driver_test.gd`: Aus-/Einsteigen bei allen vier Modellen, Türöffnung und -schluss, blockierte Wege, Pausieren/Fortsetzen, stehender Fahrer als Hindernis und gesperrte Freigabe ohne sitzenden Fahrer.
- `driver_menu_test.gd` mit Display: E öffnet/bestätigt, Mausrad in beide Richtungen samt Umlauf, Esc schließt, Mausblick pausiert, wechselnde Aktionen draußen, Gespräch beenden, Wiedereinsteigen und abschließende Freigabe. Übersichtszoom bleibt erhalten.
- Bestehende Fundament-, Verkehrs- und grafische Interaktionstests wurden an die Menübedienung angepasst und erneut bestanden.
- Screenshots von geöffneter Tür, aussteigendem Fahrer und Außenmenü wurden visuell geprüft.

Die neue Funktion benötigt noch den Windows-Test unter Godot 4.7.2. `main` und `develop` bleiben unverändert; Entwicklung auf `feature/fundamentals`.

### Grenzen

Feste kurze Bewegungsbahn neben dem Fahrzeug, kein freies NPC-Wegfinden und keine hochwertige Skelettanimation. Fahrer warten an einem festen Punkt. Befragen, Dokumente und Durchsuchungen sind noch nicht enthalten.

## Schritt 4 – Erste Kontrolle · Ausblick

Dokumente anfordern und vergleichen sowie eine einfache persönliche Durchsuchung. Umfang, Bedienung und Darstellung sind noch offen.

## Dokumentationsregel

Jeder umgesetzte Schritt ergänzt diese Datei um Verhalten, relevante technische Entscheidungen, tatsächliche Prüfung und offene Punkte. Geplante Funktionen werden nicht als abgeschlossen dokumentiert.
