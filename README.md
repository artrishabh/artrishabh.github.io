# Rishabh Jain Portfolio - Dark Cinematic Blockout v2

A beginner-friendly static portfolio built with plain HTML, CSS, and JavaScript. No framework, package manager, or build command is required.

## What is included

- Responsive dark-cinematic one-page layout
- Desktop sidebar and mobile navigation
- Experience timeline
- Three technical-art case-study slots
- Six game project cards linked to itch.io
- Resume and contact sections
- Keyboard-accessible navigation and skip link
- Reduced-motion support
- Scroll progress, section reveal, and subtle hero movement
- Social sharing preview and favicon
- Custom GitHub Pages 404 page
- Content checklist for the next editing session

## Project files

- `index.html` - all page content
- `styles.css` - layout and visual styling
- `script.js` - navigation, section highlighting, motion, and scroll behavior
- `404.html` - custom missing-page screen for GitHub Pages
- `CONTENT_CHECKLIST.md` - details and assets to collect
- `assets/` - resume, screenshots, videos, favicon, and social preview

## Preview it on your computer

### Easiest method

Double-click `index.html`. It should open in your browser.

### Better local preview

If Python is installed, open a terminal inside this folder and run:

```bash
python -m http.server 8000
```

Then visit:

```text
http://localhost:8000
```

## Edit these placeholders before publishing

Search inside `index.html` for:

1. `Add company name`
2. `your-email@example.com`
3. `Resume PDF coming next`
4. Exact experience dates and titles
5. Technical-art case-study placeholder copy

Also review `CONTENT_CHECKLIST.md`.

## Add your resume

1. Put the PDF at `assets/Rishabh_Jain_Resume.pdf`.
2. Find this element in `index.html`:

```html
<span class="button button-primary disabled-link" aria-disabled="true">Resume PDF coming next</span>
```

3. Replace it with:

```html
<a class="button button-primary" href="assets/Rishabh_Jain_Resume.pdf" target="_blank" rel="noreferrer">Open resume</a>
```

## Add real project images

Put optimized `.webp` or `.jpg` images inside `assets/images/`.

Example:

```css
.game-nodesmith {
  --game-bg: url("assets/images/nodesmith-cover.webp") center / cover no-repeat;
}
```

Suggested starting dimensions:

- Game images: 1400 x 900 pixels
- Technical-art images: 1600 x 1000 pixels
- Try to keep each image below 500 KB

## Publish with GitHub Pages

### Recommended repository name

```text
gamelordzzz.github.io
```

The site will publish at:

```text
https://gamelordzzz.github.io/
```

### Upload steps

1. Sign in to GitHub.
2. Create a new public repository named `gamelordzzz.github.io`.
3. Open the new repository.
4. Choose **Add file -> Upload files**.
5. Upload the contents of this folder. `index.html` must be at the repository root.
6. Commit the files to the `main` branch.
7. Open **Settings -> Pages**.
8. Under **Build and deployment**, choose **Deploy from a branch**.
9. Choose branch `main` and folder `/ (root)`.
10. Save and open `https://gamelordzzz.github.io/` after deployment finishes.

## Important note about the site URL

The Open Graph and canonical URL currently use:

```text
https://gamelordzzz.github.io/
```

If you publish under a different username, repository, or custom domain, update the `og:url` and `canonical` entries near the top of `index.html`.

## Next session priorities

1. Confirm experience details and dates.
2. Add the real resume and email.
3. Collect approved technical-art visuals.
4. Replace game gradients with screenshots or GIFs.
5. Turn the strongest technical-art project into a detailed case study.
