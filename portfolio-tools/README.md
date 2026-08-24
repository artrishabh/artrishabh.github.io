# Portfolio Manager - PowerShell version

No Python required.

## Install

Delete the previous Python version if you copied it into the repo.

Then copy this folder into the root of your local cloned portfolio:

```text
artrishabh.github.io/
|-- index.html
|-- styles.css
|-- ...
`-- portfolio-tools/
    |-- portfolio-manager.bat
    |-- portfolio-manager.ps1
    `-- README.md
```

Double-click:

```text
portfolio-manager.bat
```

The BAT file starts Windows PowerShell with a temporary ExecutionPolicy bypass only for this script.

## Main menu

```text
Rishabh Portfolio Manager

1. Technical Art
2. Preview website locally
3. Git status
0. Exit
```

Technical Art currently supports:

```text
1. Add post
2. List posts
3. Publish / hide post
4. Remove post
5. Install / repair homepage integration
```

## Safety

Before creating a post:

- The tool checks your current Git branch.
- If you have uncommitted edits, it does not pull/reset anything.
- If the tree is clean, it fetches origin.
- If the branch is behind, it offers `git pull --ff-only`.
- It never runs `git reset`, `git checkout .`, or `git clean`.
- The first homepage integration creates a backup of `index.html`.

This means it works against your actual current branch instead of an old ZIP snapshot.

## Adding a Technical Art post

Choose:

```text
1. Technical Art
1. Add post
```

It asks for:

- Title
- URL slug
- Category/type
- Short card description
- Tags
- Date
- YouTube or local video
- Optional cover image
- Overview
- Why you made it
- Technical approach
- Usage steps
- Technical notes
- Results/learnings
- Optional source link
- Optional screenshots
- Published/draft state

It creates:

```text
technical-art/<slug>/index.html
assets/technical-art/<slug>/
```

## One-time homepage integration

The first run only inserts these references into your existing `index.html`:

```html
<link rel="stylesheet" href="technical-art/posts.css" />
<script src="technical-art/posts.js" defer></script>
```

After that, adding posts does not rewrite the Technical Art section in `index.html`.

Post cards are loaded from:

```text
technical-art/posts.json
```

## Local media

Generated media folders look like:

```text
assets/technical-art/shader-graph-utility/
|-- cover.png
|-- demo.mp4
|-- shot-1.png
|-- shot-2.png
`-- README.txt
```

Gallery images named `shot-1` through `shot-20` are detected automatically.

Supported:

```text
.webp
.png
.jpg
.jpeg
.avif
```

## Preview

Choose:

```text
2. Preview website locally
```

The built-in PowerShell static server opens:

```text
http://localhost:8000
```

Press `Ctrl+C` to stop it.

## Publish

The tool does not auto-push.

After previewing:

```bash
git status
git add .
git commit -m "Add technical art post"
git push
```

## If Windows warns about PowerShell

Use the `.bat` launcher rather than double-clicking the `.ps1`.

The launcher runs:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass
```

for this one script only. It does not permanently change your PowerShell execution policy.


## Reliability notes

- `posts.json` is always written as a JSON array, even when there is only one post.
- The homepage renderer also accepts older single-object `posts.json` files so existing posts do not disappear.
- The manager never rewrites finalized homepage content when adding posts; it only maintains the Technical Art runtime files.
- Optional source links are only added when they start with `http://` or `https://`.
- `.vs/` and `portfolio-tools/backups/` should stay out of Git; the supplied `.gitignore` handles that.
