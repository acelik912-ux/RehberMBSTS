# Uygulama içeriğinden (assets/content) okunaklı PDF çalışma kitabı üretir.
# Kullanım: python3 tool/pdf/build_pdf.py /çıktı/klasörü
import asyncio, html, json, re, sys, pathlib
from playwright.async_api import async_playwright
ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else '.')
C = ROOT / 'assets/content'
AREAS = [  # sınavdaki ağırlığa göre sıra
 ('fikih', 'Fıkıh', 20, '#3F7A3A'), ('hadis', 'Hadis', 7, '#2B4C7E'), ('kelam', 'Kelam', 7, '#7A4E9A'),
 ('kuran', "Kur'an-ı Kerim bilgisi", 7, '#0F5C63'), ('tefsir', 'Tefsir', 7, '#C4632B'), ('siyer', 'Siyer ve İslam tarihi', 7, '#8A6D1C'),
 ('mezhep', 'Mezhepler tarihi', 3, '#A8402F'), ('dinler', 'Dinler tarihi', 2, '#4A5568')]
AREA = {a[0]: a for a in AREAS}
entries = {}
for f in ['hadis', 'kelam', 'fikih', 'kuran', 'siyer']:
    for e in json.loads((C / f'{f}.json').read_text(encoding='utf-8')):
        entries[e['id']] = e
questions = json.loads((C / 'sorular.json').read_text(encoding='utf-8'))
if isinstance(questions, dict): questions = questions.get('questions', [])
LINK = re.compile(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]')

def inline(t):
    t = html.escape(t, quote=False)
    def lk(m):
        tgt, lab = m.group(1), m.group(2)
        if tgt.startswith('http'): return html.escape(lab or tgt)
        e = entries.get(tgt)
        lab = lab or (e['t'] if e else tgt)
        return f'<a class="ln" href="#{tgt}">{lab}</a>' if e else lab
    t = LINK.sub(lk, t.replace('&#x27;', "'"))
    t = re.sub(r'https?://\S+', '', t)
    t = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', t)
    return t

shown_img = {}
def body(e):
    out, ul = [], False
    def close():
        nonlocal ul
        if ul: out.append('</ul>'); ul = False
    for raw in e.get('b', '').split('\n'):
        l = raw.strip()
        if not l: close(); continue
        if l.startswith('- '):
            if not ul: out.append('<ul>'); ul = True
            out.append(f'<li>{inline(l[2:])}</li>'); continue
        close()
        if l.startswith('## '): out.append(f'<h4>{inline(l[3:])}</h4>')
        elif l.startswith('> '): out.append(f'<div class="box tip"><span>💡 İpucu</span>{inline(l[2:])}</div>')
        elif l.startswith('!! '): out.append(f'<div class="box warn"><span>⚠️ Dikkat</span>{inline(l[3:])}</div>')
        elif l.startswith('%% '): out.append(f'<div class="box code"><span>🧠 Akılda tut</span>{inline(l[3:])}</div>')
        elif l.startswith('&& '):
            em, _, tx = l[3:].partition(' | ')
            out.append(f'<div class="box scene"><span>🎬 Sahne {em}</span>{inline(tx)}</div>')
        elif re.match(r'^\d+\. ', l): out.append(f'<p class="num">{inline(l)}</p>')
        else: out.append(f'<p>{inline(l)}</p>')
    close()
    for img in e.get('img', []):
        name = img.split('/')[-1]
        if name in shown_img:
            out.append(f'<p class="see">🖼️ Şema: <a class="ln" href="#{shown_img[name]}">{entries[shown_img[name]]["t"]}</a> maddesinde.</p>')
        else:
            shown_img[name] = e['id']
            out.append(f'<figure><img src="{(ROOT / img).as_uri() if img.startswith("assets/") else (ROOT / "assets" / img).as_uri()}"></figure>')
    return '\n'.join(out)

def card(e, color):
    yrs = ''.join(f'<span class="yr">{y}</span>' for y in (e.get('y') or []))
    return f'''<section class="entry" id="{e["id"]}" style="--k:{color}">
<div class="eh"><div class="ic">{e.get("ic","")}</div><div class="et"><h3>{html.escape(e["t"])} {yrs}</h3>
<div class="hint">{inline(e.get("ih",""))}</div></div></div>
{f'<div class="sum">{inline(e["o"])}</div>' if e.get("o") else ''}
{body(e)}</section>'''

parts = []
# ---------- Kapak
dist = ''.join(f'<tr><td><span class="dot" style="background:{c}"></span>{n}</td><td>{q}</td><td>{sum(1 for e in entries.values() if e["a"]==a)}</td></tr>' for a,n,q,c in AREAS)
parts.append(f'''<div class="cover"><div class="cv-top">DİB · MBSTS 2027</div>
<h1>Rehber MBSTS<br><small>Görsel ve kodlu çalışma kitabı</small></h1>
<p class="lead">Sınav: <b>4 Nisan 2027 Pazar</b> · Başvuru: <b>9–17 Şubat 2027</b> (geç başvuru 25 Şubat) · Sonuç: 21 Nisan 2027<br>
<b>60 soru · 90 dakika</b> · Yanlış doğruyu götürmez: <b>hiçbir soruyu boş bırakma</b>.</p>
<table class="dist"><tr><th>Alan</th><th>Soru</th><th>Madde</th></tr>{dist}<tr><th>Toplam</th><th>60</th><th>{len(entries)}</th></tr></table>
<div class="how"><h3>Bu kitap nasıl kullanılır?</h3><ul>
<li>Her madde bir <b>kart</b>: solda küçük resim, yanında <b>görsel ipucu</b>; altta tek cümlelik özet, sonra açıklama.</li>
<li><span class="mini code">🧠 Akılda tut</span> kutuları hafıza kodlarıdır; önce kodu, sonra açılımını ezberle.</li>
<li><span class="mini warn">⚠️ Dikkat</span> kutuları ÖSYM'nin tuzak kurduğu yerlerdir.</li>
<li>Başlıklardaki <span class="yr">2024</span> gibi etiketler o konunun çıktığı sınav yıllarıdır.</li>
<li>Altı çizili mavi kelimeler başka bir maddeye götürür (PDF'te dokununca açılır).</li>
<li>Kitabın sonunda <b>{len(questions)} özgün soru</b> ve cevap anahtarı var. Sorular çıkmış sınav konularından, kendi cümlelerimizle yazılmıştır.</li>
<li>Çalışma sırası önerisi: <b>Fıkıh</b> (sınavın üçte biri) → Hadis → Kelam → Kur'an ve Tefsir → Siyer → Mezhepler → Dinler.</li></ul></div></div>''')
# ---------- İçindekiler
toc = []
for a,n,q,c in AREAS:
    es = [e for e in entries.values() if e['a']==a]
    groups = []
    for e in es:
        if e['g'] not in groups: groups.append(e['g'])
    toc.append(f'<div class="tocA" style="--k:{c}"><a href="#area-{a}"><b>{n}</b></a> <small>({q} soru)</small><div class="tocG">' +
               ' · '.join(f'<a href="#{next(x["id"] for x in es if x["g"]==g)}">{html.escape(g)}</a>' for g in groups) + '</div></div>')
parts.append('<div class="toc"><h2>İçindekiler</h2>' + ''.join(toc) +
             '<div class="tocA"><a href="#sorular"><b>Soru bankası ve cevap anahtarı</b></a></div></div>')
# ---------- Alanlar
for a,n,q,c in AREAS:
    es = [e for e in entries.values() if e['a']==a]
    parts.append(f'<div class="areahead" id="area-{a}" style="--k:{c}"><h2>{n}</h2><p>Sınavda <b>{q}</b> soru · {len(es)} madde</p></div>')
    g0 = None
    for e in es:
        if e['g'] != g0:
            g0 = e['g']; parts.append(f'<h2 class="grp" style="--k:{c}">{html.escape(g0)}</h2>')
        parts.append(card(e, c))
# ---------- Sorular
L = 'ABCDE'
parts.append('<div class="areahead" id="sorular" style="--k:#1d2433"><h2>Soru bankası</h2><p>Önce çöz, sonra her alanın sonundaki cevap anahtarına bak.</p></div>')
n = 0
for a,nm,q,c in AREAS:
    qs = [x for x in questions if x['a']==a]
    if not qs: continue
    parts.append(f'<h2 class="grp" style="--k:{c}">{nm} · {len(qs)} soru</h2>')
    keys = []
    for x in qs:
        n += 1
        opts = ''.join(f'<div>{L[i]}) {inline(o)}</div>' for i,o in enumerate(x['s']))
        qtext = '<br>'.join(inline(t) for t in x['q'].split('\n'))
        parts.append(f'<div class="q" style="--k:{c}"><b>{n}.</b> {qtext}<div class="opts">{opts}</div></div>')
        keys.append(f'<div><b>{n}. {L[x["c"]]}</b> — {inline(x.get("x",""))}</div>')
    parts.append(f'<div class="key" style="--k:{c}"><h4>Cevap anahtarı · {nm}</h4>{"".join(keys)}</div>')

CSS = '''
@page{size:A4;margin:16mm 13mm 16mm 13mm}
body{font-family:'DejaVu Sans',sans-serif;font-size:10.3pt;color:#1d2433;line-height:1.45}
a{color:inherit;text-decoration:none}.ln{color:#2b4c7e;border-bottom:1px solid #9fb3d6}
.cover{page-break-after:always;padding-top:20mm}.cv-top{font-weight:800;color:#0f5c63;letter-spacing:2px}
.cover h1{font-size:34pt;margin:6mm 0;color:#0f5c63;line-height:1.1}.cover h1 small{display:block;font-size:15pt;color:#555;font-weight:600}
.lead{font-size:11pt;background:#eef4f4;padding:10px 14px;border-radius:10px}
.dist{border-collapse:collapse;width:100%;margin:6mm 0}.dist td,.dist th{border-bottom:1px solid #ddd;padding:5px 8px;text-align:left}
.dist th{background:#0f5c63;color:#fff}.dot{display:inline-block;width:10px;height:10px;border-radius:50%;margin-right:8px}
.how{background:#fff8e6;border:1.5px solid #e2c26b;border-radius:12px;padding:6px 16px}.how li{margin:3px 0}
.mini{font-size:9pt;font-weight:700;padding:1px 6px;border-radius:6px}
.toc{page-break-after:always}.toc h2{color:#0f5c63}.tocA{border-left:5px solid var(--k,#333);padding:4px 10px;margin:7px 0;break-inside:avoid}
.tocG{font-size:9pt;color:#555}
.areahead{page-break-before:always;background:var(--k);color:#fff;border-radius:14px;padding:16px 20px;margin-bottom:8px}
.areahead h2{margin:0;font-size:24pt}.areahead p{margin:4px 0 0}
h2.grp{color:var(--k);border-bottom:2.5px solid var(--k);font-size:14pt;margin:14px 0 6px;padding-bottom:3px;break-after:avoid}
.entry{border:1.5px solid #d7dbe4;border-left:6px solid var(--k);border-radius:10px;padding:8px 12px;margin:8px 0}
.eh{display:flex;gap:10px;align-items:center;break-inside:avoid;break-after:avoid}
.ic{font-size:24pt;width:44px;height:44px;display:flex;align-items:center;justify-content:center;border-radius:10px;background:#f2f4f8;flex:0 0 44px}
h3{margin:0;font-size:13pt;color:var(--k)}.hint{font-weight:700;font-size:10pt}
.yr{display:inline-block;font-size:7.5pt;font-weight:700;background:#a8402f;color:#fff;border-radius:6px;padding:0 5px;margin-left:3px;vertical-align:middle}
.sum{background:#f3f5f9;border-radius:8px;padding:6px 10px;margin:6px 0;font-style:italic;break-inside:avoid}
h4{margin:8px 0 2px;color:var(--k);font-size:10.8pt;break-after:avoid}
p{margin:3px 0}ul{margin:3px 0 3px 0;padding-left:18px}li{margin:1px 0}
.box{border-radius:8px;padding:5px 10px;margin:5px 0;break-inside:avoid}.box span{font-weight:800;margin-right:6px}
.tip,.mini.tip{background:#e9f0fb}.warn,.mini.warn{background:#fdecea}.code,.mini.code{background:#fff6db}
.code{border:1.5px dashed #c79a1e}
.scene{background:#f1ebfa;border-left:4px solid #7a4e9a}
figure{margin:6px 0;text-align:center;break-inside:avoid}figure img{max-width:100%;max-height:235mm;border-radius:8px}
.see{color:#666;font-size:9pt}
.q{break-inside:avoid;margin:7px 0;padding:6px 10px;border-left:4px solid var(--k);background:#fafbfd}
.opts{margin-top:3px;padding-left:10px}.opts div{margin:1px 0}
.key{break-inside:auto;background:#f7f7f2;border-radius:10px;padding:6px 12px;margin:8px 0 14px;font-size:9.2pt}
.key h4{margin:2px 0 6px}.key div{margin:2px 0;break-inside:avoid}
'''
doc = f'<!doctype html><html lang="tr"><head><meta charset="utf-8"><style>{CSS}</style></head><body>{"".join(parts)}</body></html>'
OUT.mkdir(parents=True, exist_ok=True)
(OUT / 'rehber_mbsts.html').write_text(doc, encoding='utf-8')

async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path='/usr/bin/google-chrome')
        pg = await b.new_page()
        await pg.goto((OUT / 'rehber_mbsts.html').as_uri())
        await pg.wait_for_load_state('networkidle')
        await pg.pdf(path=str(OUT / 'Rehber_MBSTS_Calisma_Kitabi.pdf'), format='A4', print_background=True,
                     margin={'top': '16mm', 'bottom': '16mm', 'left': '13mm', 'right': '13mm'},
                     display_header_footer=True,
                     header_template='<div style="font-size:7pt;width:100%;text-align:right;padding-right:13mm;color:#999">Rehber MBSTS · çalışma kitabı</div>',
                     footer_template='<div style="font-size:8pt;width:100%;text-align:center;color:#777"><span class="pageNumber"></span> / <span class="totalPages"></span></div>')
        await b.close()
asyncio.run(main())
print('ok', len(entries), 'madde', len(questions), 'soru')
