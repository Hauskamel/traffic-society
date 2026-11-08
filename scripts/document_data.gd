extends RefCounted
## Authored prototype documents. No generated identities or discrepancy logic.
const PEOPLE := {
	"Bobby Mayer": {"birth": "14.03.1987", "number": "TS-F-10487", "issued": "18.06.2021", "expires": "18.06.2036", "holder": "Bobby Mayer", "first_registration": "09.05.2014"},
	"Nora Beck": {"birth": "22.08.1995", "number": "TS-F-21795", "issued": "07.09.2020", "expires": "07.09.2035", "holder": "Nora Beck", "first_registration": "12.02.2018"},
	"Erik Sommer": {"birth": "06.11.1979", "number": "TS-F-30879", "issued": "23.04.2019", "expires": "23.04.2034", "holder": "Sommer Logistik", "first_registration": "16.07.2016"},
	"Mara Wolf": {"birth": "30.01.1991", "number": "TS-F-41291", "issued": "11.12.2022", "expires": "11.12.2037", "holder": "Mara Wolf", "first_registration": "25.10.2015"},
}

static func for_car(car: Node) -> Dictionary:
	if not PEOPLE.has(car.driver_name):
		return {}
	var person: Dictionary = PEOPLE[car.driver_name]
	return {
		"license": {"Name": car.driver_name, "Geburtsdatum": person.birth, "Fuehrerscheinnummer": person.number, "Klassen": "B / C1" if car.model_kind == "van" else "B", "Ausgestellt am": person.issued, "Gueltig bis": person.expires},
		"registration": {"Kennzeichen": car.plate_number, "Fahrzeughalter": person.holder, "Fahrzeugtyp": car.model_name, "Farbe": {"sedan": "Blaugruen", "hatch": "Ocker", "van": "Cremeweiss", "pickup": "Rotbraun"}.get(car.model_kind, "Unbekannt"), "Erstzulassung": person.first_registration},
	}
