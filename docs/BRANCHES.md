# Git-Branches als Buslinie

Stand: **13. November 2026**. Die farbigen Linien zeigen die tatsächlichen Abzweigungen und Zusammenführungen der Spielfunktionen. GitHub stellt das Mermaid-Diagramm direkt als Grafik dar.

Die Übersicht ist ein **Schnappschuss vor der Ergänzung dieser Dokumentation**. Sie fasst Zwischenstände zusammen; die angegebenen Commit-IDs bezeichnen Spielstände. Die anschließenden reinen Dokumentationscommits auf den einzelnen Branches sind nicht eingezeichnet.

```mermaid
gitGraph LR:
    commit id: "efe140c" tag: "Grundprototyp"
    branch develop
    branch "feature/fundamentals"
    checkout "feature/fundamentals"
    commit id: "10f88f6" tag: "Verkehr und Kontrollen"
    checkout develop
    merge "feature/fundamentals" id: "8adbd8c"
    branch "feature/vehicleSearches"
    checkout "feature/vehicleSearches"
    commit id: "364e485" tag: "Werkzeugkoffer"
    checkout develop
    merge "feature/vehicleSearches" id: "29e406d"
    branch "feature/vehicleDamage"
    checkout "feature/vehicleDamage"
    commit id: "52049aa" tag: "Einschussmarkierungen"
    commit id: "8f34566" tag: "Scheiben und Reifen"
    checkout develop
    branch "feature/extendedVehicleSearch"
    checkout "feature/extendedVehicleSearch"
    commit id: "5384bec" tag: "Direkte Ladungsdurchsuchung"
    checkout develop
    merge "feature/extendedVehicleSearch" id: "d24e02a"
    checkout "feature/vehicleDamage"
    merge develop id: "d7db46c"
    checkout develop
    merge "feature/vehicleDamage" id: "cc49440"
    branch "feature/bodPhysics"
    checkout "feature/bodPhysics"
    commit id: "bd77a26" tag: "Koerperphysik-Labor"
    commit id: "8edd766" tag: "NPC-Treffer im Spiel"
    commit id: "0094051" tag: "Bewaffneter NPC-Test"
    commit id: "22dd1a0" tag: "Zeitlupen-Mausblick"
```

**So liest du die Buslinie:** Jede Linie ist ein Branch, Punkte sind ausgewählte Commits. Eine Abzweigung startet einen Feature-Branch; eine zurücklaufende Verbindung übernimmt Änderungen. Die Verbindung von `develop` zu `feature/vehicleDamage` zeigt die damalige Aktualisierung des Feature-Branches mit der erweiterten Fahrzeugdurchsuchung, bevor die Fahrzeugschäden nach `develop` übernommen wurden.

## Noch auf GitHub vorhandene Branches

| Branch | Rolle / Status | Letzter Spielstand vor der Doku-Ergänzung |
| --- | --- | --- |
| `main` | Stabiler Ausgangsstand; spätere Spielfunktionen noch nicht übernommen | `efe140c` – Straße und Parkbucht |
| `develop` | Integrationsbranch; Grundlagen, Durchsuchungen und Fahrzeugschäden zusammengeführt | `cc49440` – Fahrzeugschäden übernommen |
| `feature/bodPhysics` | Laufende Entwicklung; noch nicht in `develop` zusammengeführt | `22dd1a0` – Körperphysik, bewaffneter NPC-Test und Zeitlupe |
| `feature/vehicleDamage` | Bereits in `develop` zusammengeführt, Remote-Branch noch vorhanden | `d7db46c` – Fahrzeugschäden inklusive damaligem `develop` |
| `feature/extendedVehicleSearch` | Bereits in `develop` zusammengeführt, Remote-Branch noch vorhanden | `5384bec` – Gegenstände direkt im Fahrzeug untersuchen |

`feature/fundamentals` und `feature/vehicleSearches` sind auf GitHub bereits gelöscht. Ihre historischen Linien bleiben im Diagramm sichtbar. Die Dokumentation legt diese Branches nicht erneut an. `feature/bodPhysics` ist die tatsächliche Schreibweise des vorhandenen Branches.

## Zusammenführungen

- [PR #1](https://github.com/Hauskamel/traffic-society/pull/1): `feature/fundamentals` → `develop`, zusammengeführt.
- [PR #2](https://github.com/Hauskamel/traffic-society/pull/2): `feature/vehicleSearches` → `develop`, zusammengeführt.
- [PR #4](https://github.com/Hauskamel/traffic-society/pull/4): `feature/extendedVehicleSearch` → `develop`, zusammengeführt.
- [PR #3](https://github.com/Hauskamel/traffic-society/pull/3): `develop` zunächst in `feature/vehicleDamage` aktualisiert, anschließend `feature/vehicleDamage` → `develop`, zusammengeführt.
- [PR #5](https://github.com/Hauskamel/traffic-society/pull/5): `feature/bodPhysics` → `develop`, derzeit offen.

Die zeitliche Reihenfolge **#4 vor #3** ist beabsichtigt und entspricht der Git-Historie. Nach `main` wurden bislang keine späteren Spielfunktionen zusammengeführt. Dass diese Übersicht auch dort liegt, ändert den dortigen Spielstand nicht.

## Übersicht aktuell halten

Bei einem neuen Branch oder Merge dieses Diagramm, die Branch-Tabelle und das Standdatum aktualisieren. Nur tatsächlich zusammengeführte Funktionen als übernommen darstellen. Gelöschte Remote-Branches dürfen als historische Linien erhalten bleiben. Die Übersicht wird als reine Dokumentation auf allen noch vorhandenen Remote-Branches gepflegt; Spielfunktionen werden ausschließlich über den [Git-Arbeitsablauf](GIT-WORKFLOW.md) integriert.

Für den vollständigen lokalen Verlauf:

```bash
git fetch origin --prune
git log --graph --oneline --decorate --all
```
