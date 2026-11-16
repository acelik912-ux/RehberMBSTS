# Şemaları PNG'ye çevirir ve kapalı şema kutularının yerlerini çıkarır.
# Kullanım: python3 tool/gorsel/render.py            -> maskeler.py'deki bütün şemalar
#           python3 tool/gorsel/render.py ad1 ad2    -> yalnız bu şemaların PNG'si (maske dosyası yine baştan yazılır)
import asyncio, json, sys, pathlib
from playwright.async_api import async_playwright
from PIL import Image
sys.path.insert(0, str(pathlib.Path(__file__).parent))
from maskeler import SEMALAR
root = pathlib.Path(__file__).resolve().parents[2]

JS = r"""
([specs, hintSel]) => {
  const g = document.querySelector('#g');
  const gb = g.getBoundingClientRect();
  const norm = r => [(r.left - gb.left) / gb.width, (r.top - gb.top) / gb.height, r.width / gb.width, r.height / gb.height].map(v => +v.toFixed(4));
  const hintEls = hintSel ? [...g.querySelectorAll(hintSel)] : [];
  const inHint = n => hintEls.some(h => h.contains(n));
  const nodes = [];
  const w = document.createTreeWalker(g, NodeFilter.SHOW_TEXT);
  let n; while ((n = w.nextNode())) { if (!inHint(n) && !n.parentElement.closest('style,script')) nodes.push(n); }
  const used = [];
  const out = [];
  for (const sp of specs) {
    if (sp.sel) {
      [...g.querySelectorAll(sp.sel)].forEach((el, i) => out.push({
        t: el.innerText.replace(/\s+/g, ' ').trim().slice(0, 260), e: (sp.entries || [])[i] || '', r: [norm(el.getBoundingClientRect())]}));
      continue;
    }
    const rects = [];
    for (const node of nodes) {
      const txt = node.textContent;
      if (sp.exact && txt.trim() !== sp.text) continue;
      let from = 0;
      while (true) {
        const i = txt.indexOf(sp.text, from);
        if (i < 0) break;
        const end = i + sp.text.length;
        from = end;
        if (used.some(u => u.n === node && i < u.e && end > u.s)) continue;
        const rg = document.createRange(); rg.setStart(node, i); rg.setEnd(node, end);
        for (const cr of rg.getClientRects()) if (cr.width > 1 && cr.height > 1) rects.push(norm(cr));
        used.push({n: node, s: i, e: end});
      }
    }
    if (!rects.length) throw new Error('maske bulunamadı: ' + sp.text);
    out.push({t: sp.label || sp.text, e: sp.e || '', r: rects});
  }
  return {asp: +(gb.width / gb.height).toFixed(4), m: out, h: hintEls.map(h => norm(h.getBoundingClientRect()))};
}
"""

def specs(m):
    out = []
    for x in m:
        if isinstance(x, dict):
            out.append(x)
        else:
            text = x[0]
            exact = text.startswith('=')
            out.append({'text': text[1:] if exact else text, 'exact': exact, 'e': x[1], 'label': x[2] if len(x) > 2 else None})
    return out

async def main(only):
    data = {}
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path='/usr/bin/google-chrome')
        pg = await b.new_page(viewport={'width': 800, 'height': 1200}, device_scale_factor=2)
        for name, sp in SEMALAR.items():
            await pg.goto((root / f'tool/gorsel/{name}.html').as_uri())
            out = root / f'assets/sema/{name}.png'
            if not only or name in only or not out.exists():
                await pg.locator('#g').screenshot(path=str(out))
                Image.open(out).convert('RGB').quantize(colors=256, method=Image.Quantize.MEDIANCUT).save(out, optimize=True)
                print(name, out.stat().st_size // 1024, 'KB')
            r = await pg.evaluate(JS, [specs(sp['m']), sp.get('hint', '')])
            data[name] = {'t': sp['t'], 'a': sp['a'], **r}
            print('  ', name, len(r['m']), 'kutu,', len(r['h']), 'ipucu')
        await b.close()
    (root / 'assets/content/maskeler.json').write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')

asyncio.run(main(set(sys.argv[1:])))
