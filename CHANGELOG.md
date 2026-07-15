# Changelog

## Cozy interaction polish

- Made the home-page scroll cue larger, clickable, and animated.
- Moved company logos beside the role headings in Experience.
- Removed the OVERDARE contract pill and increased that card's vertical breathing room.
- Added the Technical Art “Stay tuned” message.
- Unified individual game-page typography with the main portfolio fonts.
- Added alternating pastel colors to game-page and catalogue blocks.
- Fixed active navigation so Contact highlights correctly at the bottom of the page.
- Replaced the dark favicon with a colorful RJ landscape icon.
- Added subtle hover, reveal, floating, and parallax-friendly motion with reduced-motion support.

## Image reliability and Technical Art cleanup

- Temporarily removed the Technical Art articles and breakdowns area.
- Added local screenshots for Squeak Off, Nodesmith, Netherborne, Bean 'Em All, and Graycing.
- Added local project covers for every other catalogue entry.
- Stopped using remote itch.io images for homepage cards, catalogue covers, related-game cards, and game-page heroes.
- Added automatic fallback artwork when a remote gallery screenshot is blocked or unavailable.
- Updated cache versions for game CSS and JavaScript files.

## Portfolio expansion

- Added Technical Art showreels from YouTube.
- Added future article and case-study placeholders.
- Added a storefront-style page for every game in the catalogue.
- Added a searchable and filterable game catalogue.
- Added screenshots, videos, credits, controls, and itch.io download/play links.
- Added icon-based GitHub, itch.io, and LinkedIn links.
- Updated contact details.
- Added cache-busting versions to the main stylesheets.
- Set fallback logo dimensions to prevent oversized logos while CSS is loading.

## Games grid image layering and catalogue CTA
- Moved selected-game cover artwork into the card artwork layer so fallback gradients cannot render over real covers.
- Replaced negative pseudo-element stacking with explicit layers for more consistent browser rendering.
- Added a large View all games card after Graycing to fill the final grid row and direct visitors to the complete catalogue.

## Cozy cartoon redesign
- Reworked the visual system from dark cinematic to a warm, playful game-development portfolio.
- Added chunky illustrated borders, offset shadows, rounded cards, paper textures, and brighter section backgrounds.
- Added three selectable palettes: Sunlit Workshop, Berry Picnic, and Forest Camp.
- Saved the selected palette in the browser and carried it across the portfolio, catalogue, and standalone game pages.
- Restyled the hero, experience cards, showreels, game cards, resume, contact section, catalogue, game-detail pages, and 404 page.
- Kept the redesign in separate override stylesheets so future visual changes remain easy.
