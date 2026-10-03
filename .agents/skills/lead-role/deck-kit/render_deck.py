"""Render a professional HTML/CSS deck → PDF (weasyprint), with PNG previews (pymupdf).

HTML/CSS gives real
typography (IBM Plex), a true layout grid, generous whitespace, and hand-authored SVG figures;
weasyprint prints 16:9 slides; pymupdf rasterizes for self-review.

Run: `uv run python scripts/render_deck.py decks/<name>.html`         -> renders/<name>.pdf
     `uv run python scripts/render_deck.py decks/<name>.html --png 2`  -> + preview PNG of slide 2
     `uv run python scripts/render_deck.py decks/<name>.html --png all` -> + all-slide previews
"""
from __future__ import annotations

import os
import sys
import tempfile
from pathlib import Path
from weasyprint import HTML
import fitz

ROOT = Path(__file__).resolve().parents[1]
RENDERS = ROOT / "renders"
# Previews are for self-review, so they go to a scratch dir rather than the repo.
# Set DECK_SCRATCH to put them somewhere you can find twice.
SCRATCH = Path(os.environ.get("DECK_SCRATCH") or Path(tempfile.gettempdir()) / "deck-previews")


def _resolve_tokens(html: str) -> str:
    """Substitute every {{key}} with its artifact-read figure.

    No-op for decks that carry no tokens; an unknown token or missing artifact
    fails loudly here rather than shipping a stale literal.
    """
    if "{{" not in html:
        return html
    sys.path.insert(0, str(ROOT / "decks"))
    import deck_data
    for key, val in deck_data.tokens().items():
        html = html.replace(f"{{{{{key}}}}}", val)
    if "{{" in html:
        stray = html[html.index("{{"):].split("}}", 1)[0] + "}}"
        raise ValueError(f"unresolved deck token {stray} — add it to decks/deck_data.py")
    return html


def render(html_path: Path, png: str | None = None):
    html_path = Path(html_path)
    out_pdf = RENDERS / f"{html_path.stem}.pdf"
    html = _resolve_tokens(html_path.read_text())
    HTML(string=html, base_url=str(html_path.parent)).write_pdf(str(out_pdf))
    doc = fitz.open(str(out_pdf))
    print(f"  {html_path.name} -> {out_pdf.relative_to(ROOT)}  ({len(doc)} slides, {out_pdf.stat().st_size//1024} KB)")
    if png:
        SCRATCH.mkdir(parents=True, exist_ok=True)
        pages = range(len(doc)) if png == "all" else [int(png) - 1]
        for i in pages:
            pix = doc[i].get_pixmap(dpi=150)
            p = SCRATCH / f"{html_path.stem}_s{i+1}.png"
            pix.save(str(p))
            print(f"    preview slide {i+1} -> {p}")
    doc.close()
    return out_pdf


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: render_deck.py <deck.html> [--png N|all]"); sys.exit(1)
    png = None
    if "--png" in sys.argv:
        png = sys.argv[sys.argv.index("--png") + 1]
    render(sys.argv[1], png=png)
