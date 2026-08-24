(() => {
  const section = document.querySelector('#technical-art');
  if (!section) return;

  const showreels = section.querySelector('.showreel-grid');
  const anchor = showreels || section.querySelector('.section-heading') || section;

  const escapeHtml = (value = '') =>
    String(value).replace(/[&<>"']/g, ch => ({
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#039;'
    })[ch]);

  const extensions = ['webp', 'png', 'jpg', 'jpeg', 'avif'];

  function resolveCover(img, slug, preferred) {
    const candidates = [];

    if (preferred) {
      candidates.push(`assets/technical-art/${slug}/${preferred}`);
    }

    extensions.forEach(ext => {
      candidates.push(`assets/technical-art/${slug}/cover.${ext}`);
      candidates.push(`assets/technical-art/${slug}/shot-1.${ext}`);
    });

    let cursor = 0;

    const next = () => {
      if (cursor >= candidates.length) {
        img.removeAttribute('src');
        img.closest('.ta-post-card-media')?.classList.add('is-placeholder');
        return;
      }

      img.src = candidates[cursor++];
    };

    img.addEventListener('error', next);
    next();
  }

  fetch('technical-art/posts.json', { cache: 'no-store' })
    .then(response => response.ok ? response.json() : [])
    .then(data => {
      const posts = (
        Array.isArray(data)
          ? data
          : (data && typeof data === 'object' ? [data] : [])
      ).filter(post => post && post.published !== false);

      if (!posts.length) return;

      document.querySelector('.ta-posts-home')?.remove();

      const block = document.createElement('div');
      block.className = 'ta-posts-home reveal';

      block.innerHTML = `
        <div class="ta-posts-heading">
          <div>
            <p class="eyebrow">Tools & Breakdowns</p>
            <h3>Technical Art Posts</h3>
          </div>
          <p>Tools, shaders, workflows, and technical breakdowns.</p>
        </div>
        <div class="ta-post-grid"></div>
      `;

      const grid = block.querySelector('.ta-post-grid');

      posts.forEach(post => {
        const tags = (post.tags || [])
          .slice(0, 4)
          .map(tag => `<span>${escapeHtml(tag)}</span>`)
          .join('');

        const card = document.createElement('a');
        card.className = 'ta-post-card';
        card.href = `technical-art/${encodeURIComponent(post.slug)}/`;

        card.innerHTML = `
          <div class="ta-post-card-media">
            <img alt="" loading="lazy" decoding="async">
            <span class="ta-post-card-type">${escapeHtml(post.category || 'Technical Art')}</span>
          </div>
          <div class="ta-post-card-copy">
            <h4>${escapeHtml(post.title)}</h4>
            <p>${escapeHtml(post.excerpt || '')}</p>
            <div class="ta-post-card-tags">${tags}</div>
            <strong>Read breakdown <span aria-hidden="true">-></span></strong>
          </div>
        `;

        grid.appendChild(card);
        resolveCover(card.querySelector('img'), post.slug, post.cover);
      });

      if (showreels) {
        showreels.insertAdjacentElement('afterend', block);
      } else if (anchor !== section) {
        anchor.insertAdjacentElement('afterend', block);
      } else {
        section.appendChild(block);
      }

      if (window.IntersectionObserver) {
        const observer = new IntersectionObserver(entries => {
          entries.forEach(entry => {
            if (entry.isIntersecting) {
              entry.target.classList.add('is-visible');
              observer.unobserve(entry.target);
            }
          });
        }, { threshold: 0.08 });

        observer.observe(block);
      } else {
        block.classList.add('is-visible');
      }
    })
    .catch(error => {
      console.warn('Technical Art posts could not be loaded.', error);
    });
})();
