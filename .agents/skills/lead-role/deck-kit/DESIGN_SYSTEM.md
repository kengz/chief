# Deck design system

The standard a progress deck is built to: professional, technical, and worth a reader's time.

## Tooling

1. HTML and CSS rendered to PDF with weasyprint; pymupdf turns pages into PNG for self-review.
2. `render_deck.py` is copied into the project as `scripts/render_deck.py`. It treats its parent's parent as the repo root, so it renders `decks/<name>.html` to `renders/<name>.pdf` (add `--png N|all` for previews) only from there.
3. `deck.css` is copied in beside the decks as `decks/deck.css`; it holds the design system as CSS.
4. Figures are hand-written SVG. Layout uses flexbox, because weasyprint's grid support is incomplete.
5. Fonts are IBM Plex Sans and Mono. Install the system libraries and fonts first (for example `libpango-1.0-0 libpangocairo-1.0-0 fontconfig fonts-ibm-plex` on Debian), then `pip install weasyprint pymupdf`.

## Visual system (exact values in `deck.css`)

1. **Type:** a sans face for text, a mono face for every number, label and code; two dominant sizes per slide; weight, never italics, for emphasis.
2. **Grid:** twelve columns, everything flush left, at least a third of each slide left empty.
3. **Color:** near-black ink, two grays, a hairline, a panel tint, one accent and one second data hue. No red, amber and green stoplight.
4. **Anatomy:** a small label orients, the headline states the finding (a claim, not a topic), a figure gives the evidence, and a footer carries the source note and slide number.
5. **Charts:** inline SVG without border, legend or gridlines; values labelled directly; bars start at zero; one highlighted series.
6. **Diagrams:** outlined nodes, one accent node, right-angle edges.
7. **Lists:** no bullets in boxes; use a ruled key and value list, or a short numbered sequence.

## Figures read from artifacts

Every number on a slide is read from its verdict artifact at render time through `{{key}}` tokens; an unknown token fails the render rather than shipping a stale value.

## Do not overclaim

1. Show design and result apart on every deck; unrun design is never presented as a result.
2. An inconclusive result is shown with its intervals and the bar it missed.
3. A metric is named for what it measures, not for what it hopes to show.
