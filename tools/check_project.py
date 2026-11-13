"""Prüft feste Godot-Ressourcenpfade, Skript-UIDs und Dokumentationsblöcke."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESOURCE = re.compile(r'''["']res://([^"']+)["']''')
FUNCTION = re.compile(r"^(?:static )?func \w+\(")


def main() -> int:
    """Meldet fehlende Dateien, doppelte UIDs und undokumentierte Funktionen."""
    errors = []
    uids = {}
    scripts = []
    for folder in ("game", "prototypes", "tests"):
        scripts.extend(sorted((ROOT / folder).rglob("*.gd")))
    resources = scripts + list((ROOT / "game").rglob("*.tscn"))
    resources += list((ROOT / "prototypes").rglob("*.tscn"))
    resources.append(ROOT / "project.godot")
    for path in resources:
        source = path.read_text(encoding="utf-8")
        for target in RESOURCE.findall(source):
            if "%" not in target and not (ROOT / target).exists():
                errors.append(f"{path.relative_to(ROOT)}: missing res://{target}")
    for path in scripts:
        lines = path.read_text(encoding="utf-8").splitlines()
        if not lines or not lines[0].startswith("## "):
            errors.append(f"{path.relative_to(ROOT)}: missing script documentation")
        for line_number, line in enumerate(lines):
            if FUNCTION.match(line) and (
                line_number == 0 or not lines[line_number - 1].startswith("## ")
            ):
                errors.append(
                    f"{path.relative_to(ROOT)}:{line_number + 1}: missing function documentation"
                )
        uid_path = path.with_suffix(".gd.uid")
        if not uid_path.is_file():
            errors.append(f"{path.relative_to(ROOT)}: missing .gd.uid; import with Godot first")
            continue
        uid = uid_path.read_text(encoding="utf-8").strip()
        if not uid.startswith("uid://"):
            errors.append(f"{uid_path.relative_to(ROOT)}: invalid UID")
        if uid in uids:
            errors.append(f"{uid_path.relative_to(ROOT)}: duplicate of {uids[uid]}")
        uids[uid] = uid_path.relative_to(ROOT)
    print(f"{len(scripts)} scripts checked; {len(errors)} issue(s)")
    for error in errors:
        print(error)
    return int(bool(errors))


if __name__ == "__main__":
    raise SystemExit(main())
