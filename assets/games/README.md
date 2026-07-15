# Local game images

Each game reads images automatically from its own folder. You do not need to edit HTML or JavaScript when adding screenshots.

## Folder and file naming

Use the game's exact slug as the folder name:

```text
assets/games/divine-darkness/
  cover.png       # optional catalogue/home card image
  hero.png        # optional wide banner for the project page
  shot-1.png      # gallery image 1; also used as cover when cover is absent
  shot-2.png
  shot-3.png
```

Supported image extensions:

```text
.webp .png .jpg .jpeg .avif
```

The loader checks these names automatically:

- `hero.*` for the large page banner
- `cover.*` for catalogue and homepage cards
- `shot-1.*`, `shot-2.*`, and onward for the gallery

If `hero.*` or `cover.*` is absent, the site uses `shot-1.*`.

## Important GitHub rules

- File and folder names are case-sensitive on GitHub Pages.
- Use lowercase names exactly: `shot-1.png`, not `Shot-1.PNG`.
- Include the extension in the filename.
- Keep screenshot numbers continuous: `shot-1`, `shot-2`, `shot-3`.
- After uploading, hard-refresh with `Ctrl + Shift + R` if an old image remains cached.

## Current game folder slugs

```text
squeak-off
entwined-reimagined
nodesmith
statescape
netherborne
bean-em-all
overryder
graycing
statescape-jam
something-fishy
paws-n-claws
gun-it
nezumi
fortune-smiles-upon-you
entwined
divine-darkness
project-xmas
```
