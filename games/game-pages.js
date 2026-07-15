(() => {
  const games = window.GAME_DATA || [];
  const bySlug = Object.fromEntries(games.map((game) => [game.slug, game]));
  const escapeHtml = (value = "") => String(value).replace(/[&<>'"]/g, (char) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    "'": "&#39;",
    '"': "&quot;"
  })[char]);
  const escapeXml = (value = "") => String(value).replace(/[&<>'"]/g, (char) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    "'": "&apos;",
    '"': "&quot;"
  })[char]);

  document.querySelectorAll("[data-year]").forEach((node) => {
    node.textContent = new Date().getFullYear();
  });

  const categoryName = {
    full: "Full games",
    jam: "Game jams",
    prototype: "Prototypes"
  };

  function placeholderDataUri(title) {
    let hash = 0;
    for (const char of String(title)) hash = ((hash << 5) - hash + char.charCodeAt(0)) | 0;
    const hue = Math.abs(hash) % 360;
    const secondaryHue = (hue + 52) % 360;
    const safeTitle = escapeXml(title);
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720" viewBox="0 0 1280 720">
      <defs>
        <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop stop-color="hsl(${hue} 38% 18%)"/><stop offset="1" stop-color="#07090b"/></linearGradient>
        <radialGradient id="glow"><stop stop-color="hsl(${secondaryHue} 76% 62%)" stop-opacity=".5"/><stop offset="1" stop-color="hsl(${secondaryHue} 76% 62%)" stop-opacity="0"/></radialGradient>
        <pattern id="grid" width="48" height="48" patternUnits="userSpaceOnUse"><path d="M48 0H0V48" fill="none" stroke="#fff" stroke-opacity=".045"/></pattern>
      </defs>
      <rect width="1280" height="720" fill="url(#bg)"/><circle cx="1000" cy="170" r="360" fill="url(#glow)"/><rect x="44" y="44" width="1192" height="632" rx="18" fill="url(#grid)" stroke="#fff" stroke-opacity=".12"/>
      <text x="82" y="112" fill="#63d8dc" font-family="Arial,sans-serif" font-size="20" font-weight="700" letter-spacing="5">PROJECT IMAGE UNAVAILABLE</text>
      <text x="82" y="555" fill="#f3f6f7" font-family="Arial,sans-serif" font-size="72" font-weight="800">${safeTitle}</text>
      <text x="84" y="607" fill="#a8b3b9" font-family="Arial,sans-serif" font-size="24">View the game on itch.io for the complete gallery.</text>
    </svg>`;
    return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`;
  }

  function setupImageFallbacks(scope = document) {
    scope.querySelectorAll("img[data-fallback-title]").forEach((image) => {
      const applyFallback = () => {
        if (image.dataset.fallbackApplied === "true") return;
        image.dataset.fallbackApplied = "true";
        image.classList.add("is-fallback");
        image.removeAttribute("srcset");
        image.src = placeholderDataUri(image.dataset.fallbackTitle || "Game project");
      };

      image.addEventListener("error", applyFallback, { once: true });
      if (image.complete && image.naturalWidth === 0) applyFallback();
    });
  }

  function renderGamePage(game) {
    const root = document.querySelector("#game-page-root");
    if (!root || !game) return;

    document.title = `${game.title} | Rishabh Jain`;
    const hero = game.cover || game.images?.[0] || "";
    const controls = (game.controls || []).map((item) => `<li>${escapeHtml(item)}</li>`).join("");
    const credits = (game.credits || []).map(([role, name]) => `<div><dt>${escapeHtml(role)}</dt><dd>${escapeHtml(name)}</dd></div>`).join("");
    const gallery = (game.images || []).map((image, index) => `
      <button class="gallery-item" type="button" aria-label="Open ${escapeHtml(game.title)} screenshot ${index + 1}">
        <img src="${escapeHtml(image)}" alt="${escapeHtml(game.title)} gameplay screenshot ${index + 1}" loading="lazy" referrerpolicy="no-referrer" data-fallback-title="${escapeHtml(game.title)}" />
      </button>`).join("");
    const video = game.videoId ? `
      <section class="store-section" id="gameplay">
        <div class="section-title-row">
          <div><p class="store-kicker">Gameplay</p><h2>Watch it in action</h2></div>
          <a class="quiet-link" href="https://www.youtube.com/watch?v=${escapeHtml(game.videoId)}" target="_blank" rel="noreferrer">Open on YouTube ↗</a>
        </div>
        <div class="video-frame"><iframe src="https://www.youtube-nocookie.com/embed/${escapeHtml(game.videoId)}" title="${escapeHtml(game.title)} gameplay video" loading="lazy" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe></div>
      </section>` : "";
    const related = games
      .filter((item) => item.slug !== game.slug)
      .sort((a, b) => Number(b.category === game.category) - Number(a.category === game.category))
      .slice(0, 3)
      .map((item) => `<a class="mini-game" href="${escapeHtml(item.slug)}.html"><img src="${escapeHtml(item.cover || item.images?.[0] || "")}" alt="" loading="lazy" data-fallback-title="${escapeHtml(item.title)}"/><span><small>${escapeHtml(item.genre)}</small><strong>${escapeHtml(item.title)}</strong></span></a>`)
      .join("");

    root.innerHTML = `
      <section class="game-hero">
        <img class="game-hero-media" src="${escapeHtml(hero)}" alt="" loading="eager" fetchpriority="high" data-fallback-title="${escapeHtml(game.title)}" />
        <div class="hero-shade"></div>
        <div class="game-hero-content">
          <a class="breadcrumb" href="index.html">← All games</a>
          <p class="store-kicker">${escapeHtml(game.categoryLabel)} · ${escapeHtml(game.genre)}</p>
          <h1>${escapeHtml(game.title)}</h1>
          <p class="game-tagline">${escapeHtml(game.tagline)}</p>
          <div class="hero-buttons"><a class="button button-primary" href="${escapeHtml(game.itch)}#download" target="_blank" rel="noreferrer">Download on itch.io <span>↗</span></a><a class="button button-ghost" href="#gallery">View screenshots</a></div>
        </div>
      </section>
      <div class="store-shell">
        <div class="store-main">
          <section class="store-section intro-section"><p class="store-kicker">About the game</p><h2>${escapeHtml(game.tagline)}</h2><p>${escapeHtml(game.description)}</p></section>
          ${video}
          <section class="store-section" id="gallery"><div class="section-title-row"><div><p class="store-kicker">Gallery</p><h2>Screenshots</h2></div><span class="section-note">Click an image to enlarge</span></div><div class="gallery-grid">${gallery}</div></section>
          <section class="store-section two-column-info"><div><p class="store-kicker">How to play</p><h2>Controls</h2><ul class="control-list">${controls}</ul></div><div><p class="store-kicker">Team</p><h2>Credits</h2><dl class="credits-list">${credits}</dl></div></section>
        </div>
        <aside class="store-sidebar"><div class="purchase-card"><p class="availability">Available on itch.io</p><h2>Play ${escapeHtml(game.title)}</h2><p>The download button opens the official itch.io page so the latest build and platform files remain current.</p><a class="button button-primary button-wide" href="${escapeHtml(game.itch)}#download" target="_blank" rel="noreferrer">Download / Play ↗</a></div><dl class="game-meta"><div><dt>My role</dt><dd>${escapeHtml(game.role)}</dd></div><div><dt>Genre</dt><dd>${escapeHtml(game.genre)}</dd></div><div><dt>Platform</dt><dd>${escapeHtml(game.platforms)}</dd></div><div><dt>Tools</dt><dd>${escapeHtml(game.engine)}</dd></div><div><dt>Release</dt><dd>${escapeHtml(game.release)}</dd></div><div><dt>Status</dt><dd>${escapeHtml(game.status)}</dd></div><div><dt>Download</dt><dd>${escapeHtml(game.download)}</dd></div></dl></aside>
      </div>
      <section class="more-games"><div class="more-games-head"><div><p class="store-kicker">Keep exploring</p><h2>More games</h2></div><a href="index.html">Full catalogue →</a></div><div class="mini-game-grid">${related}</div></section>`;

    setupImageFallbacks(root);
    setupLightbox();
  }

  function renderCatalogue() {
    const grid = document.querySelector("#catalogue-grid");
    if (!grid) return;

    grid.innerHTML = games.map((game) => `
      <article class="catalogue-card" data-category="${escapeHtml(game.category)}" data-title="${escapeHtml(`${game.title} ${game.genre}`.toLowerCase())}">
        <a href="${escapeHtml(game.slug)}.html">
          <div class="catalogue-art"><img src="${escapeHtml(game.cover || game.images?.[0] || "")}" alt="${escapeHtml(game.title)}" loading="lazy" data-fallback-title="${escapeHtml(game.title)}"/><span class="genre-pill">${escapeHtml(game.genre)}</span></div>
          <div class="catalogue-copy"><p>${escapeHtml(categoryName[game.category])}</p><h2>${escapeHtml(game.title)}</h2><span>${escapeHtml(game.tagline)}</span><b>View project page →</b></div>
        </a>
      </article>`).join("");

    setupImageFallbacks(grid);
    const projectCount = document.querySelector("[data-project-count]");
    if (projectCount) projectCount.textContent = String(games.length);

    const cards = [...grid.querySelectorAll(".catalogue-card")];
    const buttons = [...document.querySelectorAll("[data-filter]")];
    const search = document.querySelector("[data-game-search]");
    let filter = "all";

    const update = () => {
      const query = (search?.value || "").trim().toLowerCase();
      let visible = 0;
      cards.forEach((card) => {
        const show = (filter === "all" || card.dataset.category === filter) && (!query || card.dataset.title.includes(query));
        card.hidden = !show;
        if (show) visible += 1;
      });
      const empty = document.querySelector(".empty-state");
      if (empty) empty.hidden = visible !== 0;
    };

    buttons.forEach((button) => button.addEventListener("click", () => {
      buttons.forEach((item) => item.classList.remove("active"));
      button.classList.add("active");
      filter = button.dataset.filter;
      update();
    }));
    search?.addEventListener("input", update);
  }

  function setupLightbox() {
    const dialog = document.querySelector("dialog.lightbox");
    if (!dialog) return;
    const image = dialog.querySelector("img");

    document.querySelectorAll(".gallery-item").forEach((button) => button.addEventListener("click", () => {
      const source = button.querySelector("img");
      image.src = source?.currentSrc || source?.src || "";
      dialog.showModal();
    }));
    dialog.querySelector("button")?.addEventListener("click", () => dialog.close());
    dialog.addEventListener("click", (event) => {
      if (event.target === dialog) dialog.close();
    });
  }

  const slug = document.body.dataset.game;
  if (slug) renderGamePage(bySlug[slug]);
  if (document.body.dataset.page === "catalogue") renderCatalogue();
})();
