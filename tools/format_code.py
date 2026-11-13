"""Formatiert GDScript einheitlich; Parserdaten bleiben im lokalen Projektcache."""
import argparse
from pathlib import Path

from gdtoolkit.formatter import check_formatting_safety, format_code
from gdtoolkit.parser import parser

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    """Formatiert Spiel-, Prototyp- und Testskripte oder meldet Abweichungen."""
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("--check", action="store_true", help="Check without modifying files")
    options = cli.parse_args()
    # gdtoolkit 4.5 creates a cache directory even when caching is disabled.
    # Keep that implementation detail inside Godot's ignored local cache.
    parser._cache_dirpath = str(ROOT / ".godot" / "formatter")
    parser.disable_grammar_caching()
    changed = []
    for folder in ("game", "prototypes", "tests"):
        for path in sorted((ROOT / folder).rglob("*.gd")):
            before = path.read_text(encoding="utf-8")
            after = format_code(before, 100)
            check_formatting_safety(before, after, 100)
            if after != before:
                changed.append(path.relative_to(ROOT).as_posix())
                if not options.check:
                    path.write_text(after, encoding="utf-8", newline="\n")
    print(f"{len(changed)} script(s) {'need formatting' if options.check else 'formatted'}")
    for name in changed:
        print(name)
    return int(options.check and bool(changed))


if __name__ == "__main__":
    raise SystemExit(main())
