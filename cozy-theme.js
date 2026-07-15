(() => {
  const themes = ['sunny', 'berry', 'forest'];
  const fallback = 'sunny';
  const themeColors = { sunny: '#fff6df', berry: '#fff1f3', forest: '#f4f0e2' };
  let saved = fallback;

  try {
    const stored = window.localStorage.getItem('portfolio-theme');
    if (themes.includes(stored)) saved = stored;
  } catch (_) {
    saved = fallback;
  }

  document.documentElement.dataset.theme = saved;

  document.addEventListener('DOMContentLoaded', () => {
    const buttons = [...document.querySelectorAll('[data-theme-choice]')];
    const applyTheme = (theme) => {
      if (!themes.includes(theme)) return;
      document.documentElement.dataset.theme = theme;
      const themeMeta = document.querySelector('meta[name="theme-color"]');
      if (themeMeta) themeMeta.setAttribute('content', themeColors[theme]);
      buttons.forEach((button) => {
        const active = button.dataset.themeChoice === theme;
        button.classList.toggle('is-active', active);
        button.setAttribute('aria-pressed', String(active));
      });
      try { window.localStorage.setItem('portfolio-theme', theme); } catch (_) {}
    };

    buttons.forEach((button) => {
      button.addEventListener('click', () => applyTheme(button.dataset.themeChoice));
    });

    applyTheme(document.documentElement.dataset.theme || fallback);
  });
})();
