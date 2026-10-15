# Icon Composer artwork

All SVG assets use a transparent 1024 × 1024 canvas and contain only `<path>` elements. Numbers are outlined, with no font dependency. No raster images, filters, strokes, masks, gradients, or external resources are embedded.

## Files

- `2048.svg`: complete artwork, ready for single-layer import.
- `01-board.svg`: taupe board base.
- `02-tiles.svg`: four classic-colored tiles.
- `03-numbers.svg`: outlined digits arranged as 2, 0, 4, 8.
- `preview.png`: visual reference only; not an icon source.
- `build-icon.swift`: regenerates the paths using macOS CoreText.

## Import

Use either the combined `2048.svg` or the three numbered layers, not both. For separate layers, keep the board at the bottom, tiles in the middle, and numbers on top. All files share the same viewBox and coordinates; preserve their shared canvas alignment when importing rather than independently fitting each layer's visible bounds.

Choose the full icon background color in Icon Composer, for example classic ivory `#FAF8EF`. The SVG artwork is intentionally inset from the canvas edges. Let Icon Composer supply the final system icon shape and materials. Avoid extra shadows or bevels if retaining the app's simple classic appearance.

The Icon Composer `.icon` document and its project integration are left for your composition step.

Regenerate from the repository root:

```sh
swift macOS/Icon/build-icon.swift
```
