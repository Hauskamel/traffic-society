# Traffic Society

[Git-Branches als visuelle Buslinie](docs/BRANCHES.md) · Abzweigungen, Merges und aktueller Branch-Status.

Ein kompakter 3D-Prototyp für ein Polizeikontrollspiel: Verkehr aus der Vogelperspektive beobachten und Kontrollen später in der Ego-Perspektive durchführen.

## Technik

- Godot 4 mit GDScript; Standardausgabe, kein .NET erforderlich.
- Renderer: GL Compatibility.
- Einfache Low-Poly-Geometrie aus Godot-Meshes; Blender und glTF/GLB sind für spätere individuelle Modelle vorgesehen.
- Entwicklungsplattform des bisherigen Prototyps: Windows, Godot 4.7.2 laut Editor-Screenshot.
- Das Projekt deklariert Godot 4.7; für die Weiterentwicklung dieselbe Version verwenden.
- Lokales Arbeitsverzeichnis: `E:\godot-projects`.

## Projektstatus

`develop` enthält die übernommenen Grundlagen und die interaktiven Werkzeugkoffer. Der aktive Branch **feature/extendedVehicleSearch** erweitert darauf die direkte Auswahl einzelner Ladungsgegenstände: kein pauschales Durchsuchen der Ladefläche mehr. `feature/vehicleDamage` bleibt ein separater Entwicklungszweig und ist hier nicht enthalten. `main` bleibt beim Ausgangsstand.

Verkehr, Fahreraktionen, Inventare, Dokumentenansicht, Waffen und Streifenabholung sind weiterhin verfügbar. Die aktuelle Bedienung der Fahrzeugdurchsuchung steht im Abschnitt „Direkte Fahrzeugdurchsuchung“ am Ende; ältere Abschnitte dokumentieren die vorherigen Ausbaustufen.

Die Dokumentenansicht ist verfügbar; ein Vergleichsmodus und Befragungsdialoge folgen später. Der Verkehr nutzt zunächst nur eine Fahrtrichtung und einen gleichzeitig reservierbaren Kontrollstellplatz.

Der Ausgangsstand wurde beim Import mit Godot 4.6.3 im Headless-Modus geprüft. Für Schritt 2 gibt es einen wiederholbaren Ablauf-Test; Prüfungen und Einschränkungen stehen in der Entwicklungsdokumentation. Der Verkehr bis Schritt 2a wurde vom Nutzer unter Windows bestätigt. Der neue Fahrer-/Menüablauf benötigt noch einen Windows-Test unter Godot 4.7.2.

## Spiel starten

`project.godot` im Godot-Projektmanager importieren, öffnen und F5 drücken. Die Umgebung wird beim Start vom Skript aufgebaut; eine leere 3D-Ansicht im Editor ist daher zunächst normal.

| Eingabe | Funktion |
| --- | --- |
| Tab | Vogelperspektive / Ego-Ansicht |
| WASD oder Pfeiltasten | Bewegen |
| Maus | In der Ego-Ansicht umsehen; pausiert während der Menüauswahl |
| Strg | Schneller gehen (bei geholsterter Waffe) |
| 1 / 2 oder Mausrad | Glock 19 / Taser in der Waffenleiste auswählen |
| Shift halten | Zur ausgewählten Waffe greifen |
| Rechte Maustaste halten | Nach dem Griff ziehen und zielen |
| Mausrad | Übersicht zoomen oder im offenen Interaktionsmenü die Aktion wählen |
| Escape | Menü / Inventar schließen oder die kurze Durchsuchung abbrechen; sonst Maus freigeben |
| Linksklick | In der Ego-Ansicht Maus wieder einfangen |
| Linksklick beim Zielen | Glock-Einzelschuss |
| R | Glock-Magazin wechseln; ersetzt den bisherigen Spieler-Reset |
| Leertaste | Am offenen Heck von Transporter/Pickup hochklettern; auf der Ladefläche heruntersteigen |
| T | Funkgerät öffnen / schließen; Streife für festgenommene Person anfordern |
| I | Eigenes Inventar in der Ego-Ansicht öffnen; Esc schließt |
| Linksklick auf Auto | In der Übersicht auswählen; hält das Fahrzeug noch nicht an |
| Zur Kontrolle anhalten | Ausgewähltes Fahrzeug ausdrücklich in die freie Bucht holen |
| E | Am Fenster / stehenden Fahrer Menü öffnen und ausgewählte Aktion bestätigen |

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
5. Auf das Fenster schauen und E drücken. Mit dem Mausrad **Aussteigen lassen** oder **Weiterfahren lassen** auswählen und mit E bestätigen. Esc schließt das Menü. Blick und Bewegung pausieren während der Auswahl.
6. Der bestätigte Aus-/Einstiegsauftrag läuft vollständig durch, auch wenn du direkt vor der Tür oder im Weg stehst. Zurücktreten und erneutes Anfordern sind nicht nötig. Während der Animation darf die Tür Hindernisse durchdringen.
7. Der Fahrer öffnet die Tür, steigt mit einer einfachen Animation aus und bleibt neben dem Auto stehen. Ansehen und E drücken: **Einsteigen lassen** oder **Gespräch beenden**. Letzteres schließt nur das Menü; der Fahrer wartet weiter.
8. Nach dem Wiedereinsteigen und Schließen der Tür erneut am Fenster das Menü öffnen und **Weiterfahren lassen** wählen. Das Fahrzeug fädelt wieder ein. Alternativ kann es bereits vor dem Aussteigen freigegeben werden.
9. Sobald auch das Heck den markierten Kontrollstellplatz vollständig verlassen hat, kannst du das nächste Auto anhalten. Das erste darf dabei noch in der Bucht oder an der Ausfahrt unterwegs sein. Kein manueller Neustart mit N ist nötig.

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

Er prüft die Fahrzeugauswahl per Physikstrahl, Kamerawechsel und die Freigabe über das Menü samt Blick- und Seitenprüfung. Vorschau-Screenshots werden im Godot-Benutzerdatenordner (`user://`) gespeichert. Zusätzliche Tests für Schritt 3:

```sh
godot --headless --path . --script res://tests/driver_test.gd
godot --path . --script res://tests/driver_menu_test.gd
```

Der erste prüft bei allen vier Modellen Aus-/Einsteigen, Türbewegung, belegte Wege ohne Abbruch oder Pause, Fahrerkollision und Abfahrtsbedingungen. Der zweite benötigt ein Display und prüft den vollständigen Menüablauf einschließlich Mausrad in beide Richtungen, Esc, pausiertem Mausblick und unverändertem Übersichtszoom.

Tests unter Linux mit Godot 4.6.3; die neue Funktion ist unter Windows/4.7.2 noch zu prüfen.

Test für die frühzeitige Stellplatzfreigabe:

```sh
godot --headless --path . --script res://tests/parking_reservation_test.gd
```

Prüft alle vier Fahrzeuglängen: keine Freigabe bei überstehendem Heck, sofortige nächste Kontrolle nach Räumen des Stellplatzes und unabhängiges Entfernen des vorherigen Autos.

## Geschwindigkeiten und Maßstab

1 Godot-Einheit entspricht 1 Meter. Bewegungen verwenden Meter pro Sekunde; die zentralen Werte in `scripts/speed_settings.gd` sind in km/h angegeben und werden durch 3,6 geteilt.

| Bewegung | km/h | m/s |
| --- | --- | --- |
| Straßenverkehr | 21,6 | 6,0 |
| Einfahren in die Bucht | 14,4 | 4,0 |
| Ausfahren aus der Bucht | 9,0 | 2,5 |
| Spieler ohne Sprint | 12,6 | 3,5 |
| Spieler mit Sprint | 21,6 | 6,0 |

Der Straßenverkehr verwendet `BASE_TRAFFIC_SPEED_KMH = 10.8` mal `TRAFFIC_SPEED_FACTOR = 2.0`. Der Faktor verändert nur die Reisegeschwindigkeit der Autos. Parktempo und Spielerbewegung haben eigene Werte. Die angegebenen Fahrzeugwerte sind Ziel-/Höchstgeschwindigkeiten; Bremsen, Abstände und Einfädeln können das Tempo reduzieren. Die Spielerwerte wurden bei dieser Anpassung nicht verändert; die normale Bewegung ist damit eher Laufen als gemütliches Gehen.

## Türen und Ladebereiche – an allen vier Fahrzeugmodellen

Am kontrollierten, geparkten Fahrzeug in die Ego-Ansicht wechseln. Mit dem Fadenkreuz auf **Fahrertür, Beifahrertür oder den hinteren Ladebereich** schauen. Der getroffene Bereich wird gelb eingefärbt, dazu erscheint **[E] … öffnen/schließen**. E bewegt das jeweilige Teil mit einer kurzen Scharnieranimation. Zum Schließen erneut das geöffnete Teil ansehen und E drücken.

- Türblech ansehen: Tür bedienen. Fahrerfenster / Fahrer ansehen: weiterhin das Mausrad-Menü öffnen.
- Maximal circa 2,8 Meter Reichweite; Wände oder andere Hindernisse verdecken die Interaktion. Die Türen werden von ihrer jeweiligen Fahrzeugseite bedient, der Kofferraum vom Heck.
- Während der Aus-/Einstiegsanimation übernimmt der Fahrer die Fahrertür. Manuelle Aktionen sind währenddessen gesperrt; der bereits geöffnete Türflügel wird ohne Zuschlagen übernommen.
- Vor dem Weiterfahren alle geöffneten Bereiche schließen. Sonst bleibt der Wagen stehen und zeigt einen Hinweis.
- Alle Modelle haben manuell bedienbare Fahrer- und Beifahrertüren.
- Limousine: Kofferraumdeckel. Kleinwagen: obere Heckklappe. Weißer Transporter: zwei einzeln bedienbare hintere Ladetüren. Pickup: nach unten klappbare Ladeflächenklappe.
- Die Ladebereiche enthalten feste Gegenstände und lassen sich durchsuchen; siehe Fahrzeugdurchsuchung unten.

Grafischer Test:

```sh
godot --path . --script res://tests/vehicle_parts_test.gd
```

Prüft Auswahl/Markierung mit dem Fadenkreuz, E-Hinweise, beide Türen und Kofferraum, Öffnen/Schließen, Reichweite, Verdeckung durch eine Wand, das Fahrer-Menü, die Übergabe an die Fahreranimation und die Abfahrtsbedingungen.

Grafischer Test für alle Modelle:

```sh
godot --path . --script res://tests/all_vehicle_parts_test.gd
```

Prüft jedes bedienbare Teil an allen vier Modellen: Fadenkreuz-Markierung, benannter E-Hinweis, Öffnen, erneutes Anvisieren zum Schließen und die gesperrte Abfahrt bei offenen Teilen. Für die Ladetüren des Transporters jeweils den linken oder rechten Flügel ansehen.

## Person durchsuchen und Inventare

1. Fahrzeug anhalten, Fahrer aussteigen lassen und den wartenden Fahrer ansehen.
2. E öffnet das Mausrad-Menü. **Person durchsuchen** wählen und mit E bestätigen.
3. Der Fahrer nimmt eine kurze Durchsuchungshaltung ein. Nach circa 3,2 Sekunden öffnet sich die Übersicht mit Mauszeiger. Es gibt keine einzeln anzuklickenden Körperbereiche.
4. Links stehen die gefundenen NPC-Gegenstände, in der Mitte die Details des angeklickten Items, rechts das Spielerinventar. Ein Klick betrachtet nur; **Übernehmen** und **Zurückgeben** verschieben den ausgewählten Gegenstand.
5. Esc oder die untere Schaltfläche beendet die Durchsuchung. Der Fahrer wartet wieder normal und kann zum Einsteigen aufgefordert werden.

Die Welt und der Verkehr laufen weiter. Blick und Bewegung des Spielers sind während der Animation und Ansicht gesperrt; Esc kann auch die kurze Animation abbrechen. Mit I lässt sich außerhalb einer Durchsuchung das eigene Inventar ohne NPC-Inhalt ansehen.

Alle vier Fahrer haben feste Schlüssel, eine Geldbörse und eine individuell beschriftete Quittung. Die Gegenstände besitzen eigene Symbole. Der Spieler startet mit einer Taschenlampe als Inventargegenstand (vorerst ohne Benutzungsfunktion) einem Funkgerät (T), einer Glock 19, einem Taser und zwei Ersatzmagazinen. NPCs haben acht, der Spieler zwölf Plätze. Eine volle Zielseite verhindert die Übertragung ohne Verlust. Zurückgeben ist nur an den ursprünglichen Besitzer möglich.

Inventare bleiben innerhalb der laufenden Spielsitzung bestehen – auch bei einer erneuten Durchfahrt derselben Figur. Weggenommene Items erscheinen dabei nicht erneut. Ein Neustart setzt die Inventare zurück. Es gibt noch kein Speichern, Gewicht, Drag-and-drop oder verschachtelte Taschen. Fahrzeug-Ladebereiche haben eigene, getrennte Inventare; siehe unten.

Tests:

```sh
godot --headless --path . --script res://tests/inventory_test.gd
godot --path . --script res://tests/search_interaction_test.gd
```

Der grafische Test prüft den gesamten Menü-/Suchablauf, erst danach sichtbare Items, Anklicken ohne Wegnehmen, Übernehmen und Zurückgeben, gesperrte Bewegung und Mausblick bei weiterlaufendem Verkehr sowie Esc, Abbruch und das eigene Inventar.

## Fahrzeugdurchsuchung

1. Fahrzeug zur Kontrolle anhalten. Der Fahrer darf sitzen bleiben.
2. Zum Heck gehen und Kofferraum/Heckklappe/Ladeflächenklappe öffnen. Beim Transporter genügt eine geöffnete Ladetür.
3. Mit dem Fadenkreuz **in den Innenraum** schauen. Der Bodenbereich wird gelb markiert und zeigt **E – Laderaum durchsuchen**. Ein Blick auf die Klappe bedient weiterhin die Klappe.
4. E startet eine kurze Suchbewegung (circa 3 Sekunden). Danach öffnet sich die bekannte Übersicht mit dem Fahrzeuginventar links und Spielerinventar rechts.
5. Items ansehen, **Entnehmen** oder **Zurücklegen** wählen. Esc schließt die Übersicht oder bricht die kurze Suche ab.

Personen- und Fahrzeuginventare sind getrennt. Zurücklegen funktioniert nur in das ursprüngliche Fahrzeug; ein Gegenstand aus dem Auto kann nicht in die Taschen des Fahrers zurückgegeben werden. Die Welt läuft weiter, während Blick und Bewegung gesperrt sind. Sichtbare Platzhaltergegenstände verschwinden beim Entnehmen und erscheinen beim Zurücklegen wieder. Leere Fahrzeuge bleiben innerhalb derselben Sitzung leer, auch bei einer erneuten Durchfahrt.

| Fahrzeug | Fester Inhalt |
| --- | --- |
| Bobby | Werkzeugkoffer, Ersatzteil, Werkstattbeleg |
| Nora | Einkaufstasche, Geschenk, Kassenbon |
| Erik | Paket, Arbeitsmaterial, Lieferschein |
| Mara | Seil, Werkzeugkoffer, Handschuhe |

Ein gemeinsames Ladeinventar pro Fahrzeug mit neun Plätzen, keine einzeln durchsuchbaren Behälter. Noch keine versteckten Fächer, Handschuhfächer, Gewichtsberechnung oder Speicherung über Spielneustarts.

Tests:

```sh
godot --headless --path . --script res://tests/cargo_test.gd
godot --path . --script res://tests/cargo_interaction_test.gd
```

Der grafische Test durchläuft alle vier Modelle, einschließlich einer einzelnen geöffneten Transportertür, Fadenkreuz-Auswahl, verzögerter Ansicht, sitzendem Fahrer, Entnehmen/Zurücklegen, leerem Laderaum und Abbruch. Der Datentest prüft getrennte Inventare, korrektes Zurücklegen und erhaltene leere Fahrzeug-Inventare bei erneuter Durchfahrt.

## 3D-Gegenstände und längere Animationen

Ein Gegenstandsklick zeigt im mittleren Inventarbereich ein einfaches echtes 3D-Modell statt des bisherigen großen Symbols. Die Slot-Symbole bleiben erhalten.

- Linke Maustaste **in der 3D-Ansicht halten und ziehen**: frei um zwei Achsen drehen, auch auf die Rückseite.
- Mausrad über der Ansicht: näher heran-/herauszoomen.
- **Ansicht zurücksetzen** stellt Winkel und Zoom wieder her.
- Quittungen und Belege haben Text auf Vorder- und Rückseite. Die lesbare Beschreibung bleibt zusätzlich unter der Vorschau erhalten.
- Die bisherige Beschreibung „Ursprünglicher Besitzer“ wird nicht mehr angezeigt. Die interne Zuordnung bleibt für korrektes Zurückgeben erhalten.

Neun einfache Modellkategorien decken die bisherigen NPC-, Spieler- und Fahrzeuggegenstände ab. Die Vorschau hat eine eigene 3D-Welt mit Kamera und Licht; Drehen verändert weder die Spielkamera noch das Inventar.

Zeiten stehen zentral in `scripts/interaction_timings.gd`: Aus-/Einsteigen 3,6 s, Person durchsuchen 3,2 s, Fahrzeug durchsuchen 3 s. Auch die manuellen Scharnierbewegungen sind etwas langsamer. Nur während Personen- und Fahrzeugdurchsuchungen ersetzt ein kleiner Fortschrittsbalken das Fadenkreuz. Aus-/Einsteigen und Klettern zeigen keinen Ladebalken. Nach Abschluss oder Abbruch erscheint das normale Fadenkreuz wieder.

Einfahren ist auf 14,4 km/h erhöht, Ausfahren bleibt bei 9 km/h. Straßenverkehr und Spielerwerte sind unverändert.

Grafischer Test:

```sh
godot --path . --script res://tests/item_inspection_test.gd
```

Prüft alle 13 Modellkategorien, Ziehen, Zoom, Zurücksetzen, Papier-Vorder-/Rückseite, entfernte Besitzerzeile und unveränderte Inventarinhalte. Der bestehende grafische Suchtest prüft zusätzlich den Fortschrittsbalken.

## Auf Ladeflächen klettern

Bei einem angehaltenen **Pickup oder Transporter** die hintere Klappe beziehungsweise eine Ladetür öffnen. Direkt vor das offene Heck stellen und hineinschauen. Der Hinweis **Leertaste – Auf Ladefläche klettern** erscheint bei freiem Einstieg. Leertaste startet eine kurze räumliche Bewegung ohne Ladebalken.

Auf der Ladefläche mit WASD bewegen, den Innenraum mit E durchsuchen oder mit **Leertaste heruntersteigen**. Im niedrigen Transporter werden Kollisionskapsel und Augenhöhe automatisch abgesenkt; beim Heruntersteigen wird die normale Höhe wiederhergestellt. Bei nur einer geöffneten Transportertür wird die offene Seite genutzt.

Boden, Wände und Dach besitzen passende Kollisionen statt eines den ganzen Laderaum füllenden Blocks. Ein blockierter Zielpunkt verhindert den Einstieg. Solange der Spieler auf der Ladefläche steht, sind Abfahrt und Schließen der hinteren Öffnung gesperrt. Limousinen-Kofferräume und allgemeines Parkour-Klettern sind nicht Bestandteil dieser Funktion.

Grafischer Test:

```sh
godot --path . --script res://tests/climbing_test.gd
```

Prüft Pickup und Transporter, geschlossene/blockierte Einstiege, Hochklettern, Bewegung auf dem Boden, automatisch angepasste Höhe, Heruntersteigen, Suchinteraktion von innen und Ladebalken ausschließlich bei Durchsuchungen.

## Weiterfahren, Spielerfigur und Streifenabholung

Beim ausgestiegenen Fahrer stehen **Einsteigen lassen** (Auto bleibt stehen) und **Weiterfahren lassen** (Einsteigen und anschließende Abfahrt) getrennt zur Verfügung. Offene manuelle Klappen müssen vor der Freigabe geschlossen sein. Der Spieler besitzt jetzt eine sichtbare Polizistenfigur in der Vogelperspektive.

1. Fahrer aussteigen lassen und im Personenmenü **Festnehmen** wählen. Solange keine Abholung angefordert ist, lässt sich die Festnahme wieder aufheben.
2. Mit **T** das Funkgerät mit Display öffnen und **Streife zur Abholung anfordern** anklicken. Bewegung und Blick sind während der Funkbedienung gesperrt, die Welt läuft weiter.
3. Nach frühestens **20 Sekunden** spawnt der Streifenwagen; die zusätzliche Anfahrt benötigt Zeit. Bei belegtem Spawnpunkt wartet er kurz auf freien Verkehr. Die Anforderung lässt sich bis zum Spawn abbrechen.
4. Der Wagen hält am zweiten Stellplatz vor dem kontrollierten Fahrzeug. Ein Polizist steigt aus, begleitet die Person zum Streifenwagen, bringt sie hinein und fährt mit ihr ab.

Die Person kehrt während dieser Sitzung nicht in den Verkehr zurück. Das zurückgelassene Fahrzeug wird nach dem Transport vorläufig entfernt und der Kontrollplatz freigegeben. Abschleppen, rechtliche Festnahmeprüfung und dauerhafte Speicherung sind noch nicht umgesetzt. Die Abholung nutzt feste Wege für diesen Kontrollplatz; sie ist kein allgemeines Navigationssystem. Das Funkgerät besitzt auch eine drehbare Inventarvorschau.

Neue Ablaufprüfungen: `tests/departure_test.gd`, `tests/patrol_test.gd` (alle vier Fahrer) und `tests/police_interaction_test.gd` (grafische Bedienung und Abholung). Geprüft unter Linux/Godot 4.6.3; Windows/Godot 4.7.2 benötigt einen Praxistest.

## Dokumente ansehen

Am Fahrerfenster oder beim ausgestiegenen Fahrer mit E das Menü öffnen und **Dokumente anfordern** wählen. Führerschein und Fahrzeugpapier erscheinen gemeinsam. Beide lassen sich an ihrer Titelleiste ziehen; **Dokumente anordnen** stellt die Ansicht wieder her. **Esc** oder **Dokumente zurückgeben** schließt sie. Die Welt läuft währenddessen weiter, Bewegung und Blick sind gesperrt.

Alle vier Fahrer besitzen feste Namen, Geburtsdaten, Führerscheinnummern und Gültigkeitsangaben. Fahrzeugpapiere zeigen Kennzeichen, Halter, Typ, Farbe und Erstzulassung. Eriks Transporter gehört seiner Firma; ein abweichender Halter ist kein automatisch bewerteter Verstoß. Das Lichtbild ist vorläufig passend zum gemeinsamen Fahrer-Platzhalter gestaltet. Noch kein Vergleichsmodus, keine absichtlichen Dokumentenfehler und keine Dokumentendialoge.

Grafischer Test: `tests/documents_test.gd` mit Godot 4.6.3 unter Linux; prüft alle vier Paare, Menüzugang innen/außen, Zuordnung, Kartenpositionen und Rückkehr zur Steuerung.

### Dokumentenprüfung in Zeitlupe

Beim Anfordern wechselt die Kamera sanft in eine nähere Vogelperspektive über dem kontrollierten Fahrzeug. Die Dokumente bleiben farbig im Vordergrund; dahinter läuft die sichtbare Spielwelt mit **18 % Geschwindigkeit**, entsättigt und leicht abgedunkelt. Das normale HUD ist ausgeblendet. Karten und Maus bleiben direkt bedienbar.

Esc beziehungsweise „Dokumente zurückgeben“ stellt die vorherige Spielgeschwindigkeit wieder her und führt die Kamera zur Ego-Ansicht zurück. Während des kurzen Rückwegs bleibt die Steuerung gesperrt. Auch Streifen-Wartezeit und Animationen laufen während der Dokumentenprüfung langsamer. Der Prüfmodus verändert weder Position noch Blickrichtung des Spielers und lässt die normale Übersichtskamera unverändert.

Die dauerhafte Bedienungs-/Statusanzeige links oben ist entfernt. Situative Interaktionshinweise und Rückmeldungen stehen unten mittig; bei Fahrzeugauswahl erscheint dort auch der Anhalteknopf.

## Waffenleiste, Glock 19 und Taser

Der Spieler trägt beide Waffen als echte Gegenstände im Inventar (I). In der Ego-Ansicht stehen zwei Schnellplätze unten bereit: **1** wählt die Glock 19, **2** den Taser; außerhalb von Menüs wechselt auch das Mausrad. Der gewählte Platz ist gelb markiert. In der Vogelperspektive sind beide Waffen am Gürtel in getrennten Holstern sichtbar.

**Shift halten** führt die Hand zum Griff. Danach **Rechtsklick halten**, um die ausgewählte Waffe zu ziehen und zu zielen. Eine schnelle Kombination wird nach der kurzen Griffbewegung ausgeführt. Nach dem Ziehen darf Shift losgelassen werden; gehalten wird die Zielhaltung mit Rechtsklick. Rechtsklick loslassen bringt die Waffe wieder ins Holster; bleibt Shift gedrückt, bleibt die Hand am Griff. Waffenwechsel beendet die bisherige Haltung. **Sprinten liegt jetzt auf Strg**, damit Shift eindeutig zum Griff gehört. Während Griff/Zielen wird nicht gesprintet.

Inventar, Funk, Dokumentenprüfung, Klettern und Perspektivwechsel beenden die Waffenhaltung. Beim Griff/Zielen sind E-Interaktionen gesperrt. Das Mausrad bedient in Menüs weiterhin die Menüauswahl und in der Vogelperspektive den Zoom. Die Glock unterstützt Einzelschüsse und Magazinwechsel (siehe unten). Der Taser bleibt ohne Wirkung; die Glock kann NPCs zur Aufgabe zwingen (siehe unten). Die Glock 19 ist ein eigener vereinfachter Low-Poly-Nachbau, kein importiertes Detailmodell. Beide Waffen lassen sich in der Inventaransicht in 3D drehen.

Geprüft unter Linux/Godot 4.6.3: `tests/equipment_test.gd`, Inventartransfers und 3D-Gegenstandsvorschau. Windows/Godot 4.7.2 bitte praktisch testen.

## Schießen und Magazinwechsel testen

Die Glock 19 startet mit **15 Patronen im eingesetzten Magazin**. Zusätzlich liegen **zwei volle 15er-Magazine** im Spielerinventar: insgesamt 45 Patronen. Die Waffenleiste zeigt den aktuellen Inhalt und die Anzahl der Ersatzmagazine; deren Füllstände stehen im Inventar.

1. Glock mit **1** wählen, **Shift halten**, dann **Rechtsklick halten** zum Ziehen/Zielen.
2. **Linksklick** gibt einen Einzelschuss ab. Gedrückthalten erzeugt kein Dauerfeuer. Knall, kurzer Mündungsblitz, Rückstoß, Schusslinie und kurz sichtbarer Auftreffeffekt dienen als Testfeedback.
3. Mit gezogener Glock **R** drücken und für den etwa **1,8 Sekunden** langen Magazinwechsel Rechtsklick weiter halten. Währenddessen kann nicht geschossen werden.

Beim Nachladen wird das Ersatzmagazin mit der meisten Munition gewählt. Es muss mehr Patronen enthalten als das eingesetzte Magazin. Das bisherige Magazin kommt mit seiner Restmunition ins Inventar; auch leere Magazine bleiben erhalten. Ein volles Magazin oder fehlende geeignete Ersatzmagazine verhindern den Wechsel. Holstern, Waffenwechsel oder ein Menü brechen das Nachladen ab, ohne Munition zu verlieren oder hinzuzufügen.

**R setzt den Spieler nicht mehr zurück.** Kein Schaden und keine Taserwirkung. Das Erzwingen der Aufgabe durch Zielen ist separat beschrieben. Es gibt noch keine lose Munition, Magazinbefüllung oder separate Patrone im Patronenlager. Welt-Treffer werden nur für temporäre Effekte ermittelt. Ton und Modelle sind einfache eigene Platzhalter.

Geprüft mit Godot 4.6.3 unter Linux: `tests/shooting_test.gd` (Schüsse, leeres Magazin, Nachladezeit, Teilladungen, Abbruch und Munitionserhaltung), Inventar-/Bedienungstests und 13 Kategorien in der 3D-Vorschau. Windows/Godot 4.7.2 bitte testen.

## NPCs mit der Glock zur Aufgabe zwingen

Mit vollständig gezogener Glock kurz auf Kopf oder Oberkörper eines noch nicht verhafteten Fahrers zielen. Nach etwa **0,25 Sekunden** bei freier Sicht und höchstens **25 Metern** Abstand hebt er die Hände. Ein Schuss ist nicht erforderlich; auch eine leere Glock wird als Bedrohung erkannt. Der Taser löst diesen Ablauf noch nicht aus.

Ein sitzender Fahrer hebt bereits im Führerhaus die Hände. Falls das Auto fährt, bremst es bis zum Stillstand und der Fahrer steigt anschließend mit erhobenen Händen aus. Das Auto hält dabei an seiner aktuellen Fahrstrecke; es fährt durch diese Aktion nicht automatisch in die Kontrollbucht. Nachfolgender Verkehr wartet entsprechend.

Die Aufgabe bleibt beim Senken der Waffe bestehen. Aus der Nähe (etwa zwei Meter), mit Blick auf die Person, erscheint **[E] Handschellen anlegen**. E führt dies direkt aus und holstert die Waffe. Anschließend stehen Durchsuchung, Aufheben der Festnahme und Streifenanforderung wie bisher zur Verfügung – auch bei einer Person außerhalb der Kontrollbucht. Dafür am Verhafteten das Menü öffnen oder mit Blick auf ihn T für das Funkgerät drücken. Eine andere laufende Kontrolle wird nicht ersetzt.

Die Streife kann bei einer blockierten Fahrbahn seitlich anfahren; ihre Abholwege berücksichtigen den tatsächlichen Standort des Verhafteten. Es bleibt ein einfacher Ablauf für diesen Kontrollplatz, kein allgemeines Verkehrs- oder Navigationssystem. Die groben Fahrzeugkollisionen schließen die transparenten Kabinen ein; deshalb wird das anvisierte Fahrzeug bei der Sichtprüfung ausgenommen. Andere Fahrzeuge und feste Hindernisse blockieren die Erkennung.

Geprüft: `tests/compliance_test.gd` grafisch für alle vier Modelle, Aufgabe außerhalb des Autos, Glock/Taser-Abgrenzung, blockierte Sicht, Bremsen vor Aussteigen, Hände oben, direkte Handschellen und Folgeaktionen. `tests/patrol_test.gd` prüft zusätzlich die Straßenabholung bei weiterhin belegter Kontrollbucht. Linux/Godot 4.6.3; Windows/Godot 4.7.2 bitte testen.

## Interaktive Werkzeugkoffer · erste Testversion

Auf **feature/vehicleSearches** lässt sich die Ladung genauer untersuchen:

1. Fahrzeug anhalten und den Ladebereich wie bisher öffnen/durchsuchen.
2. **Werkzeugkoffer** auswählen → **Genauer untersuchen**.
3. In der großen 3D-Ansicht den **goldenen Verschluss anklicken**, danach den **Deckel anklicken**.
4. Sichtbare Gegenstände im Koffer anklicken. Rechts erscheint ihre drehbare Nahansicht; **Entnehmen** legt den gewählten Gegenstand ins Spielerinventar.

Im großen Bild: **Linksklick bedient Teile**, **rechte Maustaste halten und ziehen dreht den Koffer**, **Mausrad zoomt**. Die Nahansicht rechts wird wie die bisherige Vorschau mit links gedreht. Esc führt zuerst zum Inventar zurück; ein weiteres Esc beendet die Durchsuchung. Die Welt läuft weiterhin normal, Blick und Bewegung bleiben gesperrt.

**Bobby Mayer:** Hammer und Messer mit sichtbaren dunkelroten Spuren. **Mara Wolf:** nur ein Hammer. Keine automatische Blutbestätigung und kein Fundtext vor dem Öffnen. Noras Ladung und Eriks Arbeitsmaterial bleiben zunächst bei der bisherigen Untersuchung.

Verschluss, Deckel und Inhalt bleiben innerhalb der Sitzung erhalten – auch beim Schließen der Ansicht, beim Mitnehmen des ganzen Koffers oder bei erneuter Durchfahrt des Fahrzeugs. Entnommene Gegenstände verschwinden aus dem Koffer. In der großen Ansicht lassen sich eigene Entnahmen über **Zurücklegen** in genau diesen Koffer zurücklegen. Volles Inventar verhindert die Entnahme ohne Verlust. Die Zustände werden noch nicht über Spielneustarts gespeichert.

Es ist zunächst ein einfacher Behältertyp, noch kein allgemeines System verschachtelter Inventare. Kein Farbeimer, keine Drogenanalyse oder neue Dialoge. Die Kofferöffnung wird in der Untersuchungsansicht dargestellt; der kleine Beladungsplatzhalter im Fahrzeug bleibt vereinfacht.

Prüfung unter Linux/Godot 4.6.3: `tests/toolbox_test.gd` für echtes 3D-Anklicken von Verschluss/Deckel/Inhalt, Funddarstellung, Entnahme/Rückgabe, volle Inventare, Mitnehmen und Wiederkehr. Die gemeinsame 3D-Vorschau umfasst jetzt 15 Modellkategorien. Windows/Godot 4.7.2 bitte testen.

## Direkte Fahrzeugdurchsuchung · feature/extendedVehicleSearch

**Die Ladefläche selbst ist nicht mehr durchsuchbar.** Öffne Kofferraum oder Ladetüren, suche einen konkreten Gegenstand in der Welt und richte das Fadenkreuz darauf. Die Hervorhebung und der Hinweis nennen genau diesen Gegenstand. **E** öffnet ihn ohne Suchwartezeit; weitere, noch nicht ausgewählte Fahrzeuggegenstände werden nicht als Gesamtliste verraten.

| Fahrzeug | Feste Beladung |
| --- | --- |
| Bobby / Limousine | Werkzeugkoffer, Kühlbox, Werkstattbeleg |
| Nora / Kleinwagen | Kühlbox, Geschenk, Kassenbon |
| Erik / Transporter | Lagerregal mit drei äußerlich gleichen Farbeimern; Wasserfass |
| Mara / Pickup | Werkzeugkoffer, gesicherte Leiter, Handschuhe |

- **Werkzeugkoffer:** Verschluss lösen, Deckel öffnen. Bobbys Koffer enthält Hammer und Messer mit roten Spuren; Maras nur einen Hammer.
- **Farbeimer:** Deckel abnehmen, dann den weißen Einsatz mit dem sichtbaren Rand herausnehmen. Einer der drei Eimer enthält darunter ein versiegeltes Päckchen; außen sehen alle gleich aus.
- **Kühlbox:** Verschluss und Deckel öffnen, Innenkorb mit den einfachen Lebensmittel-Platzhaltern herausnehmen. Bobbys Box enthält darunter ein Päckchen, Noras nicht.
- **Wasserfass:** Deckel abnehmen. Ein wasserdicht wirkendes Päckchen ist unter einer vereinfachten transparenten Wasserfläche sichtbar.

In der großen Ansicht bedient **Linksklick** ein Teil oder wählt sichtbaren Inhalt; **Rechtsziehen** dreht den Behälter und das **Mausrad** zoomt. Die Nahansicht rechts lässt sich mit links drehen. Verdeckter Inhalt kann nicht durch Deckel oder Einsatz ausgewählt werden. Es gibt keine automatische Bestätigung, dass das helle Material Drogen oder die roten Spuren Blut sind.

**Entnehmen** verschiebt einen Fund ins Spielerinventar. Zurücklegen ist nur in den ursprünglichen geöffneten und freigelegten Behälter möglich. Esc führt zuerst in die Inventaransicht des ausgewählten Gegenstands zurück; dort kann auch der ganze Behälter mitgenommen werden. Ein weiteres Esc beendet die Kontrolle des Gegenstands. Der Inhalt anderer Behälter bleibt verborgen. Die Leiter und das Regal sind vorerst feste Ladung, keine untersuchbaren Behälter.

Die Welt läuft weiter; Blick und Bewegung sind während der Ansicht gesperrt. Währenddessen fährt das kontrollierte Auto nicht ab. Öffnungszustand, Einsätze und Entnahmen bleiben beim Schließen, Mitnehmen und bei erneuter Fahrzeugdurchfahrt in derselben Sitzung erhalten. Zum Zurücklegen eines mitgenommenen ganzen Behälters kannst du am geöffneten Fahrzeug **I** öffnen, den eigenen Gegenstand auswählen und **Zurück ins Fahrzeug legen** drücken. Dabei wird keine Liste unbekannter Ladung gezeigt. Das funktioniert auch bei einem vollständig geleerten Fahrzeug. Keine Speicherung über Neustarts, Analyse, Missionen oder echte Flüssigkeitssimulation.

Für tiefer liegende Ladung kannst du auf Pickup und Transporter klettern. Beim Transporter empfiehlt es sich, beide Hecktüren zu öffnen; der Einstieg nutzt die freie rechte Seite neben dem Regal. Gegenstände, Regal und andere Weltobjekte können die Sicht versperren – die Perspektive muss deshalb gegebenenfalls geändert werden.

Prüfung unter Godot 4.6.3/Linux: `tests/extended_search_test.gd` (reale Weltziele, geschlossener Zugang, Wandblockade, einzelne Inventaransicht, Behälterschritte, sichtbares und anklickbares Päckchen, Rückgabe und Zustände), `tests/climbing_test.gd`, Werkzeugkoffer-/Inventar-/Verkehrstests sowie die gemeinsame Vorschau mit 18 Modellkategorien. Windows/Godot 4.7.2 bitte praktisch testen.
