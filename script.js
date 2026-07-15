const navLinks = [...document.querySelectorAll('.nav-link')];
const sections = [...document.querySelectorAll('[data-section]')];
const menuToggle = document.querySelector('.menu-toggle');
const nav = document.querySelector('.primary-nav');
const progressBar = document.querySelector('.scroll-progress span');
const backToTop = document.querySelector('.back-to-top');
const hero = document.querySelector('.hero');
const heroAtmosphere = document.querySelector('.hero-atmosphere');
const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

const setActiveLink = (sectionId) => {
  navLinks.forEach((link) => {
    const isActive = link.getAttribute('href') === `#${sectionId}`;
    link.classList.toggle('active', isActive);
    if (isActive) link.setAttribute('aria-current', 'location');
    else link.removeAttribute('aria-current');
  });
};

if ('IntersectionObserver' in window) {
  const sectionObserver = new IntersectionObserver(
    (entries) => {
      const visible = entries
        .filter((entry) => entry.isIntersecting)
        .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];

      if (visible) setActiveLink(visible.target.dataset.section);
    },
    { rootMargin: '-20% 0px -55% 0px', threshold: [0.1, 0.35, 0.6] }
  );

  sections.forEach((section) => sectionObserver.observe(section));
}

const closeMenu = () => {
  nav?.classList.remove('open');
  menuToggle?.setAttribute('aria-expanded', 'false');
  document.body.classList.remove('menu-open');
};

menuToggle?.addEventListener('click', () => {
  const open = !nav.classList.contains('open');
  nav.classList.toggle('open', open);
  menuToggle.setAttribute('aria-expanded', String(open));
  document.body.classList.toggle('menu-open', open);
});

navLinks.forEach((link) => link.addEventListener('click', closeMenu));

document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape') {
    closeMenu();
    menuToggle?.focus();
  }
});

document.addEventListener('click', (event) => {
  if (nav?.classList.contains('open') && !nav.contains(event.target) && !menuToggle?.contains(event.target)) {
    closeMenu();
  }
});

window.addEventListener('resize', () => {
  if (window.innerWidth > 720) closeMenu();
});

const revealItems = [...document.querySelectorAll('.reveal')];
if (reduceMotion || !('IntersectionObserver' in window)) {
  revealItems.forEach((item) => item.classList.add('is-visible'));
} else {
  const revealObserver = new IntersectionObserver(
    (entries, observer) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add('is-visible');
        observer.unobserve(entry.target);
      });
    },
    { threshold: 0.12, rootMargin: '0px 0px -8% 0px' }
  );
  revealItems.forEach((item) => revealObserver.observe(item));
}

let scrollTicking = false;
const updateScrollUI = () => {
  const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
  const progress = maxScroll > 0 ? window.scrollY / maxScroll : 0;
  progressBar.style.transform = `scaleX(${Math.min(1, Math.max(0, progress))})`;
  backToTop.classList.toggle('visible', window.scrollY > window.innerHeight * 0.7);
  scrollTicking = false;
};

window.addEventListener('scroll', () => {
  if (!scrollTicking) {
    window.requestAnimationFrame(updateScrollUI);
    scrollTicking = true;
  }
}, { passive: true });

backToTop?.addEventListener('click', () => {
  window.scrollTo({ top: 0, behavior: reduceMotion ? 'auto' : 'smooth' });
});

if (!reduceMotion && hero && heroAtmosphere) {
  hero.addEventListener('pointermove', (event) => {
    const rect = hero.getBoundingClientRect();
    const x = ((event.clientX - rect.left) / rect.width - 0.5) * 18;
    const y = ((event.clientY - rect.top) / rect.height - 0.5) * 18;
    heroAtmosphere.style.setProperty('--px', `${x}px`);
    heroAtmosphere.style.setProperty('--py', `${y}px`);
  });

  hero.addEventListener('pointerleave', () => {
    heroAtmosphere.style.setProperty('--px', '0px');
    heroAtmosphere.style.setProperty('--py', '0px');
  });
}

document.getElementById('year').textContent = new Date().getFullYear();
updateScrollUI();

// Load selected-game artwork from local asset folders. Add either cover.* or shot-1.*
// to assets/games/<game-slug>/ and the homepage card updates automatically.
(() => {
  const extensions = ['webp', 'png', 'jpg', 'jpeg', 'avif'];

  const probeFirstAvailable = (candidates) => new Promise((resolve) => {
    let index = 0;
    const probe = new Image();
    const tryNext = () => {
      if (index >= candidates.length) {
        resolve(null);
        return;
      }
      const candidate = candidates[index++];
      probe.onload = () => resolve(candidate);
      probe.onerror = tryNext;
      probe.src = candidate;
    };
    tryNext();
  });

  document.querySelectorAll('[data-game-image]').forEach(async (card) => {
    const slug = card.dataset.gameImage;
    const stems = ['cover', 'shot-1'];
    const candidates = stems.flatMap((stem) => extensions.map((extension) => `assets/games/${slug}/${stem}.${extension}`));
    const source = await probeFirstAvailable(candidates);
    if (source) card.style.setProperty('--game-image', `url("${source}")`);
  });
})();
