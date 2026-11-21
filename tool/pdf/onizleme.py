# Yeni ekranların telefon çerçeveli önizleme PDF'i (APK indirmeden bakmak için).
# Kullanım: python3 tool/pdf/onizleme.py /home/claude/out
import asyncio, base64, json, pathlib, sys
from playwright.async_api import async_playwright

root = pathlib.Path(__file__).resolve().parents[2]
out = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else '/home/claude/out'); out.mkdir(parents=True, exist_ok=True)
dil = json.load(open(root / 'assets/content/dil.json', encoding='utf-8'))
mask = json.load(open(root / 'assets/content/maskeler.json', encoding='utf-8'))

def b64(name):
    return 'data:image/png;base64,' + base64.b64encode((root / 'assets/sema' / f'{name}.png').read_bytes()).decode()

def phone(title, body, extra=''):
    return f'<div class="ph"><div class="bar">{title}</div><div class="scr">{body}</div>{extra}</div>'

def phrase_card(c, rtl=False, photo=True):
    sz = 'font-size:26px;direction:rtl;text-align:right' if rtl else 'font-size:21px'
    ph = '<div class="addp">🖼️ Kendi resmini ekle</div>' if photo else ''
    return (f'<div class="card"><div class="row"><span class="em">{c["e"]}</span><span class="sp">🔊</span></div>'
            f'<div class="nat" style="{sz}">{c["n"]}</div><div class="rd">🔊 {c["o"]}</div><div class="tr">{c["t"]}</div>'
            f'<div class="hook">💡 {c["k"]}</div>{ph}</div>')

bs, en, ar = dil
screens = []
screens.append(phone('Rehber MBSTS', '''
<div class="cd">📅 4 Nisan 2027 sınavına <b>134 gün</b></div>
<div class="acts"><div class="a" style="background:#c4302b">🃏<b>Tekrar</b><i>12 kart</i></div><div class="a" style="background:#2b6e4a">📝<b>Test</b></div><div class="a" style="background:#555">📒<b>Defterim</b></div></div>
<div class="acts"><div class="a" style="background:#7a4e9a">🙈<b>Kapalı şema</b><i>terimi kapat, hatırla</i></div><div class="a" style="background:#2b4c7e">🕌<b>Cami sarayı</b><i>10 durak, hep aynı rota</i></div></div>
<div class="a wide" style="background:#b8860b">🌍<b>Dil bölümü</b><i>Boşnakça · İngilizce · Arapça cümleler, görsel kancalarla</i></div>
<div class="sec">Alanlar</div><div class="grid"><div>📿 Fıkıh</div><div>📖 Hadis</div><div>☪️ Kelam</div><div>📚 Kur'an</div></div>'''))
screens.append(phone('Dil bölümü', '<p class="note">Her cümlenin görseli, okunuşu ve Türkçe ses benzetmesi (kanca) var. Önce gez, sonra kapatıp sına; hoparlörle doğru söylenişi dinle.</p>' + ''.join(
    f'<div class="li"><span style="font-size:32px">{d["bay"]}</span><div><b>{d["ad"]}</b><br><small>{sum(len(k["c"]) for k in d["k"])} cümle · 0 bildim</small></div><span>›</span></div>' for d in dil)))
screens.append(phone('🇧🇦 Selamlaşma', '<div class="seg"><b>Gez</b><span>Sına</span></div>' + ''.join(phrase_card(c, photo=(i == 1)) for i, c in enumerate(bs['k'][0]['c'][:3]))))
screens.append(phone('🇸🇦 Dua ve dini ifadeler', '<div class="seg"><b>Gez</b><span>Sına</span></div>' + ''.join(phrase_card(c, rtl=True, photo=False) for c in ar['k'][2]['c'][:3])))
c = en['k'][1]['c'][1]
screens.append(phone('🇬🇧 Tanışma · Sına', f'''<div class="seg"><span>Gez</span><b>Sına</b></div><div class="chips"><u>Yalnız bilemediklerim</u><u>Cümle → Türkçe</u></div>
<small>2 / 8</small><div style="text-align:center;font-size:56px">{c["e"]}</div><div style="text-align:center;font-size:20px;font-weight:800">{c["t"]}</div>
<p class="note" style="text-align:center">Bunu hedef dilde söyle (gözünün önüne sahneyi getir).</p><div class="btn">👁️ Cevabı göster</div>
<div style="text-align:center;font-size:24px;font-weight:800;color:#7a4e9a;margin-top:10px">{c["n"]}</div><div style="text-align:center">🔊 {c["o"]}</div>
<div class="hook">💡 {c["k"]}</div><div class="two"><div class="btn o">Bilemedim</div><div class="btn">Bildim</div></div>'''))
screens.append(phone('Resim ekle (her yerde)', '''<div class="card"><div class="row"><span class="em">🙏</span><span class="sp">🔊</span></div><div class="nat">Molim</div><div class="tr">Lütfen / rica ederim</div>
<div class="thumbs"><i>🖼️</i><i>📷</i></div><div class="addp">🖼️ Kendi resmini ekle (2)</div></div>
<div class="sheet"><div>🖼️ Telefondan seç (galeri)</div><div>📷 Kamerayla çek</div><div>⌨️ Klavyeden ekle (resim / çıkartma / pano)</div></div>
<div class="dlg"><b>Klavyeden resim ekle</b><small>Kutuya dokun, klavyenin resim / çıkartma / GIF düğmesinden seç. Panodaki resmi basılı tutup yapıştır.</small><div class="inp">Resmi buraya gönder…</div><small><b>1 resim eklendi.</b></small></div>'''))
mb = mask['hadis_kopukluk']
ov = ''
for i, b in enumerate(mb['m']):
    for r in b['r']:
        ov += f'<div class="mk{" cur" if i==1 else ""}" style="left:{(r[0]-.004)*100}%;top:{(r[1]-.004)*100}%;width:{(r[2]+.008)*100}%;height:{(r[3]+.008)*100}%"></div>'
screens.append(phone('Kapalı şema', f'<div class="img"><img src="{b64("hadis_kopukluk")}">{ov}</div><div class="card"><small>Kutu 2 / {len(mb["m"])} · bildim 1 · bilemedim 0</small><b>Sarı çerçeveli kutuda ne yazıyor? Aklından söyle.</b><div class="btn">👁️ Kutuyu aç</div><div class="two"><div class="btn o">Bilemedim</div><div class="btn">Bildim</div></div></div>'))
screens.append(phone('Cami hafıza sarayı', f'<p class="note">Her listeyi aynı camiye yerleştiriyoruz: minareden kubbeye hep aynı 10 durak.</p><img class="w" src="{b64("saray_rota")}"><div class="chips">' + ''.join(f'<u>{x}</u>' for x in ['1 🗼 Minare','2 🚪 Avlu kapısı','3 ⛲ Şadırvan','4 🏛️ Son cemaat yeri','5 👟 Ayakkabılık']) + '<u>…</u></div><div class="li"><span style="font-size:26px">🏹</span><div><b>Gazveler</b><br><small>Siyer · 10 durak · 3 bildim</small></div><span>›</span></div>'))
screens.append(phone('Vâcip (fıkıh) · sahne', '''<div class="scene"><small>🎬 SAHNE</small><div style="font-size:28px">🌙🥁💰🐏</div>Gökte bir hilal: bir ucunda vitir tespihi, öbür ucunda bayram davulu asılı; altında boynunda sadaka kesesiyle bir koç yürüyor. Hilal güneş (farz) kadar kesin parlamıyor ama "mutlaka yap" diyor.</div>
<p>Mezhep renk kodu: <b style="color:#2b5fa8">🔵Hanefî</b> · <b style="color:#3f7a3a">🟢Mâlikî</b> · <b style="color:#b8860b">🟡Şâfiî</b> · <b style="color:#b3402f">🔴Hanbelî</b></p>
<p>Vâcibi <b style="color:#2b5fa8">🔵Hanefî</b> mezhebi farzdan ayırır; <b style="color:#b8860b">🟡Şâfiî</b> ve <b style="color:#3f7a3a">🟢Mâlikî</b>de karşılığı yok.</p><div class="addp">🖼️ Resim ekle</div>'''))
ov0 = ''.join(f'<div class="mk cur" style="left:{(r[0]-.004)*100}%;top:{(r[1]-.004)*100}%;width:{(r[2]+.008)*100}%;height:{(r[3]+.008)*100}%"></div>' for r in mb['m'][0]['r'])
screens.append(phone('Görselden soru', f'<small>Soru 3 / 10 · {mb["t"]}</small><div class="img"><img src="{b64("hadis_kopukluk")}">{ov0}</div><b>Sarı çerçeveli kapalı kutuda ne yazıyordu?</b><div class="opt">Sahih li-ğayrihî</div><div class="opt ok">✔ {mb["m"][0]["t"]}</div><div class="opt">Hasen li-zâtihî</div><div class="opt">Kıraat-i seb\'a</div>'))
screens.append(phone('Sayıları şekle çevir', '''<div class="card"><b>Rakam kancaları (hep aynı)</b><p style="font-size:19px;line-height:1.7">0 🥯 · 1 🕯️ · 2 🦢 · 3 🔺 · 4 ⛵ · 5 🖐️ · 6 🍒 · 7 🌈 · 8 ⛄ · 9 🎈 · 10 🎳</p></div>
<div class="scene"><small>🎬 SAHNE</small><div style="font-size:26px">🕯️🥯 + ⛵</div>Vefat iddeti: mumun ve simidin (10 gün) yanında dört yelkenli (4 ay) bekliyor.</div>
<div class="scene"><small>🎬 SAHNE</small><div style="font-size:26px">🌈</div>Hacda yedi renkli gökkuşağının altında hacı yedi tur dönüyor, yedi taş atıyor, yedi kez koşuyor.</div>'''))

css = '''@page{size:A4 landscape;margin:8mm}*{box-sizing:border-box}body{font-family:"Noto Sans","DejaVu Sans",sans-serif;margin:0;background:#fff;color:#222}
h1{font-size:22px;margin:0 0 4px}.cap{font-size:12px;color:#555;margin-bottom:8px}.pg{page-break-after:always;display:flex;gap:14px;justify-content:center}
.ph{width:305px;height:560px;border:6px solid #222;border-radius:26px;overflow:hidden;background:#faf8f4;position:relative;flex:none}
.bar{background:#2b4c7e;color:#fff;padding:9px 12px;font-weight:700;font-size:14px}.scr{padding:9px;font-size:12px;height:510px;overflow:hidden}
.note{font-size:11.5px;line-height:1.4;margin:4px 0}.cd{background:#fff3cd;padding:7px;border-radius:8px;margin-bottom:8px}.acts{display:flex;gap:6px;margin-bottom:6px}
.a{flex:1;color:#fff;border-radius:10px;padding:8px;font-size:11px;display:flex;flex-direction:column;gap:2px}.a i{font-size:9px;opacity:.85}.wide{margin-bottom:8px}
.sec{font-weight:800;margin:6px 0}.grid{display:grid;grid-template-columns:1fr 1fr;gap:6px}.grid div{background:#fff;border:1px solid #ddd;padding:12px;border-radius:8px}
.li{display:flex;align-items:center;gap:10px;background:#fff;border:1px solid #ddd;border-radius:10px;padding:10px;margin:7px 0}.li div{flex:1}
.seg{display:flex;margin-bottom:6px}.seg b,.seg span{flex:1;text-align:center;padding:5px;border:1px solid #999}.seg b{background:#e8dff0}
.card{background:#fff;border:1px solid #ddd;border-radius:10px;padding:9px;margin:6px 0}.row{display:flex;justify-content:space-between}.em{font-size:28px}.sp{font-size:18px}
.nat{font-weight:800;margin:2px 0}.rd{color:#7a4e9a;font-weight:600;font-size:12px}.tr{font-weight:700;font-size:13px;margin:2px 0}
.hook{background:#fff6d6;border-radius:6px;padding:6px;font-size:11px;margin-top:5px}.addp{color:#2b4c7e;font-size:11.5px;margin-top:5px}
.chips{display:flex;flex-wrap:wrap;gap:4px;margin:6px 0}.chips u{text-decoration:none;border:1px solid #bbb;border-radius:12px;padding:3px 7px;font-size:10.5px;background:#fff}
.btn{background:#7a4e9a;color:#fff;text-align:center;padding:8px;border-radius:18px;margin:6px 0;font-weight:700}.btn.o{background:#fff;color:#7a4e9a;border:1px solid #7a4e9a}.two{display:flex;gap:6px}.two .btn{flex:1}
.thumbs{display:flex;gap:6px;margin-top:6px}.thumbs i{width:54px;height:54px;background:#e5e5e5;border-radius:8px;display:flex;align-items:center;justify-content:center;font-style:normal;font-size:22px}
.sheet{position:absolute;left:0;right:0;bottom:0;background:#fff;box-shadow:0 -4px 14px #0003;padding:6px 12px;border-radius:14px 14px 0 0}.sheet div{padding:9px 0;border-bottom:1px solid #eee;font-size:12.5px}
.dlg{position:absolute;left:14px;right:14px;top:215px;background:#fff;border-radius:14px;box-shadow:0 6px 24px #0005;padding:12px;display:flex;flex-direction:column;gap:6px}
.inp{border:1px solid #888;border-radius:6px;padding:12px 6px;color:#888}
.img{position:relative}.img img,img.w{width:100%;display:block;border-radius:6px}.mk{position:absolute;background:#7a4e9a;border-radius:2px}.mk.cur{border:2px solid #ffc83d}
.scene{background:#f1ebfa;border-left:4px solid #7a4e9a;padding:8px;border-radius:0 8px 8px 0;margin:7px 0;font-size:12px;line-height:1.4}
.opt{border:1px solid #999;border-radius:8px;padding:8px;margin:5px 0;background:#fff}.opt.ok{background:#dcebd8}'''
caps = [
 ('Ana sayfa ve dil bölümü', 'Ana sayfada yeni düğmeler. Dil bölümünde üç dil, her birinde kategoriler.', [0, 1, 2]),
 ('Arapça, sına ve resim ekleme', 'Arapça sağdan sola yazılır; "Sına" modunda görsel ve Türkçe karşılık gelir, cümleyi sen söylersin. Resim düğmesi her cümlede ve her madde sayfasında var.', [3, 4, 5]),
 ('Kapalı şema, cami sarayı, görselden soru', 'Kapalı şema ve cami sarayı gerçek şema görsellerinden çizildi.', [6, 7, 9]),
 ('Fıkıh sahneleri, mezhep renkleri, sayı şekilleri', 'Sahne kutusu, mezhep renk kodu ve rakam kancaları.', [8, 10]),
]
html = f'<html><head><meta charset="utf-8"><style>{css}</style></head><body>'
html += '<div class="pg" style="flex-direction:column;align-items:center;justify-content:center;height:190mm"><h1 style="font-size:34px">Rehber MBSTS · Yeni ekranlar önizlemesi</h1><div class="cap" style="font-size:15px;max-width:600px;text-align:center">Bu sayfalar telefon ekranlarının çizimidir, APK değildir. Yazılar, görseller ve düzen uygulamadaki gerçek içerikten üretildi; ufak görünüm farkları olabilir.</div></div>'
for t, c, idx in caps:
    html += f'<div><h1>{t}</h1><div class="cap">{c}</div><div class="pg">' + ''.join(screens[i] for i in idx) + '</div></div>'
html += '</body></html>'
(out / 'onizleme.html').write_text(html, encoding='utf-8')

async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path='/usr/bin/google-chrome', args=['--no-sandbox'])
        pg = await b.new_page()
        await pg.goto('file://' + str(out / 'onizleme.html'))
        await pg.pdf(path=str(out / 'Rehber-MBSTS-yeni-ekranlar.pdf'), format='A4', landscape=True, print_background=True)
        await b.close()
asyncio.run(main())
print('ok')
