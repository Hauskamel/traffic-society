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

Der Kontrollstellplatz hat genau einen Besitzer, vom Anhalteauftrag bis das ganze Fahrzeug den markierten Stellplatz geräumt hat. Das abfahrende Auto darf sich danach noch in der Bucht befinden. Weitere Anhalteaufträge werden nur während der Stellplatzbelegung abgewiesen; der übrige Verkehr läuft weiter. Die Freigabe am linken Fahrerfenster bleibt erhalten. Ein einfacher Abstandsregler und eine Warteprüfung beim Einfädeln berücksichtigen andere Fahrzeuge. Verkehrsbedingtes Bremsen ist kein automatischer Kontrollauftrag.

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

### Gameplay-Anpassung – Aus-/Einsteigen ohne Platzprüfung

Nach dem Windows-Test wurde die vorherige Platzprüfung auf Wunsch des Nutzers entfernt: Sie zwang den Spieler zum Zurücktreten und wiederholten Anfordern. Ein bestätigter Auftrag wird jetzt auch bei blockierter Tür oder belegtem Weg vollständig ausgeführt und während der Animation nicht mehr pausiert. Es gibt keine Platzmangel-Meldung mehr.

Die Tür kollidiert während der Bewegung vorübergehend nicht mit dem Spieler. Tür und Fahrer dürfen dabei Hindernisse durchdringen; ein wartender Fahrer hat anschließend weiterhin eine Kollision. Die Zustandsprüfung gegen doppelte Aufträge und die Abfahrt nur mit sitzendem Fahrer und geschlossener Tür bleiben erhalten.

### Gameplay-Anpassung – Stellplatz frühzeitig freigeben

Die Reservierung endet beim Räumen des markierten Kontrollstellplatzes (z=0 bis 10), nicht erst beim Verlassen der gesamten Bucht oder Szene. Die Berechnung berücksichtigt Fahrzeugbreite, Länge und Drehung. Erst wenn auch das Heck vollständig außerhalb steht, wird der Platz für den nächsten Anhalteauftrag frei.

Das vorherige Auto bleibt unabhängig davon als abfahrender Verkehrsteilnehmer erhalten. Seine spätere Entfernung darf die Reservierung einer neuen Kontrolle nicht aufheben. Statusanzeige und Markierung folgen der neuen Stellplatzreservierung.

Der neue Test `parking_reservation_test.gd` prüft die Freigabegrenze und aufeinanderfolgende Reservierungen für alle vier Modelle. Der mehrminütige Verkehrstest wurde ebenfalls erneut bestanden (Godot 4.6.3, Headless).

### Prüfung

Mit Godot 4.6.3 unter Linux:

- `driver_test.gd`: Aus-/Einsteigen bei allen vier Modellen, Türöffnung und -schluss, belegte Wege ohne erneuten Auftrag oder Pause, stehender Fahrer als Hindernis und gesperrte Freigabe ohne sitzenden Fahrer.
- `driver_menu_test.gd` mit Display: E öffnet/bestätigt, Mausrad in beide Richtungen samt Umlauf, Esc schließt, Mausblick pausiert, wechselnde Aktionen draußen, Gespräch beenden, Wiedereinsteigen und abschließende Freigabe. Übersichtszoom bleibt erhalten.
- Bestehende Fundament-, Verkehrs- und grafische Interaktionstests wurden an die Menübedienung angepasst und erneut bestanden.
- Screenshots von geöffneter Tür, aussteigendem Fahrer und Außenmenü wurden visuell geprüft.

Die neue Funktion benötigt noch den Windows-Test unter Godot 4.7.2. `main` und `develop` bleiben unverändert; Entwicklung auf `feature/fundamentals`.

### Grenzen

Feste kurze Bewegungsbahn neben dem Fahrzeug, kein freies NPC-Wegfinden und keine hochwertige Skelettanimation. Fahrer warten an einem festen Punkt. Befragen, Dokumente und Durchsuchungen sind noch nicht enthalten.

## Geschwindigkeitsabstimmung – Verkehr verdoppelt

Die Reisegeschwindigkeit der Autos wurde von 3 m/s (10,8 km/h) auf 6 m/s (21,6 km/h) erhöht. `scripts/speed_settings.gd` definiert den Maßstab und alle Bewegungsgeschwindigkeiten zentral in km/h. Ein relativer Verkehrsfaktor von 2,0 multipliziert das bisherige Grundtempo von 10,8 km/h.

Das Ein-/Ausparktempo bleibt bei 2,5 m/s (9 km/h), der Spieler bei 3,5 m/s (12,6 km/h) ohne Sprint beziehungsweise 6 m/s (21,6 km/h) mit Sprint. Umrechnung: km/h geteilt durch 3,6 ergibt m/s. Es wurde kein zusätzliches Einstellungsmenü eingeführt.

Fundament-, mehrminütiger Verkehrs- und Stellplatztest mit Godot 4.6.3 erneut bestanden. Der Verkehrstest prüft weiterhin Abstände und das Wiedereinfädeln aller vier Modelle bei unterschiedlichen Verkehrsphasen. Der neue Tempoeindruck ist unter Windows zu beurteilen.

## Fahrzeugbereiche – Türen und Kofferraum · umgesetzt

Vor der Dokumenten- und Dialogarbeit wurde das Fundament der direkten Fahrzeuginteraktion ergänzt. Die erste Ausbaustufe betrifft Bobbys Limousine: Fahrertür, Beifahrertür und Kofferraumdeckel lassen sich separat öffnen und schließen. Die übrigen Modelle behalten ihre bisherigen Fahreraktionen.

### Bedienung und Darstellung

In Ego-Ansicht wird der Bereich unter dem Fadenkreuz gelb eingefärbt. Ein benannter E-Hinweis zeigt die nächste Aktion an. Ein Tastendruck öffnet beziehungsweise schließt den Bereich; auch der bewegte/geöffnete Flügel bleibt anwählbar. Die Markierung verschwindet beim Wegsehen, im Menü, außerhalb der Reichweite oder in der Übersicht.

Das Türblech ist vom Fahrerfenster getrennt: An der unteren Türfläche bedient E die Tür, am Fahrerfenster weiterhin das Mausrad-Menü für den Fahrer. Der Kofferraum hat einen eigenen schwenkbaren Deckel und einen sichtbaren, leeren Innenraum. Die Beifahrertür schwenkt zur gegenüberliegenden Seite.

### Technik

`scripts/vehicle_part.gd` bündelt Bezeichnung, Trefferfläche, Hervorhebung und reversible Scharnierbewegung. Die Fahrzeuggeometrie wird aus getrennten Fenster-, Tür- und Kofferraumteilen aufgebaut. Eine eigene Physikebene für Interaktionsflächen ermöglicht die gezielte Auswahl. Eine zusätzliche Sichtprüfung berücksichtigt Welt-Hindernisse; Seiten- und Entfernungsprüfungen verhindern Interaktionen von der falschen Seite oder aus der Ferne.

Manuelle Aktionen sind nur am kontrollierten, geparkten Auto und außerhalb der Fahreranimation verfügbar. Die Aus-/Einstiegsanimation übernimmt die Fahrertür, auch wenn diese bereits manuell geöffnet wurde. Alle bedienbaren Bereiche müssen vor der Abfahrt geschlossen sein. Während der Bewegung bleibt das bisherige nachsichtige Verhalten gegenüber Hindernissen erhalten.

### Prüfung

Mit Godot 4.6.3 unter Linux bestanden: bestehende Fundament-, Verkehrs-, Fahrer- und Stellplatztests. Der neue grafische Test `vehicle_parts_test.gd` prüft beide Türen und Kofferraum, Hervorhebung und E-Hinweise, erneutes Anvisieren zum Schließen, Wegsehen, Reichweite, Verdeckung durch eine Wand, das weiterhin nutzbare Fahrer-Menü, die Übergabe einer geöffneten Tür an die Fahreranimation und die gesperrte Abfahrt bei geöffneten Teilen. Screenshots wurden visuell geprüft.

Der Windows-Test mit Godot 4.7.2 steht noch aus. Inhalte, Dokumente und Durchsuchungen wurden nicht ergänzt.

## Schritt 4 – Erste Kontrolle · Ausblick

Dokumente anfordern und vergleichen sowie eine einfache persönliche Durchsuchung. Umfang, Bedienung und Darstellung sind noch offen.

## Dokumentationsregel

Jeder umgesetzte Schritt ergänzt diese Datei um Verhalten, relevante technische Entscheidungen, tatsächliche Prüfung und offene Punkte. Geplante Funktionen werden nicht als abgeschlossen dokumentiert.
