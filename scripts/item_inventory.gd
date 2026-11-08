extends RefCounted
## Session-only inventory. Transfers move the same item, never copy it.
var capacity := 12
var items: Array[Dictionary] = []

func transfer_to(id: String, destination: RefCounted) -> bool:
	if destination == self or destination.items.size() >= destination.capacity:
		return false
	for existing in destination.items:
		if existing.id == id:
			return false
	for i in range(items.size()):
		if items[i].id == id:
			destination.items.append(items[i])
			items.remove_at(i)
			return true
	return false

static func for_driver(driver_name: String) -> RefCounted:
	var inventory := new()
	inventory.capacity = 8
	var notes := {
		"Bobby Mayer": "Tankstelle Nord · 47,20 Euro\nNotiz auf der Rueckseite: Freitag, 18 Uhr – alte Werkstatt.",
		"Nora Beck": "Buchhandlung am Markt · 12,90 Euro\nEin Geburtstagsgeschenk. Auf der Rueckseite steht: Fuer Leon.",
		"Erik Sommer": "Raststaette West · 8,50 Euro\nAuftragsnummer 308, Anlieferung am Suedtor.",
		"Mara Wolf": "Baumarkt · 23,40 Euro\nSchrauben, Seil und zwei Arbeitshandschuhe."
	}
	inventory.items.assign([
		{"id": driver_name + ":keys", "name": "Schluesselbund", "icon": "keys", "owner": driver_name, "description": "Fahrzeug- und Hausschluessel an einem Ring.\nAm Anhaenger steht: " + driver_name + "."},
		{"id": driver_name + ":wallet", "name": "Geldboerse", "icon": "wallet", "owner": driver_name, "description": "Eine gebrauchte Geldboerse mit etwas Bargeld.\nAuf einer kleinen Karte steht: " + driver_name + "."},
		{"id": driver_name + ":receipt", "name": "Quittung", "icon": "receipt", "owner": driver_name, "description": notes.get(driver_name, "Eine beschriftete Quittung.")}
	])
	return inventory

static func for_player() -> RefCounted:
	var inventory := new()
	inventory.items.append({"id": "player:flashlight", "name": "Taschenlampe", "icon": "flashlight", "owner": "Spieler", "description": "Deine dienstliche Taschenlampe.\nNoch ohne eigene Benutzungsfunktion."})
	return inventory


static func for_vehicle(driver_name: String, plate: String) -> RefCounted:
	var inventory := new()
	inventory.capacity = 9
	var sets := {
		"Bobby Mayer": [["Werkzeugkoffer", "case", "Schraubendreher, Zange und ein kleiner Schraubenschluessel."], ["Ersatzteil", "parcel", "Ein verpackter Oelfilter. Beschriftung: Fuer die alte Limousine."], ["Werkstattbeleg", "receipt", "Werkstatt Nord – Oelwechsel.
Notiz: Ersatzteil beim naechsten Termin mitbringen."]],
		"Nora Beck": [["Einkaufstasche", "bag", "Brot, Obst und eine Packung Tee."], ["Geschenk", "parcel", "Ein sorgfaeltig verpacktes Geschenk.
Anhaenger: Fuer Leon."], ["Kassenbon", "receipt", "Supermarkt am Markt – Lebensmittel, 18,40 Euro."]],
		"Erik Sommer": [["Paket", "parcel", "Versandkarton.
Empfaenger: Lager Sued, Tor 3."], ["Arbeitsmaterial", "case", "Eine Kiste mit Kabeln und Befestigungsmaterial."], ["Lieferschein", "receipt", "Auftrag 308 – Lager Sued.
Enthaelt ein Paket und eine Materialkiste."]],
		"Mara Wolf": [["Seil", "rope", "Ein aufgewickeltes Arbeitsseil."], ["Werkzeugkoffer", "case", "Ein Koffer mit gebrauchten Handwerkzeugen."], ["Handschuhe", "gloves", "Ein Paar robuste Arbeitshandschuhe."]]
	}
	var contents: Array = sets.get(driver_name, sets["Bobby Mayer"])
	for i in range(contents.size()):
		inventory.items.append({"id": plate + ":cargo:" + str(i), "name": contents[i][0], "icon": contents[i][1], "description": contents[i][2], "owner": "Fahrzeug " + plate})
	return inventory
