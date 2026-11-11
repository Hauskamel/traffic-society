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

## Fahrzeugbereiche – Erweiterung auf alle Modelle · umgesetzt

Die zunächst auf die Limousine begrenzte Bedienung wurde auf alle vier Fahrzeuge übertragen. Jedes Modell hat eine manuell bedienbare Fahrer- und Beifahrertür. Hinzu kommen passende hintere Öffnungen:

- Limousine: bisheriger Kofferraumdeckel.
- Kleinwagen: nach oben schwenkende Heckklappe samt Heckscheibe.
- Weißer Transporter: zwei separat nach außen schwenkende Ladetüren; der vorher massive Aufbau ist als leerer Laderaum mit Boden, Seitenwänden und Dach modelliert.
- Pickup: nach unten schwenkende Ladeflächenklappe.

Alle Bereiche verwenden dieselbe Fadenkreuz-Hervorhebung, benannte E-Hinweise und erneutes E zum Schließen. Die festen Fahreraktionen bleiben erhalten. Eine Abfahrt ist bei jedem Modell erst mit geschlossenen Bereichen möglich.

Mit Godot 4.6.3 geprüft: Der neue grafische Test `all_vehicle_parts_test.gd` durchläuft jedes Teil bei jedem Modell einschließlich Markierung, Öffnen, erneutem Anvisieren zum Schließen und Freigabeprüfung. Der Fahrertest für alle vier Modelle sowie Fundament-, Verkehrs- und Stellplatztests wurden ebenfalls bestanden. Screenshots der hinteren Öffnungen wurden visuell geprüft. Windows/Godot 4.7.2 ist noch vom Nutzer zu testen.

## Schritt 4 – Personendurchsuchung und Inventare · umgesetzt

### Ablauf

Eine Aktion **Person durchsuchen** im Mausrad-Menü des ausgestiegenen Fahrers startet die Durchsuchung. Der Spieler muss keine Taschen oder Körperbereiche einzeln abarbeiten. Der Fahrer hebt in einer circa 1,6 Sekunden langen Platzhalteranimation die Arme und nimmt eine Durchsuchungshaltung ein. Erst danach werden seine mitgeführten Gegenstände sichtbar.

Die Übersicht besitzt drei Spalten: NPC-Inventar links, ausgewählter Gegenstand mit Symbol und lesbaren Details in der Mitte, Spielerinventar rechts. Anklicken betrachtet nur. Separate Schaltflächen übernehmen oder geben zurück. Esc beziehungsweise die untere Schaltfläche schließen die Übersicht und stellen die normale Wartehaltung wieder her. Esc während der kurzen Animation bricht sauber ab. Der Fahrer kann anschließend wieder einsteigen.

Verkehr und Welt laufen weiter. Spielerbewegung, Kamera und Weltinteraktionen sind während der Animation und Übersicht gesperrt. Die Übersicht verwendet den freien Mauszeiger. I öffnet in Ego-Ansicht das eigene Inventar ohne Einblick in noch nicht durchsuchte NPCs.

### Daten und Umfang

- `scripts/item_inventory.gd`: gemeinsame Inventargrundlage mit Kapazität und atomarem Verschieben derselben Gegenstandsinstanz.
- `scripts/inventory_view.gd`: Übersicht, Slots, Symbole, Details, getrennte Transferaktionen und Rückmeldungen.
- `assets/items/`: einfache eigene SVG-Symbole für Schlüsselbund, Geldbörse, Quittung und Taschenlampe.
- Alle vier Fahrer erhalten dieselben drei Gegenstandskategorien mit festen, zur Figur gehörenden Kennungen und individuell beschrifteten Quittungen. Keine zufälligen NPC-Gegenstände.
- Acht Plätze pro NPC, zwölf beim Spieler. Die Start-Taschenlampe ist ein Platzhalter ohne Benutzungsfunktion. Volles Inventar oder ungültige Übertragung verliert beziehungsweise dupliziert keinen Gegenstand. Fremdes Spielerequipment lässt sich nicht als Rückgabe an einen NPC verschieben.
- Der Verkehrsmanager hält das Inventar jeder festen Figur für die Sitzung vor. Eine erneute Durchfahrt erzeugt keine bereits weggenommenen Items neu. Übernommene Gegenstände bleiben beim Spieler. Ein Spielneustart setzt die Daten zurück.

### Prüfung

Godot 4.6.3 unter Linux: Inventartest für volle Kapazität, Übernehmen/Rückgabe, fehlgeschlagene doppelte Transfers, feste Identitäten und erhaltene NPC-Inhalte bei erneuter Durchfahrt. Die Suchhaltung wurde für alle vier Fahrer geprüft. Der grafische Test durchläuft Menü, verzögerte Inventaröffnung, Details, Transfer/Rückgabe, Bewegung-/Blicksperre, weiterfahrenden Verkehr, Schließen, eigenes Inventar und Abbruch. Die Übersicht wurde anhand eines Screenshots visuell geprüft.

Bestehende Fundament-, Verkehrs-, Fahrer- und Stellplatztests sind weiterhin bestanden. Der vorhandene grafische Fahrermenütest wurde an die zusätzliche Aktion angepasst und erneut bestanden. Der Windows-Test unter Godot 4.7.2 steht noch aus.

### Grenzen

Keine Speicherung über Spielneustarts, Gewicht, verschachtelten Taschen, Drag-and-drop oder 3D-Objektdrehung. Kein Beweis-/Bewertungssystem, keine Durchsuchung der Fahrzeuge und keine zusätzlichen Dialoge. Eine einzelne Durchsuchung gehört zur aktuell reservierten Kontrolle. `main` und `develop` bleiben unverändert.

## Schritt 5 – Fahrzeugdurchsuchung · umgesetzt

### Ablauf

Bei einem angehaltenen Fahrzeug den hinteren Ladebereich öffnen und in den Innenraum schauen. Der Innenraum hat eine eigene gelbe Fadenkreuz-Markierung und den E-Hinweis **Laderaum durchsuchen**. Ein Blick auf den Türflügel bedient weiterhin die Tür. Beim Transporter reicht eine geöffnete Ladetür. Der Fahrer muss nicht aussteigen.

E startet eine circa 1,4 Sekunden lange einfache Kamerabewegung. Danach öffnet sich die gemeinsame Inventarübersicht im Fahrzeugmodus: feste Fahrzeuggegenstände links, ausgewähltes Item in der Mitte und Spieler rechts. Eigene Aktionen **Entnehmen / Zurücklegen**; Esc beendet oder bricht die kurze Bewegung ab. Die Welt läuft weiter, Spielerbewegung und Blick bleiben währenddessen gesperrt.

### Daten und Darstellung

- `scripts/cargo_zone.gd`: eigener Innenraum-Trefferbereich auf Basis der bisherigen Hervorhebung; nur bei geöffnetem Ladebereich aktiv. Keine zusätzlichen Klicks auf einzelne Behälter nötig.
- Fahrzeug-Inventare sind im Verkehrsmanager getrennt von NPC-Inventaren nach Kennzeichen gespeichert und bleiben innerhalb einer Sitzung erhalten.
- Neun Plätze und drei feste Gegenstände pro Fahrzeug, eigene Quellenkennung für korrektes Zurücklegen. NPC-Taschen sind kein zulässiges Ziel für Fahrzeuggegenstände.
- Bobby: Werkzeugkoffer, Ersatzteil, Werkstattbeleg. Nora: Einkaufstasche, Geschenk, Kassenbon. Erik: Paket, Arbeitsmaterial, Lieferschein. Mara: Seil, Werkzeugkoffer, Handschuhe.
- Einfache sichtbare Platzhalter im Laderaum sind über die Gegenstandskennung mit den Daten verknüpft. Entnommene Items verschwinden, zurückgelegte erscheinen wieder. Auch nach einer vollständig leeren erneuten Durchfahrt wird beim Zurücklegen der richtige Platzhalter wiederhergestellt.
- Geschlossene Ladebereiche oder fahrende Fahrzeuge lassen sich nicht durchsuchen. Während der Suche ist die Abfahrt gesperrt. Der Fahrerzustand wird beim Beenden nicht verändert.

### Prüfung

Mit Godot 4.6.3 unter Linux bestanden: neuer Datentest für alle vier festen Inventare, Trennung von Personen-/Fahrzeuginhalt, Entnehmen, korrekte Rückgabe, passende sichtbare Beladung sowie teilweise und vollständig leere Wiederkehr ohne Duplikate. Neuer grafischer Test für alle vier Modelle: verschlossener/geöffneter Zugang, eine einzelne offene Transportertür, Innenraum-Markierung, E, verzögerte Inventaransicht, sitzender Fahrer, Transfer und leere Darstellung, Schließen und Abbruch.

Die bisherigen Fundament-, Verkehrs-, Fahrer-, Stellplatz-, Personeninventar- und grafischen Fahrzeugbereichstests sind weiterhin bestanden. Screenshots von Innenräumen und Fahrzeug-Inventar wurden visuell geprüft. Windows/Godot 4.7.2 ist noch vom Nutzer zu prüfen.

### Grenzen

Ein gemeinsames Ladeinventar je Fahrzeug. Keine Handschuhfächer, versteckten Fächer, verschachtelten Taschen, freie Gegenstandsplatzierung, rechtliche Bewertung oder Speicherung über Spielneustarts. Die Beladungsmodelle sind Platzhalter. Kein Merge nach `develop` oder `main`.

## Gegenstände in 3D untersuchen und Ablauf abstimmen · umgesetzt

Die mittlere Inventarspalte zeigt nach Auswahl ein prozedurales 3D-Modell. Linke Maustaste und Ziehen drehen es frei um zwei Achsen; Mausrad zoomt, ein eigener Knopf setzt die Ansicht zurück. Alle neun vorhandenen Symbolkategorien besitzen Modelle: Schlüssel, Geldbörse, Papier, Werkzeugkoffer, Paket, Tasche, Seil, Handschuhe und Taschenlampe. Quittungen zeigen ihren Inhalt auf Vorder- und Rückseite. Die Beschreibung bleibt als lesbarer Text bestehen, die zusätzliche Besitzerzeile wurde entfernt. Eigentumsdaten werden intern weiterhin zur Rückgabeprüfung verwendet.

`scripts/item_preview.gd` verwendet eine isolierte SubViewport-3D-Welt mit eigener Kamera und Beleuchtung. Die Ansicht verändert keine Gegenstands- oder Spielwelt-Daten. Die Modelle bleiben einfache Platzhalter; es gibt noch keine frei verwendbaren Gegenstände oder neue Beweise.

Zeitabstimmung in `scripts/interaction_timings.gd`: Aus-/Einsteigen von 2,4 auf 3,6 s, Personendurchsuchung von 1,6 auf 3,2 s, Fahrzeugdurchsuchung von 1,4 auf 3 s; manuelle Klappenbewegungen von 3,5 auf 2,3 rad/s. Ein kompakter Fortschrittsbalken ersetzt das Fadenkreuz während Fahrer-/Suchanimationen und verschwindet bei Abschluss oder Abbruch. Einfahrtempo von 9 auf 14,4 km/h erhöht; Ausfahrtempo bleibt separat bei 9 km/h.

Mit Godot 4.6.3 unter Linux geprüft: Fundament-, Verkehrs-, Fahrer-, Stellplatz-, Personeninventar- und Fahrzeuginventartests mit den angepassten Zeiten weiterhin bestanden. Neuer grafischer Test für neun echte 3D-Modellkategorien, Rotation, Zoom, Rücksetzen, Papierseiten, entfernte Besitzerzeile und unveränderte Gegenstände. Die grafischen Personen-/Fahrzeugsuchtests prüfen die längeren Abläufe, der Personentest zusätzlich den kompakten Fortschrittsbalken. Der bestehende Fahrzeugbereichstest für Türbedienung und Übergabe an die Fahreranimation ist mit den längeren Zeiten ebenfalls bestanden. Vorschau und Balken wurden anhand von Screenshots geprüft. Windows/Godot 4.7.2 ist noch vom Nutzer zu testen.

## Ladebalken auf Durchsuchungen begrenzen und Ladeflächen betreten · umgesetzt

Der Fortschrittsbalken erscheint nur noch bei Personen- und Fahrzeugdurchsuchungen. Aus-/Einsteigen des Fahrers und die neue Kletterbewegung laufen ohne Balken.

Am offenen Heck eines geparkten Pickups oder Transporters bietet die Leertaste das Hochklettern an. Die Bewegung hebt den Spieler zunächst über die Kante und setzt ihn auf dem tatsächlichen Ladeboden ab. Anschließend ist normale Bewegung auf der Ladefläche möglich. Leertaste führt wieder hinter das Fahrzeug auf den Boden. Es handelt sich um eine gezielte Fahrzeuginteraktion, noch kein allgemeines Parkour-System.

`scripts/vehicle_climb.gd` prüft Fahrzeug, Blickrichtung, geöffneten Zugang und freien Zielpunkt. Bei einem Hindernis während der Bewegung wird zum Ausgangspunkt zurückgekehrt. Beim Transporter wird eine geöffnete Türseite gewählt und automatisch eine niedrigere Kollisionskapsel mit angepasster Augenhöhe verwendet. Nach dem Verlassen wird die normale Höhe wiederhergestellt.

Transporter und Pickup haben getrennte Kollisionen für Kabine, Ladeboden und Begrenzungen, der Transporter zusätzlich für das Dach. Während der Spieler an Bord ist, bleiben Abfahrt und Schließen der hinteren Öffnung gesperrt. Die Fahrzeugdurchsuchung ist auch von innen möglich und beendet den Zustand an Bord nicht.

Mit Godot 4.6.3 unter Linux geprüft: grafischer Test für beide Modelle, blockierte/geschlossene Zugänge, Klettern, begehbaren Boden, Duckhöhe, Heruntersteigen, Interaktion von innen und fehlenden Balken beim Klettern beziehungsweise Aussteigen. Bestehende Fundament-, Verkehrs-, Fahrer-, Stellplatz- und Inventartests bestanden. Windows/Godot 4.7.2 ist noch vom Nutzer zu prüfen.

## Weiterfahren vom Gehweg und Streifenabholung · umgesetzt

### Bedienung und Ablauf

Die Aktion „Weiterfahren lassen“ ist nun auch beim ausgestiegenen Fahrer verfügbar: Er steigt ein und fährt anschließend ab. „Einsteigen lassen“ bleibt eine eigene Aktion ohne automatische Abfahrt. Die vorhandenen Sperren für offene Klappen, Durchsuchungen und einen Spieler auf der Ladefläche bleiben wirksam.

Eine einfache Polizistenfigur mit Gehbewegung zeigt den tatsächlichen Spielerstandort in der Vogelperspektive. In der Ego-Ansicht wird sie ausgeblendet. Das Spielerinventar enthält zusätzlich ein Funkgerät mit eigener 3D-Vorschau. T öffnet ein sichtbares Handgerät mit Display und Bedienfeld. Währenddessen sind Bewegung und Blick gesperrt; Verkehr und Wartezeit laufen weiter.

Das Personenmenü bietet „Festnehmen“ beziehungsweise „Festnahme aufheben“. Eine festgenommene Person kann nicht selbst weiterfahren. Über das Funkgerät wird ihre Abholung angefordert. Es gibt maximal einen laufenden Auftrag; während der ersten 20 Sekunden ist ein Abbruch möglich. Erst nach dieser Wartezeit erscheint der Streifenwagen an einem freien Spawnpunkt und fährt zum zweiten Stellplatz vor dem kontrollierten Fahrzeug.

Der Streifenpolizist steigt aus, läuft zum Verhafteten, begleitet ihn um das Fahrzeug zur Beifahrerseite, setzt ihn in den Streifenwagen, steigt selbst wieder ein und fährt ab. Während der reservierten Abholung sind konkurrierende Fahrzeug-/Personeninteraktionen gesperrt. Der Verkehr berücksichtigt den Streifenwagen. Die Anfahrt umgeht den belegten Kontrollplatz auf dessen Bordsteinseite.

### Technik und Prüfung

`scripts/patrol_dispatch.gd` steuert Wartezeit, Anfahrt, Begleitung, Einsteigen und Abfahrt als Zustandsfolge. `scripts/police_visuals.gd` baut Spielerfigur und Handfunkgerät. Fahrer erhalten einen Festnahmestatus und eine Handschellendarstellung. Der Verkehrsmanager merkt sich abgeholte Personen für die Sitzung, damit sie nicht erneut spawnen.

Godot 4.6.3 unter Linux: Getrennter Einsteige-/Abfahrttest für alle vier Fahrzeugmodelle bestanden. Abholtest für alle vier Fahrer einschließlich 20-Sekunden-Grenze, Abbruch und erneuter Anforderung, zweitem Stellplatz, Begleiten, Einsteigen, Abfahrt, Freigabe des Kontrollplatzes und unterbundener Wiederkehr bestanden. Grafischer Test prüft Figurenanzeige, Menüs, Funkdisplay und die vollständige Abholung. Bestehende Fundament-, Verkehrs-, Fahrer-, Stellplatz- sowie Personen-/Fahrzeuginventartests bestanden. Windows/Godot 4.7.2 bleibt vom Nutzer zu prüfen.

### Vorläufige Grenzen

Die Festnahme ist eine manuelle Testaktion ohne rechtliche Bewertung. Feste Wege statt allgemeiner Navigation; ein Streifenauftrag gleichzeitig. Nach dem Transport wird das leere Ursprungsfahrzeug vorläufig entfernt, ohne Abschleppanimation. Keine Speicherung von Haftstatus über einen Spielneustart. `main` und `develop` bleiben unverändert.

## Dokumentenansicht · erster Schritt umgesetzt

### Verhalten

Die neue Aktion „Dokumente anfordern“ steht am Fenster und beim ausgestiegenen Fahrer zur Verfügung, solange keine Streifenabholung reserviert ist. Zwei farblich getrennte Karten zeigen Führerschein und Fahrzeugpapier nebeneinander. Ziehen an der Titelleiste verschiebt eine Karte und holt sie nach vorne; Begrenzungen halten die Karten erreichbar. „Dokumente anordnen“ setzt die Positionen zurück. Esc beziehungsweise „Dokumente zurückgeben“ schließt die Ansicht und aktiviert wieder die Maussteuerung. Die Simulation läuft weiter, Spielerbewegung und andere Interaktionen sind gesperrt.

### Daten und Darstellung

`scripts/document_data.gd` enthält feste Identitäten für alle vier Fahrer. Kennzeichen und Fahrzeugtyp stammen aus dem kontrollierten Fahrzeug. Die Papiere zeigen Name, Geburtsdatum, Führerscheinnummer, Klasse, Ausstellungsdatum und Gültigkeit sowie Kennzeichen, Halter, Typ, Farbe und Erstzulassung. Eriks Halter ist „Sommer Logistik“; daraus entsteht keine automatische Bewertung. `scripts/document_view.gd` baut die skalierbare Ansicht mit verschiebbaren Karten. Das Lichtbild bleibt ein gemeinsamer Platzhalter passend zum derzeitigen Fahrer-Modell.

### Prüfung und Umfang

Grafisch mit Godot 4.6.3 unter Linux geprüft: alle vier Dokumentpaare, Zugang am Fenster und beim ausgestiegenen Fahrer, korrekte Namen und Kennzeichen, zwei gleichzeitige Karten, Verschieben und Begrenzung, freier Mauszeiger, gesperrte Weltinteraktion und Schließen mit Esc. Screenshot auf Lesbarkeit geprüft. Bestehender Fahrer-Menütest an die zusätzliche Aktion angepasst. Windows/Godot 4.7.2 benötigt einen Praxistest.

Dieser Schritt enthält ausschließlich Anfordern und Ansehen. Vergleichsmodus, absichtliche Abweichungen, Dialoge und rechtliche Bewertung folgen getrennt. Dokumente sind keine übertragbaren Inventargegenstände. Arbeit bleibt auf `feature/fundamentals`.

## Dokumentenprüfung mit Vogelperspektive und Slow Motion · umgesetzt

`scripts/document_mode.gd` verwaltet einen eigenen Prüfmodus mit separater Kamera. Beim Anfordern gleitet diese in 0,55 Echtzeitsekunden vom Spieler zu einer erhöhten Ansicht über das kontrollierte Fahrzeug. Der Spieler bleibt sichtbar in der Welt. Das normale HUD wird ausgeblendet, die reguläre Übersichtskamera bleibt unverändert.

Die globale Spielgeschwindigkeit wird auf 18 % des vorherigen Werts gesetzt. Verkehr, Fahreranimationen und Streifen-Wartezeit folgen dieser Zeit. Maus und Kartenverschieben sind ereignisgesteuert und bleiben direkt; die Kameraübergänge ignorieren die Zeitlupe. Bewegung, Blick und andere Aktionen sind während Prüfung und Rückweg gesperrt.

Die Dokumente liegen auf einer eigenen Canvas-Ebene vor der Spielwelt. `shaders/document_world.gdshader` entsättigt und verdunkelt ausschließlich den dahinterliegenden Bildinhalt; Karten und Bedienung bleiben farbig. Die beiden verschiebbaren Karten starten zentriert nebeneinander. Esc oder Rückgabe stellt die vorherige Geschwindigkeit sofort wieder her, gleitet in 0,4 Sekunden zur Ego-Kamera zurück und aktiviert anschließend HUD und Steuerung. Beim Entfernen der Szene wird die Geschwindigkeit ebenfalls wiederhergestellt.

Grafische Prüfung mit Godot 4.6.3 unter Linux: Dokumente aller vier Fahrer, aktive erhöhte Prüfkamera, verstecktes HUD, Zeitlupe mit weiterlaufender Weltzeit, Kartenbedienung, Rückkehr zur Ego-Ansicht und Wiederherstellung einer abweichenden vorherigen Geschwindigkeit sowie Szenenabbau. Darstellung anhand eines Screenshots geprüft. Windows/Godot 4.7.2 benötigt einen Praxistest. Kein Vergleichs- oder Dialogsystem ergänzt.

## Bedienungsanzeige links oben entfernt · umgesetzt

Der dauerhafte Kasten mit Perspektiventitel, Tastaturübersicht, Fahrzeugzähler und Kontrollstatus wurde vollständig entfernt. Situative E-/Kletterhinweise und kurze Aktionsrückmeldungen erscheinen unten mittig. Der Anhalteknopf bleibt bei ausgewähltem Fahrzeug in der Vogelperspektive verfügbar und steht nun ebenfalls unten mittig. Keine neue Debug-Ansicht ergänzt.

## Spieler-Waffenleiste und Holsterbedienung · umgesetzt

### Verhalten

Glock 19 und Taser sind zusätzliche Spieler-Inventargegenstände mit eigenen Symbolen und drehbaren 3D-Vorschauen. Zwei Schnellplätze unten zeigen Auswahl und Zustand (Holster, Griff, Zielen). Tasten 1/2, Mausrad außerhalb von Menüs und die Schaltflächen wählen den Platz. Beide Waffen starten in getrennten Gürtelholstern.

Shift halten startet den Griff; Rechtsklick halten zieht anschließend die ausgewählte Waffe in die Zielhaltung. Auch direkt aufeinanderfolgende Eingaben funktionieren: die Zielhaltung wartet auf den kurzen Griff. Beim Zielen darf Shift losgelassen werden; Rechtsklick hält die Waffe gezogen. Nach Loslassen der rechten Taste wird geholstert beziehungsweise bei weiter gehaltenem Shift zum Griff zurückgekehrt. Ein Wechsel setzt die Haltung zurück. Strg übernimmt das bisherige Sprinten, solange keine Waffe gegriffen oder gezogen ist.

### Technik und Grenzen

`scripts/player_equipment.gd` steuert Holster-/Griff-/Zielzustand, Auswahl, Eingaben, Schnellleiste, Ego-Hand und Holsterdarstellung. Die Armknoten der Spielerfigur sind nun bewegliche Pivots. `scripts/weapon_visuals.gd` erzeugt eine Glock-19-Silhouette mit kompaktem Schlitten, Griff, offenem Abzugsbügel und Visierung sowie einen gelb abgesetzten Taser. Beide Modelle werden für Gürtel, Ego-Ansicht und Inventar wiederverwendet. Es handelt sich um eigene vereinfachte Low-Poly-Modelle.

Waffenbedienung steht nur in freier Ego-Ansicht zur Verfügung. Menüs, Funk, Dokumentenmodus, Klettern, Fokusverlust und Perspektivwechsel setzen die Haltung zurück. Während der Waffenhaltung sind E-Interaktionen gesperrt. Die bestehende Mausradbedienung von Menüs und Übersicht bleibt erhalten. Schießen, Taserwirkung, Munition, Treffer und NPC-Reaktionen gehören nicht zu diesem Schritt.

### Prüfung

Godot 4.6.3 unter Linux: neuer grafischer Test für beide Inventargegenstände, getrennte Holster, Auswahl, Griff ohne Ziehen, Rechtsklick ohne Griff, reguläre und schnelle Eingabefolge, Loslassen, Wechsel sowie Wechsel zu Inventar, Funk und Übersicht. Vorhandene Inventartests an vier Startgegenstände angepasst; die 3D-Vorschau deckt jetzt zwölf Kategorien ab. Screenshots der Ego-Haltung und Leiste geprüft. Windows/Godot 4.7.2 benötigt einen Praxistest.

## Glock-Schusssystem und Ersatzmagazine · umgesetzt

### Bedienung

Linksklick bei vollständig gezogener und zielender Glock erzeugt genau einen Schuss mit 0,16 Sekunden Mindestabstand. Gedrückthalten erzeugt kein Dauerfeuer. R ersetzt den Spieler-Reset vollständig und wechselt bei gezogener Waffe in etwa 1,8 Sekunden das Magazin. Während des Wechsels wird die Waffe abgesenkt, seitlich gehalten und durch eine zweite Hand ergänzt; ein zusätzlicher Ladebalken erscheint nicht. Rechtsklick bleibt während des Nachladens gehalten.

### Munition und Daten

Ein eingesetztes 15er-Magazin und zwei zusätzliche volle Magazine ergeben 45 Startpatronen. Die zwei Ersatzmagazine sind normale Spieler-Inventargegenstände, das eingesetzte Magazin ist in den Daten der Glock enthalten. Jedes Magazin hat eine eigene Kennung und einen veränderlichen Füllstand. Das vollste geeignete Ersatzmagazin muss mehr Patronen als das eingesetzte besitzen; volle Magazine werden nicht gewechselt. Erst nach Ablauf der Zeit werden die beiden Magazin-Datensätze ausgetauscht. Teilvolle und leere Magazine bleiben erhalten, ohne Verluste oder Duplikate. Abbruch durch Holstern, Auswahlwechsel, Menüs oder Fokusverlust verändert keine Füllstände. Beschreibungen und Leiste zeigen den Zustand an; Magazine besitzen Symbol und 3D-Vorschau.

### Feedback und Grenzen

`scripts/pistol_action.gd` kapselt Schussabstand, Magazine, Nachladezeit und Effekte. Ein Kamera-Strahl gegen Welt, Fahrzeuge und Personen ermittelt nur den Auftreffpunkt. Kurzer Mündungsblitz mit Licht, Handrückstoß, temporäre Schusslinie und kurz schrumpfender Auftreffpunkt machen den Schuss sichtbar. Eigene synthetische WAV-Dateien liefern Knall und mechanisches Klicken. Es werden keine Schadensmethoden aufgerufen und keine NPC-Zustände verändert.

Kein Schadensmodell, keine Taserwirkung, Trefferwertung, Patronenlager-Simulation, lose Munition oder Magazinbefüllung. Die Effekte sind Test-Platzhalter. Die Munitionsdaten gelten wie das bisherige Inventar nur während der Sitzung.

### Prüfung

Grafischer Test mit Godot 4.6.3 unter Linux: Startmunition, R ohne Positionsreset, Schießen ausschließlich beim Zielen, Einzelschuss und Mindestabstand, Welt-Treffer, Blitz/Rückstoß, leeres Magazin, zeitversetzter Magazinwechsel, Erhaltung von Restmunition, Abbruch durch Waffenwechsel, getrennte Taser-/Glock-Daten und fehlende Ersatzmunition. Screenshots von Schuss und Nachladehaltung geprüft. Inventartests auf sechs Startgegenstände und 3D-Vorschautest auf 13 Kategorien angepasst. Windows/Godot 4.7.2 benötigt einen Praxistest.

## Mit Glock zur Aufgabe zwingen und direkt Handschellen anlegen · umgesetzt

### Erkennung und Verhalten

`scripts/npc_compliance.gd` erkennt Kopf/Oberkörper im Zielstrahl der vollständig gezogenen Glock. Eine kurze Zielzeit von 0,25 Sekunden und maximal 25 Meter Entfernung verhindern eine Aufgabe beim bloßen Vorbeischwenken. Freie Ego-Bedienung ist erforderlich; Holster, Griff allein, Taser, Nachladen und bereits verhaftete Personen lösen keine neue Aufgabe aus. Die Munition spielt keine Rolle. Sichtstrahlen respektieren Welt und fremde Fahrzeuge; die gesamte Ziel-Fahrzeugkollision wird wegen ihrer bisher groben Kabinenform ausgenommen.

Der Fahrer erhält einen eigenen persistenten Aufgabestatus, getrennt von der Festnahme. Die Arme bleiben in Sitz-, Aussteige- und Außenpose oben, auch wenn die Waffe anschließend gesenkt wird. Ein fahrendes Auto bremst mit 4 m/s² bis zum Stillstand, bevor der Fahrer aussteigt. Ein bereits stehender Fahrer steigt unmittelbar über die vorhandene Aussteigeanimation aus. Erneutes Zielen startet die Animation nicht neu. Ein gerade einsteigender Fahrer kehrt die Bewegung um. Eine automatische Abfahrt wird abgebrochen; solange die Hände oben sind, sind Einsteigen und Weiterfahren gesperrt.

### Festnahme und Folgeaktionen

In etwa zwei Metern Reichweite und mit Blick auf den ausgestiegenen NPC zeigt das HUD „E: Handschellen anlegen“. E führt die Festnahme direkt aus, auch bei gezogener Waffe. Der Spieler holstert, der NPC wechselt von erhobenen Händen zur bestehenden Handschellenpose. Die Aufgabe selbst gilt noch nicht als Festnahme. Nach Aufheben der Festnahme können Einsteigen und Weiterfahren wieder normal genutzt werden.

Das Interaktionsziel kann jetzt auch eine an der Straße angehaltene Person sein; ein geöffnetes Menü behält seinen ursprünglichen Gesprächspartner. Funkanforderungen merken sich diesen Partner, statt immer die Person am Kontrollstellplatz zu verwenden. Eine parallel laufende Kontrolle wird bei der Abholung nicht gelöscht. Der Streifenpolizist nutzt bei Straßenstopps einen Weg um das Fahrzeugheck zum tatsächlichen NPC-Standort. Bei Rückstau bis zum üblichen Spawn fährt die Streife für diesen Fall seitlich an und nutzt weiter Stellplatz zwei.

### Prüfung und Grenzen

Grafisch unter Godot 4.6.3/Linux: alle vier Kabinen/Fahrer, Arme bereits vor dem Bremsende oben, verzögertes Anhalten statt Sofortstopp, Aussteigen mit erhobenen Händen, Aufgabe nach Holstern, Nähe für Handschellen, direkte E-Festnahme bei gezogener Glock und Funk-/Menüfolge. Zusätzliche Fälle für bereits ausgestiegene/verhaftete NPCs, Blick neben die Person, Taser und Sichtblockade durch eine Wand. Abholtest für die vier bisherigen Fälle plus Straßenabholung bei anderer belegter Kontrollbucht bestanden. Bestehende Fundament-, Verkehrs-, Fahrer-, Stellplatz-, Abfahrts- und Inventartests bestanden. Screenshots der Aufgabe geprüft; Windows/Godot 4.7.2 bleibt praktisch zu testen.

Feste, kooperative Reaktion ohne Flucht-/Kampf-KI oder rechtliche Bewertung. Fahrzeuge halten auf ihrer aktuellen Strecke; noch kein allgemeines Ausweichen oder sicheres Heranfahren an den Straßenrand. Schaden und Taserwirkung bleiben unverändert außerhalb dieses Schritts.

## Interaktive Werkzeugkoffer · erste Testversion auf feature/vehicleSearches

### Ausgangspunkt und Bedienung

`feature/fundamentals` wurde per PR #1 nach `develop` übernommen. Der neue Branch `feature/vehicleSearches` wurde von diesem Integrationsstand abgeleitet. Dieser Schritt erweitert die Gegenstandsuntersuchung; der bisherige Zugang zur Fahrzeugladung bleibt bestehen.

Werkzeugkoffer bieten in Fahrzeug- und Spielerinventar „Genauer untersuchen“. Die große 3D-Ansicht besitzt anklickbare Bereiche für Verschluss, Deckel und Inhalt. Ein goldener Verschluss wird zuerst gelöst, danach klappt der Deckel auf. Linksklick bedient oder wählt einen sichtbaren Gegenstand; Rechtsziehen dreht die Gesamtszene, Mausrad zoomt. Anklickbare Teile werden beim Überfahren hervorgehoben. Rechts erscheint die drehbare Nahansicht des gewählten Gegenstands mit Beschreibung und eigener Entnahmeaktion. Esc kehrt zuerst zum Inventar zurück, danach zur Welt. Keine neuen Suchbalken oder zusätzlichen Wartezeiten.

### Daten und sichtbare Funde

Bobbys Koffer enthält einen Hammer und ein Messer mit sichtbaren dunkelroten Spuren. Maras Koffer enthält nur einen Hammer. Vor dem Öffnen verrät kein Inventartext das Messer; die Spuren sind Bestandteil der sichtbaren Geometrie, keine automatische bestätigte Blut-/Straftatbewertung. Eriks kistenförmiges Arbeitsmaterial bleibt ein anderer Gegenstand ohne diese Funktion.

Der Koffer speichert entriegelten/offenen Zustand und ein eigenes kleines Inhaltsinventar. Jeder Inhalt hat eine feste Kennung und die Kennung seines ursprünglichen Koffers. Entnehmen verschiebt denselben Datensatz in das Spielerinventar; Zurücklegen ist über die Kofferansicht nur zum ursprünglichen Behälter möglich. Direkte Rückgabe solcher Inhalte als lose Fahrzeug-/NPC-Gegenstände ist gesperrt. Ein volles Ziel verhindert die Übertragung. Der ganze Koffer bleibt als Gegenstand transportierbar, ohne Inhalt oder Öffnungszustand zurückzusetzen. Der bestehende Sitzungscache hält die Daten auch bei erneuter Fahrzeugdurchfahrt.

### Technik

`scripts/toolbox_model.gd` baut Basis, Scharnierdeckel, Verschluss, Hammer und Messer mit einfacher Low-Poly-Geometrie. `scripts/toolbox_preview.gd` nutzt eine isolierte 3D-Welt, eigene Kamera und echte Physikstrahlen gegen die anklickbaren Teile. Der Deckel bewegt sich sichtbar; geschlossener oder gerade bewegter Deckel verhindert die Inhaltsbedienung. Die Oberfläche liegt in `scripts/toolbox_inspection.gd`, eingebettet in die bestehende Inventaransicht. Hammer und Messer besitzen eigene SVG-Symbole und verwenden auch außerhalb des Koffers dieselben 3D-Modelle.

### Prüfung und Grenzen

Godot 4.6.3/Linux: grafischer Test für feste Kofferinhalte, verschlossene/entriegelte/geöffnete Zustände, reale Strahlen auf Verschluss/Deckel/Messer, Hervorhebung, sichtbare Inhalte, volle Inventare, Entnehmen und korrektes Zurücklegen, Schutz gegen doppelte Entnahme, erste Esc-Ebene, Mitnehmen des ganzen Koffers und Wiederkehr ohne Wiederbefüllung. Screenshots auf Darstellung und Lesbarkeit geprüft. Vorhandene Personen-/Fahrzeuginventartests bestanden; gemeinsamer 3D-Modelltest auf 15 Kategorien erweitert. Windows/Godot 4.7.2 benötigt einen Praxistest.

Ein Behältertyp, keine beliebige Verschachtelung oder Speicherung über Neustarts. Kein Farbeimer, keine Analyse, neuen Dialoge oder automatische Bewertung. Öffnungsbewegungen gelten für die Untersuchungsszene; die Beladung in der Welt bleibt ein vereinfachter Platzhalter. Änderungen bleiben auf `feature/vehicleSearches`.

## Fehlerkorrektur: Absturz bei Koffer-Hervorhebung

Der bedingte Ausdruck für die hervorzuhebenden Meshes erzeugte bei Verschluss und Deckel ein untypisiertes Array. Die Zuweisung an `Array[Node]` konnte dadurch zur Laufzeit abbrechen. Die Liste wird jetzt explizit typisiert erzeugt und per `append` beziehungsweise `assign` befüllt. Der grafische Koffertest deckt nun zusätzlich echtes Maus-Hover über den Verschluss, den Wechsel zum Deckel und das Entfernen der Hervorhebung ab; der Inhalt war bereits separat abgedeckt. Der erweiterte grafische Test ist unter Godot 4.6.3/Linux bestanden; Windows/Godot 4.7.2 bitte erneut prüfen.

## Fahrzeugtreffer – Schritt 1 auf feature/vehicleDamage

PR #2 wurde nach `develop` übernommen. `feature/vehicleDamage` basiert auf diesem Integrationsstand und ergänzt zunächst präzise Fahrzeugtreffer und sichtbare Einschussmarkierungen.

`scripts/vehicle_hit_surfaces.gd` erzeugt für die sichtbaren Box-/Reifen-Meshes eigene Schusstrefferkörper auf Layer 16. Boxen entsprechen ihren sichtbaren Abmessungen; Reifen erhalten eine konvexe Form aus ihrem Mesh. Die Trefferflächen folgen der vorhandenen Hierarchie für Türen, Heckklappen, Lenkung und Raddrehung. Karosserie, Glas, Reifen und Felgen sind getrennt klassifiziert. Fahrer, Beladungsplatzhalter und Auswahlring erhalten in diesem Schritt keine Fahrzeugtrefferflächen.

`scripts/pistol_action.gd` nutzt weiterhin Hitscan. Der Schussstrahl prüft Welt, die bisherige NPC-Kollision und die neuen Fahrzeugflächen; die groben Fahrzeug-/Türkollisionen für Bewegung werden ausgeschlossen. Dadurch sitzt der Treffer auf der sichtbaren Oberfläche, statt vor einer unsichtbaren Kabinenbox. Andere Weltobjekte blockieren den Strahl weiterhin. NPCs erhalten unverändert keinen Schaden.

`scripts/vehicle_hit_surface.gd` leitet Fahrzeugtreffer an die Markierungsverwaltung weiter. Ein texturiertes Quad liegt knapp über der getroffenen Oberfläche, zeigt entlang ihrer Normalen und ist dem jeweiligen Mesh untergeordnet. Die eigene SVG-Textur ist ein einfacher Einschuss-Platzhalter, rendererkompatibel ohne Decal-Node. Maximal 64 Markierungen je Fahrzeug begrenzen den Ressourcenverbrauch; die ältesten werden bei weiteren Treffern ersetzt. Die Markierungen bestehen bis zum Entfernen des Fahrzeugobjekts, ohne Wiederherstellung bei späterer Durchfahrt oder Spielneustart.

Grafischer Test unter Godot 4.6.3/Linux: alle vier Modelle mit Karosserie-, Glas-, Reifen- und Dachtreffern; echte Glock-Schüsse erzeugen Markierungen; sie folgen Türen und Fahrzeugbewegung, und die Trefferkörper folgen geöffneten Türen. Wandblockade und Markierungsbudget geprüft. Darstellung per Screenshot geprüft. Bestehende Fundament-, Verkehrs-, Fahrer-, Stellplatz- sowie Personen-/Fahrzeuginventartests bestanden. Windows/Godot 4.7.2 benötigt einen Praxistest.

Dies ist ausschließlich Schritt 1: keine Deformation, Reifenpanne, Glaszerstörung, Durchschüsse, Fahrverhaltensänderung oder Körperteilverletzung. Die eigene Trefferstruktur ist die Grundlage für diese weiteren Schritte.

## Scheiben- und Reifenschäden – Schritt 2 umgesetzt

### Scheiben

Jede Glas-Trefferfläche besitzt die Zustände intakt, angerissen und zerstört. Ein erster Treffer ergänzt eine Rissdarstellung auf beiden Seiten des jeweiligen Fensters. Der zweite Treffer blendet Glas samt Rissen aus, deaktiviert ausschließlich seine Schusskollision und erzeugt einen kurzen Splitter-/Toneffekt. Der zerstörende Schuss endet noch am Glas; folgende Schüsse nutzen die freie Öffnung. Bewegungskollisionen und Türbedienung bleiben erhalten. Die Darstellung folgt weiterhin der Tür-/Klappenhierarchie.

### Reifen und Fahrt

Ein erster Gummitreffer ersetzt den Reifen durch ein breiteres, unten abgeflachtes Low-Poly-Mesh mit eigener passender Schussform. Der beschädigte Reifen dreht nicht mehr als starrer platter Körper durch den Boden; die Felge dreht sich weiter. Pro Rad wird höchstens eine Panne gezählt. Felgentreffer allein verändern den Reifen nicht.

Die Geschwindigkeitsobergrenze beträgt bei 1/2/3/4 platten Reifen 3/1,8/0,9/0,45 m/s. Bestehende niedrigere Verkehrs-/Parklimits bleiben gültig. Die vorhandene Beschleunigungs-/Bremslogik senkt die Geschwindigkeit gleichmäßig, die Bremsleuchten zeigen das Abbremsen an. Auch vollständig beschädigte Fahrzeuge können noch langsam abfahren, um keine permanente Belegung zu verursachen.

Das Fahrzeug sinkt abhängig von den betroffenen Rädern leicht ab und neigt sich. Radpositionen werden aus gespeicherten Ausgangspositionen abgeleitet und auf der ebenen Strecke am Boden gehalten; keine kumulativen Positionsverschiebungen. Aussteigepositionen berücksichtigen die abgesenkte Stellung, damit der Fahrer neben dem Auto auf Bodenniveau bleibt. Es ist eine vereinfachte Darstellung mit weiterhin vorgegebenen Fahrwegen, keine vollständige Fahrwerkssimulation.

### Prüfung und Grenzen

Godot 4.6.3/Linux: grafischer Test für alle vier Modelle, einzelne Glaszustände, deaktivierte Glastrefferfläche und folgende freie Schussbahn, echte erste/zweite Glock-Schüsse, vier unabhängige Reifen, Felgenabgrenzung, Mehrfachtreffer ohne Mehrfachzählung, Absenkung, sanftes Abbremsen, Tempolimits, Aufgabe, Aussteigen und anschließende Abfahrt. Screenshots der Risse und beschädigten Reifen geprüft. Bestehende Treffer-/Schuss-/Nachladetests sowie Fundament-, Verkehrs-, Fahrer-, Stellplatz- und Inventartests bestanden. Windows/Godot 4.7.2 bleibt praktisch zu testen.

Kein NPC-Schaden, Reparatursystem, Schleudern oder Unfälle. Splitter sind kurzlebige kosmetische Effekte; Geräusche synthetische Platzhalter. Schaden gilt nur für das aktuelle Fahrzeugobjekt, ohne Wiederherstellung bei späterer Durchfahrt oder Neustart. Entwicklung bleibt auf `feature/vehicleDamage`; PR #3 enthält beide Schadensschritte.

## Direkte Ladungsauswahl und weitere Behälter · feature/extendedVehicleSearch

### Branch und Spielablauf

Der neue Branch wurde ausdrücklich von `develop` nach Übernahme der Werkzeugkoffer-Version abgeleitet. Die parallel entwickelten Fahrzeugschäden werden dabei nicht übernommen.

Der allgemeine Trefferbereich der Ladefläche ist dauerhaft deaktiviert. E wählt nun einen real platzierten Gegenstand und öffnet dessen fokussierte Inventar-/Untersuchungsansicht direkt, ohne Wartebalken. Die UI zeigt keine vollständige Fahrzeugladungs-Liste. Auswahl und Transfers sind auf den ursprünglich gewählten Gegenstand begrenzt; sein Inhalt bleibt bis zur erforderlichen Öffnung verborgen. Die bekannte Spieler-Inventarspalte bleibt nutzbar.

### Beladungen und Mechaniken

Pickup: Werkzeugkoffer, dekorative gesicherte Leiter und Handschuhe. Transporter: seitliches Lagerregal mit drei identisch gestalteten Farbeimern und ein Wasserfass. Limousine/Kleinwagen erhalten jeweils eine Kühlbox neben ihrer übrigen festen Ladung.

Werkzeugkoffer behalten Verschluss, Klappdeckel und die bisherigen Inhalte. Farbeimer haben einen abnehmbaren Deckel und herausnehmbaren weißen Einsatz; erst danach kann das darunterliegende Päckchen gesehen und ausgewählt werden. Kühlboxen besitzen Verschluss, Klappdeckel und herausnehmbaren Innenkorb mit wenigen Lebensmittel-Platzhaltern. Ein Päckchen liegt nur in Bobbys Kühlbox. Im Transporter enthält der zweite Farbeimer ein Päckchen, die anderen sind leer. Das Wasserfass besitzt einen abnehmbaren Deckel und eine einfache transparente Wasserfläche mit sichtbarem Päckchen darunter. Es gibt keine chemische Bestätigung oder automatische Fundbewertung.

### Technik und Zustände

`scripts/cargo_item.gd` erweitert die bisherigen Interaktionsbereiche um ein konkretes Ladungsobjekt mit Datenbindung. Reichweite, offener Zugang, Parkzustand, Sichtblockaden und reservierte Abholung begrenzen die Bedienung. Regal und Ladung besitzen einfache Kollisionen; die Leiter bleibt Dekoration. Der Transporter-Einstieg bevorzugt eine geöffnete rechte Tür neben dem Regal.

`scripts/cargo_container_model.gd` erweitert die gemeinsame Untersuchungsansicht um Farbeimer, Kühlbox und Wasserfass. Die Kamera blickt je nach Behälter stärker von oben, damit nach dem Freilegen nicht nur ein Datenflag gesetzt ist, sondern das Päckchen tatsächlich sichtbar und per Physikstrahl anklickbar wird. Verdeckte oder bewegte Inhalte sind nicht auswählbar. Modelle und Zustand werden auch in der Fahrzeugwelt verwendet; Weltladung wird nach Entnahme/Rückgabe aktualisiert.

Die bisherigen stabilen Gegenstandskennungen und das Sitzungscache bleiben erhalten. Bei leerer oder teilweiser Wiederkehr werden unsichtbare Originalplätze vorbereitet, aber nur die tatsächlichen Datensätze aus dem aktuellen Inventar eingeblendet und gebunden. Dadurch erzeugt ein zurückgelegter Behälter keine neuen Inhalte. Ganzen Behälter mitnehmen, Einsätze zurücklegen und Inhalte an ihren ursprünglichen Behälter zurückgeben bleiben möglich. Ein volles Inventar verhindert die Übertragung ohne Verlust. Die Abfahrtssperre gilt bis zum vollständigen Schließen der Untersuchungsansicht. Mitgenommene ganze Gegenstände können über I am geöffneten ursprünglichen Fahrzeug zurückgelegt werden, ohne eine Gesamtliste der Ladung anzuzeigen. Dies erhält die Rückgabemöglichkeit auch bei vollständig leerer Ladung.

### Prüfung und Grenzen

Godot 4.6.3/Linux: grafischer Test für alle vier konkreten Weltziele, geschlossene Bereiche, Wandblockade, E ohne Suchzeit, fokussierte Liste statt Gesamtliste, Zugriffsschutz auf nicht gefundene Gegenstände, erste/zweite Esc-Ebene und Freigabe der Abfahrt. Alle vier Behältertypen, verdeckte Einsätze, tatsächliches 3D-Anklicken des freigelegten Päckchens, Entnehmen/Zurücklegen und erneutes Öffnen geprüft. Werkzeugkoffer-Test und Klettertest an die neue Ladung angepasst und bestanden. Bestehende Inventar-, Verkehrs-, Fahrer-, Stellplatz- und Abfahrttests bestanden; die Modellvorschau umfasst 18 Kategorien. Screenshots der Weltbeladung und Behälter geprüft. Windows/Godot 4.7.2 benötigt einen Praxistest.

Weiterhin feste Fälle ohne Zufallsladung, allgemeine Verschachtelung, Flüssigkeitsphysik, Analyse, neue Missionen oder Speicherung über Neustarts. Die Lebensmittel im Kühlkorb und die Leiter sind bewusst einfache Platzhalter beziehungsweise Dekoration. Entwicklung bleibt auf `feature/extendedVehicleSearch`.

## Integration der direkten Fahrzeugdurchsuchung in vehicleDamage

PR #4 wurde nach `develop` übernommen. Anschließend wurde der aktualisierte Integrationsstand in `feature/vehicleDamage` zusammengeführt. Dokumentationskonflikte wurden unter Erhaltung beider Funktionsbeschreibungen aufgelöst. Der Branch enthält nun direkte Ladungsauswahl, Behälteruntersuchung und Kühlboxen gemeinsam mit Scheiben-/Reifenschäden. Die gemeinsamen grafischen Tests für Fahrzeugschäden, direkte Durchsuchung und Klettern sowie der Verkehrstest sind unter Godot 4.6.3/Linux bestanden. `main` bleibt unverändert.

## Aktive Körperphysik – separates Testlabor auf feature/bodPhysics

### Aufbau und Bedienung

Der Branch basiert auf `develop` nach Übernahme der Fahrzeugschäden. F9 führt aus dem Hauptspiel in `scenes/body_lab/body_lab.tscn`. Zwei gleich aufgebaute Figuren stehen auf einer ebenen Testfläche: links ohne Bewegungsauftrag, rechts mit prozeduralem Gehauftrag auf kurzer Strecke. Region auswählen und Leertaste gibt beiden denselben Testimpuls und regionalen Kraftverlust. Einzelne Regionen lassen sich auch direkt anklicken. Orbitkamera, Zoom, getrennte Regler für Impuls und lokalen Kraftverlust sowie Zurücksetzen ermöglichen wiederholbare Vergleiche. Rückkehr mit F9 startet eine neue Hauptspiel-Sitzung.

### Physik und Reaktion

`scripts/active_body.gd` baut im aktuellen Stand pro Figur 11 echte RigidBody3D-Segmente für Becken, Rumpf, Kopf, Oberarme, Unterarme inklusive Hände, Oberschenkel und Unterschenkel inklusive Füße. Zehn Generic6DOFJoint3D-Gelenke verbinden sie mit linearen Sperren und Winkelgrenzen. Selbstkollisionen der Figur sind im Prototyp deaktiviert; Boden und andere Figuren bleiben physikalische Kollisionspartner.

Positions- und rotationsabhängige Feder-/Dämpfungskräfte bilden virtuelle Muskeln. Rotationskräfte sind über eine näherungsweise Trägheit der Segmente skaliert; begrenzte Kräfte und gedämpfte Unterstützung vermeiden Explodieren der Glieder. Haltungs- und Gehziele werden mathematisch pro Schritt berechnet, nicht aus AnimationPlayer, AnimationTree oder vorgefertigten Trefferclips abgespielt.

Jede Region hat eine eigene Kraftreserve. Ein Oberschenkeltreffer schwächt auch die zugehörige Unterschenkel-/Fußkette; ein Oberarmtreffer entsprechend den Unterarm. Ein Impuls wirkt am tatsächlichen Treffpunkt und übernimmt die vorhandenen Geschwindigkeiten. Die Balancehilfe hängt kontinuierlich von Rumpf-/Kopfstabilität, Becken, regionaler Asymmetrie, gemessener Geschwindigkeit, Fußnähe zum Boden und tatsächlicher Körperhaltung ab. Zu tief gefallene Körper erhalten keine volle Aufrichtunterstützung. Es gibt keine Auswahl eines vorgefertigten „Beintreffer im Laufen“-Animationsclips und keine Todesanimation. Ein separater tödlicher Kopfverletzungszustand schaltet die aktive Muskelregelung ab.

Im geprüften Vergleich nach drei Sekunden hält die stehende Figur den linken Oberschenkeltreffer über das gesunde Bein aus; die bewegte Figur verliert später die Balance und fällt. Diese Reaktion ist ein Ergebnis der gewählten Regler und des Bewegungszustands, keine Garantie für jeden Trefferzeitpunkt. Die Gehbewegung und biomechanische Plausibilität bleiben experimentell.

### Prüfung und Grenzen

Godot 4.6.3/Linux: echte Physikschritte für beide Gelenkkörper, Stabilität im Stand, tatsächliche Fortbewegung und längeres unverletztes Gehen mit Richtungswechsel. Geprüft wurden lokale Kraftausbreitung, Impuls ohne Positionssprung, unterschiedliche gemessene Bewegung beim Treffer, Stand-/Bewegungsreaktion, Armverletzung mit erhaltener Beinstütze, Zurücksetzen und endliche begrenzte Positionen/Geschwindigkeiten. Grafische Vorher-/Reaktions-/Nachheransicht geprüft. Ein eigener Szenenwechseltest prüft F9 auch aus der verlangsamten Dokumentenansicht, Zeitwiederherstellung, Regionenauswahl, Reset und Rückkehr zum Hauptspiel. Windows/Godot 4.7.2 erfordert einen Praxistest; andere Physik-Backends/Solver können die Reaktion ändern.

Das Labor ist getrennt von den Verkehrs-NPCs. Es enthält keine Ballistik-, Blutungs-, Schmerz-, Heilungs- oder Aufstehlogik und keine fertige menschliche Bewegungs-KI. Virtuelle Stützkräfte sind eine bewusste Vereinfachung aktiver Ragdolls. Die Integration mit Verkehr, Handschellen, Fahrzeuganimationen und vorhandenen Waffen ist ein weiterer Schritt. Der Stand bleibt auf `feature/bodPhysics`.

## Labor-Standardwerte und gemeinsame Hand-/Fußsegmente

Die Standards liegen nun zentral bei 3,0 N·s Impuls und 95 % lokalem Kraftverlust; UI und direkter Trefferaufruf verwenden dieselben Vorgaben. Bei einmaligem Treffer bleibt 5 % der lokalen Reglerstärke, ohne diese Größe als medizinische Verletzungsschwere zu interpretieren.

Die getrennten Fuß-Starrkörper und Sprunggelenke wurden entfernt. Jeder Unterschenkel besitzt jetzt Bein- und Fußgeometrie samt zwei Kollisionsformen auf demselben RigidBody3D. Die Masse von Unterschenkel und Fuß bleibt zusammen 4 kg. Bodennähe und Kraftweitergabe werden an diesem gemeinsamen Segment ermittelt. Jeder Unterarm erhält sichtbare Hände mit eigener Kollisionsform auf demselben Körper, ohne zusätzliche Handgelenke. Fuß- und Handtreffer melden daher die zugehörige gemeinsame Region. Das Modell hat 11 statt 13 Starrkörper und 10 statt 12 Gelenke.

Mit Godot 4.6.3/Linux geprüft: neue Standards, zusammengesetzte Trefferkörper, echte Strahlen auf Hände/Füße, Ruhe- und Bewegungsstabilität, Stand-/Laufreaktion beim Oberschenkeltreffer mit 95 % und 3 N·s, Armverletzung sowie Szenenwechsel. Grafische Darstellung geprüft. Windows/Godot 4.7.2 bleibt vom Nutzer zu testen.

`apply_impulse` erhält direkt den Impulsvektor. Unter der verwendeten Meter-/Kilogramm-Skalierung sind 3,0 daher 3 N·s, nicht 3 N. Eine mittlere Kraft lässt sich erst mit einer angenommenen Dauer bestimmen: 3/0,01 = 300 N. Der Prototyp ist weiterhin keine kalibrierte Ballistiksimulation.

## Körperphysik – Zusammenbrechen nach schweren Kerntreffern

Ursache der unnatürlichen abgestützten Rumpfhaltung: Die Balancehilfe berücksichtigte Rumpfschäden, die aktiven Beinmotoren verfolgten aber weiterhin volle Standziele. Jetzt skaliert die zentrale Kraftreserve auch alle Gliedmaßenmotoren. Bei höchstens 25 % Restkraft in Kopf, Rumpf oder Becken wird der Zusammenbruch bis zum Zurücksetzen gespeichert: keine aktive Aufrichtung, Fortbewegung oder Muskelspannung mehr. Bei höchstens 10 % Kopfrestkraft gilt die Figur als tot. Diese Schwellen sind Gameplay-Regeln im Labor, keine medizinische Simulation. Restgeschwindigkeit und tatsächlicher Treffpunkt bleiben erhalten.

Knie und Ellenbogen erhalten gerichtete Beugegrenzen (bis ca. 132 Grad, maximal ca. 3 Grad Überstreckung); seitliches Knicken und axiales Verdrehen sind auf ca. 3 Grad begrenzt. Die Gelenkgrenzen bleiben auch beim passiven Körper aktiv. Selbstkollisionen sind weiterhin deaktiviert, daher wird damit keine vollständige anatomische Kollisionssimulation erreicht.

Erweiterte echte Physiktests prüfen schwere Kopf-, Rumpf- und Beckentreffer jeweils im Stand und in Bewegung: Stützregelung aus, Becken und Rumpf erreichen den Boden, tödlicher Zustand nur beim schweren Kopftreffer. Ein leichter Rumpftreffer erhält die Standfähigkeit. Bestehende Tests für gesunde Fortbewegung, isolierte Gliedmaßentreffer und Zurücksetzen bleiben enthalten.

## Körperphysik – Integration der Glock-Treffer ins Hauptspiel

### NPC-Modell und Trefferübergabe

Das Fahrer-Platzhaltermodell entspricht jetzt den elf Physikregionen. Die bisherigen vier Bein-/Armpivots bleiben für Ein-/Aussteigen, Durchsuchung und Händehoch erhalten. Geometrienahe Schusskörper auf Layer 32 ordnen auch Hand-/Fußtreffer der gemeinsamen Region zu. Die breite Interaktionskapsel wird bei Schussabfragen ausgeschlossen, damit sie keine regionalen Treffer verdeckt. Fahrzeugtrefferflächen bleiben auf Layer 16 und blockieren die Sichtlinie weiterhin.

Beim ersten Glock-Treffer erstellt der Fahrer den gemeinsamen ActiveBody, übergibt jede sichtbare Segmentpose sowie vorhandene Bewegung und blendet den prozeduralen Rig aus. Danach zeigen die Metadaten der dynamischen Segmente wieder auf denselben Fahrer: Folgetreffer wirken auf die physisch aktuelle Region. 95 % Kraftverlust und 3 N·s kommen aus den gemeinsamen Standardkonstanten. Kleidung, Haare und Gesichtsdetails werden übernommen. Die neutralen anatomischen Gelenkrahmen bleiben bei der Poseübergabe erhalten; Schultern erlauben das Absenken vormals erhobener Arme, Knie/Ellenbogen behalten ihre gerichteten Grenzen.

### Sitzpose, Fahrzeug und Ablaufgrenzen

Die Physikfigur ist ein Top-Level-Kind des Fahrers und wird daher nicht starr mit dem Fahrzeug verschoben, beim Entfernen des Fahrers aber mit aufgeräumt. Sitzende Körper erhalten keine Stehregelung. Da die bisherigen Interaktionskollisionen keine ausmodellierte Kabine bilden, werden eigene grobe Fahrzeugkollisionen ausgenommen und Sitzfläche, Lehne und Fußboden als unsichtbare Stützen auf Layer 64 ergänzt. Diese Helfer folgen dem Fahrzeug und werden beim Reset oder Entfernen des Physikkörpers entfernt.

Jeder verletzte Fahrer bremst mit 4 m/s² bis zum Stillstand und führt keine Aussteige-/Freigabeanimation mehr aus. Verletzte Personen sind vorerst von normalen Personeninteraktionen ausgeschlossen; ein laufender Streifenabtransport endet bei verletztem Verdächtigen oder Beamten. Sanitätsdienst, Wiederaufstehen, weitere Verletzteninteraktionen und medizinische Genauigkeit sind nicht Teil dieses Schritts.

### Prüfung

Godot 4.6.3/Linux: neue Integrationstests für alle vier Fahrzeugmodelle mit echten Straßenkollisionen, regionalen Glock-Strahlen, Poseübergabe, dynamischen Folgetreffern, Kopf-/Beinzuständen, erhobenen Armen, Glasabdeckung, Sitzstützen, Abbremsen und Reset. Grafischer Test schießt über die bestehende Waffenfunktion samt Magazinverbrauch; headless wird wegen fehlender Mausaufnahme der unveränderte gemeinsame Trefferpfad genutzt. Bestehende Labortests sowie Fahrer-, Verkehr-, Freigabe-, Inventar- und Streifentests bestanden. Waffen-, Fahrzeugtreffer-, Fahrzeugschaden- und Aufgabetests wurden zusätzlich grafisch geprüft. Windows/Godot 4.7.2 muss weiterhin vor Ort getestet werden.

## Dokumentationsregel

Jeder umgesetzte Schritt ergänzt diese Datei um Verhalten, relevante technische Entscheidungen, tatsächliche Prüfung und offene Punkte. Geplante Funktionen werden nicht als abgeschlossen dokumentiert.
