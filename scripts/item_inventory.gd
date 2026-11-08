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
	inventory.items.append({"id": "player:radio", "name": "Funkgeraet", "icon": "radio", "owner": "Spieler", "description": "Dienstliches Walkie-Talkie mit Display.\nT: Funkgeraet oeffnen und Abholung anfordern."})
	inventory.items.append({"id": "player:pistol", "name": "Glock 19", "icon": "pistol", "owner": "Spieler", "description": "Dienstpistole im rechten Holster.\n1: auswaehlen. Shift halten: Griff. Rechtsklick halten: ziehen und zielen."})
	inventory.items.append({"id": "player:taser", "name": "Taser", "icon": "taser", "owner": "Spieler", "description": "Dienstlicher Taser im linken Holster.\n2: auswaehlen. Shift halten: Griff. Rechtsklick halten: ziehen und zielen."})
	for item in inventory.items:
		if item.id == "player:pistol":
			item.loaded_magazine = magazine(0)
	for index in [1, 2]:
		inventory.items.append(magazine(index))
	return inventory

static func magazine(index: int) -> Dictionary:
	return {"id": "player:magazine:" + str(index), "name": "G19-Magazin (15/15)", "icon": "magazine", "owner": "Spieler", "rounds": 15, "description": "Ersatzmagazin fuer die Glock 19.\nEnthaelt 15 von 15 Patronen."}


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
		if contents[i][0] == "Werkzeugkoffer":
			var toolbox: Dictionary = inventory.items.back()
			toolbox.container_type = "toolbox"
			toolbox.unlocked = false
			toolbox.opened = false
			toolbox.description = "Ein Werkzeugkoffer mit einem Verschluss und aufklappbarem Deckel.\nMit 'Genauer untersuchen' laesst er sich oeffnen."
			var inside := new()
			inside.capacity = 3
			inside.items.append({"id": toolbox.id + ":hammer", "name": "Hammer", "icon": "hammer", "owner": toolbox.owner, "container_id": toolbox.id, "description": "Ein einfacher Hammer mit Holzgriff und Gebrauchsspuren."})
			if driver_name == "Bobby Mayer":
				inside.items.append({"id": toolbox.id + ":knife", "name": "Messer", "icon": "knife", "owner": toolbox.owner, "container_id": toolbox.id, "description": "Ein Messer mit dunkelroten Spuren auf der Klinge. Ob es Blut ist, ist noch nicht geklaert."})
			toolbox.contents = inside
	return inventory
