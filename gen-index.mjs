// Generate the how-to index page with embedded demos and source code
import { readdirSync, readFileSync, writeFileSync, existsSync } from 'fs';
import { join, basename } from 'path';

const root = new URL('.', import.meta.url).pathname;
const siteDir = join(root, 'site');

const howtos = [];

for (const entry of readdirSync(root, { withFileTypes: true })) {
  if (!entry.isDirectory()) continue;
  if (['site', '.git', 'node_modules'].includes(entry.name)) continue;
  const dir = join(root, entry.name);
  const mainPurs = join(dir, 'src', 'Main.purs');
  const spagoYaml = join(dir, 'spago.yaml');
  if (!existsSync(mainPurs) || !existsSync(spagoYaml)) continue;

  const source = readFileSync(mainPurs, 'utf-8');
  // Extract the module doc comment as description
  const docMatch = source.match(/^-- \| (.+)/m);
  const description = docMatch ? docMatch[1] : entry.name;

  howtos.push({
    name: entry.name,
    title: entry.name.replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase()),
    description,
    source,
  });
}

howtos.sort((a, b) => a.name.localeCompare(b.name));

const escapeHtml = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

const sections = howtos.map(h => `
    <section class="howto" id="${h.name}">
      <div class="howto-header">
        <h2>${h.title}</h2>
        <p class="howto-desc">${escapeHtml(h.description)}</p>
        <a href="https://github.com/afcondon/hylograph-howto/tree/main/${h.name}" class="repo-link">View in repo &rarr;</a>
      </div>
      <div class="howto-content">
        <div class="howto-demo">
          <iframe src="${h.name}/index.html" loading="lazy"></iframe>
        </div>
        <div class="howto-source">
          <div class="source-header">
            <span class="source-label">src/Main.purs</span>
            <button class="copy-btn" onclick="copySource(this)">Copy</button>
          </div>
          <pre><code class="language-haskell">${escapeHtml(h.source)}</code></pre>
        </div>
      </div>
    </section>`).join('\n');

const nav = howtos.map(h =>
  `        <a href="#${h.name}">${h.title}</a>`
).join('\n');

const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>How-To Guides - Hylograph</title>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism.min.css" rel="stylesheet" />
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-haskell.min.js"></script>
  <style>
    :root { --bg: #f5f5f5; --card: #fff; --border: #e0e0e0; --text: #333; --muted: #666; --code-bg: #f8f8f6; --code-fg: #333; }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: var(--bg); color: var(--text); line-height: 1.6; }

    .page { max-width: 1200px; margin: 0 auto; padding: 2rem 1.5rem; }
    .back { font-size: 0.85rem; color: #999; text-decoration: none; display: block; margin-bottom: 2rem; }
    .back:hover { color: #333; }

    .page-header { display: flex; align-items: center; gap: 1.25rem; margin-bottom: 0.5rem; }
    .logo-mark { height: 64px; width: auto; }
    h1 { font-size: 1.75rem; font-weight: 300; }
    .subtitle { color: var(--muted); margin-bottom: 2rem; }

    .howto-nav { display: flex; flex-wrap: wrap; gap: 0.5rem; margin-bottom: 2.5rem; }
    .howto-nav a { font-size: 0.8rem; padding: 0.3rem 0.7rem; background: var(--card); border: 1px solid var(--border); border-radius: 4px; text-decoration: none; color: var(--text); font-family: monospace; }
    .howto-nav a:hover { background: #e8e8e8; }

    .howto { margin-bottom: 3rem; }
    .howto-header h2 { font-size: 1.1rem; font-weight: 600; margin-bottom: 0.25rem; }
    .howto-desc { font-size: 0.9rem; color: var(--muted); margin-bottom: 0.5rem; }
    .repo-link { font-size: 0.8rem; color: #2563eb; text-decoration: none; }
    .repo-link:hover { text-decoration: underline; }

    .howto-content { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-top: 1rem; }

    .howto-demo { background: var(--card); border: 1px solid var(--border); border-radius: 6px; overflow: hidden; min-height: 300px; }
    .howto-demo iframe { width: 100%; height: 100%; min-height: 300px; border: none; }

    .howto-source { background: var(--code-bg); border: 1px solid var(--border); border-radius: 6px; overflow: hidden; display: flex; flex-direction: column; max-height: 400px; }
    .source-header { display: flex; justify-content: space-between; align-items: center; padding: 0.5rem 1rem 0; }
    .source-label { font-size: 0.65rem; text-transform: uppercase; letter-spacing: 0.1em; color: #999; }
    .copy-btn { font-size: 0.65rem; color: #999; background: none; border: 1px solid #ddd; border-radius: 3px; padding: 2px 8px; cursor: pointer; font-family: system-ui, sans-serif; }
    .copy-btn:hover { color: #333; border-color: #999; }
    .copy-btn.copied { color: #16653e; border-color: #16653e; }
    .howto-source pre { flex: 1; overflow: auto; padding: 0.5rem 1rem 1rem; margin: 0; }
    .howto-source code { font-family: 'SF Mono', 'Fira Code', monospace; font-size: 0.78rem; line-height: 1.5; color: var(--code-fg); }
    .howto-source code[class*="language-"] { background: none; }
    .howto-source .token.keyword { color: #7c3aed; }
    .howto-source .token.string { color: #b45309; }
    .howto-source .token.number { color: #0369a1; }
    .howto-source .token.comment { color: #999; font-style: italic; }
    .howto-source .token.operator { color: #888; }
    .howto-source .token.punctuation { color: #999; }
    .howto-source .token.class-name { color: #16653e; }
    .howto-source .token.title { color: #1a1a1a; font-weight: 600; }

    .bookmark { position: fixed; left: 0; top: 0; bottom: 0; width: 64px; z-index: 10; pointer-events: none; }
    .bookmark img { width: 100%; height: 100%; object-fit: cover; }
    @media (max-width: 900px) { .bookmark { display: none; } .howto-content { grid-template-columns: 1fr; } }
  </style>
</head>
<body>
  <div class="bookmark"><img src="../images/howto.jpeg" alt=""></div>
  <main class="page">
    <a href="../" class="back">&larr; Hylograph</a>
    <div class="page-header">
      <img src="../images/logo.png" alt="Hylograph" class="logo-mark">
      <h1>How-To Guides</h1>
    </div>
    <p class="subtitle">Self-contained examples. Each one builds from a fresh clone. Demo on the left, source on the right.</p>

    <nav class="howto-nav">
${nav}
    </nav>

${sections}
  </main>
  <script>
    function copySource(btn) {
      const code = btn.closest('.howto-source').querySelector('code');
      navigator.clipboard.writeText(code.textContent).then(() => {
        btn.textContent = 'Copied!';
        btn.classList.add('copied');
        setTimeout(() => { btn.textContent = 'Copy'; btn.classList.remove('copied'); }, 1500);
      });
    }
  </script>
</body>
</html>`;

writeFileSync(join(siteDir, 'index.html'), html);
console.log(`Generated ${howtos.length} how-to sections`);
