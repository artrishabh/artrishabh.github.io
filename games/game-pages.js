(() => {
  const games = window.GAME_DATA || [];
  const bySlug = Object.fromEntries(games.map((game) => [game.slug, game]));
  const escapeHtml = (value = "") => String(value).replace(/[&<>'"]/g, (char) => ({"&":"&amp;","<":"&lt;",">":"&gt;","'":"&#39;",'"':"&quot;"}[char]));
  const yearNodes = document.querySelectorAll("[data-year]");
  yearNodes.forEach((node) => { node.textContent = new Date().getFullYear(); });

  const categoryName = { full: "Full games", jam: "Game jams", prototype: "Prototypes" };

  function renderGamePage(game) {
    const root = document.querySelector("#game-page-root");
    if (!root || !game) return;
    document.title = `${game.title} | Rishabh Jain`;
    const hero = game.images[0] || "";
    const controls = (game.controls || []).map((item) => `<li>${escapeHtml(item)}</li>`).join("");
    const credits = (game.credits || []).map(([role, name]) => `<div><dt>${escapeHtml(role)}</dt><dd>${escapeHtml(name)}</dd></div>`).join("");
    const gallery = (game.images || []).map((image, index) => `<button class="gallery-item" type="button" data-lightbox="${escapeHtml(image)}" aria-label="Open ${escapeHtml(game.title)} screenshot ${index + 1}"><img src="${escapeHtml(image)}" alt="${escapeHtml(game.title)} gameplay screenshot ${index + 1}" loading="lazy" referrerpolicy="no-referrer" /></button>`).join("");
    const video = game.videoId ? `<section class="store-section" id="gameplay"><div class="section-title-row"><div><p class="store-kicker">Gameplay</p><h2>Watch it in action</h2></div><a class="quiet-link" href="https://www.youtube.com/watch?v=${escapeHtml(game.videoId)}" target="_blank" rel="noreferrer">Open on YouTube ↗</a></div><div class="video-frame"><iframe src="https://www.youtube-nocookie.com/embed/${escapeHtml(game.videoId)}" title="${escapeHtml(game.title)} gameplay video" loading="lazy" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe></div></section>` : "";
    const related = games.filter((item) => item.slug !== game.slug).sort((a, b) => Number(b.category === game.category) - Number(a.category === game.category)).slice(0, 3).map((item) => `<a class="mini-game" href="${escapeHtml(item.slug)}.html"><img src="${escapeHtml(item.images[0])}" alt="" loading="lazy" referrerpolicy="no-referrer"/><span><small>${escapeHtml(item.genre)}</small><strong>${escapeHtml(item.title)}</strong></span></a>`).join("");

    root.innerHTML = `
      <section class="game-hero" style="--hero-image:url('${hero.replace(/'/g, "%27")}')">
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
    setupLightbox();
  }

  function renderCatalogue() {
    const grid = document.querySelector("#catalogue-grid");
    if (!grid) return;
    grid.innerHTML = games.map((game) => `<article class="catalogue-card" data-category="${escapeHtml(game.category)}" data-title="${escapeHtml(`${game.title} ${game.genre}`.toLowerCase())}"><a href="${escapeHtml(game.slug)}.html"><div class="catalogue-art"><img src="${escapeHtml(game.images[0])}" alt="${escapeHtml(game.title)}" loading="lazy" referrerpolicy="no-referrer"/><span class="genre-pill">${escapeHtml(game.genre)}</span></div><div class="catalogue-copy"><p>${escapeHtml(categoryName[game.category])}</p><h2>${escapeHtml(game.title)}</h2><span>${escapeHtml(game.tagline)}</span><b>View project page →</b></div></a></article>`).join("");
    document.querySelector("[data-project-count]").textContent = String(games.length);
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
    buttons.forEach((button) => button.addEventListener("click", () => { buttons.forEach((item) => item.classList.remove("active")); button.classList.add("active"); filter = button.dataset.filter; update(); }));
    search?.addEventListener("input", update);
  }

  function setupLightbox() {
    const dialog = document.querySelector("dialog.lightbox");
    if (!dialog) return;
    const image = dialog.querySelector("img");
    document.querySelectorAll("[data-lightbox]").forEach((button) => button.addEventListener("click", () => { image.src = button.dataset.lightbox; dialog.showModal(); }));
    dialog.querySelector("button")?.addEventListener("click", () => dialog.close());
    dialog.addEventListener("click", (event) => { if (event.target === dialog) dialog.close(); });
  }

  const slug = document.body.dataset.game;
  if (slug) renderGamePage(bySlug[slug]);
  if (document.body.dataset.page === "catalogue") renderCatalogue();
})();
