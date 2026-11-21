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

def blocks(c, only=None):
    out = ''
    for i, (k, o) in enumerate([('bs', 'bo'), ('en', 'eo'), ('ar', 'ao')]):
        if only is not None and only != i: continue
        rtl = i == 2
        st = 'font-size:23px;direction:rtl;text-align:right;line-height:1.9' if rtl else 'font-size:14.5px;font-weight:800'
        out += (f'<div class="lb l{i}"><span class="fl">{FL[i]}</span><div style="flex:1;text-align:{"right" if rtl else "left"}"><div style="{st}">{c[k]}</div>'
                f'<div class="rd">🔊 {c[o]}</div></div><span class="sp">🔊</span></div>')
    return out

def phrase_card(c, n=None, photo=False):
    num = f'<span class="num">{n}</span>' if n else ''
    ph = '<div class="addp">🖼️ Kendi resmini ekle</div>' if photo else ''
    return (f'<div class="card"><div class="row"><span>{num}<span class="em">{c["e"]}</span></span><span class="sp">▶️</span></div>'
            f'<div class="tr">{c["t"]}</div>{blocks(c)}{('<div class="hook">🎬 ' + c["k"] + '</div>') if c["k"] else ''}{ph}</div>')

G = {g['id']: g for g in dil['g']}
NW = sum(len(g['c']) for g in dil['g'])
FL = ['🇧🇦', '🇬🇧', '🇸🇦']
screens = []
screens.append(phone('Rehber MBSTS', '''
<div class="cd">📅 4 Nisan 2027 sınavına <b>134 gün</b></div>
<div class="acts"><div class="a" style="background:#c4302b">🃏<b>Tekrar</b><i>12 kart</i></div><div class="a" style="background:#2b6e4a">📝<b>Test</b></div><div class="a" style="background:#555">📒<b>Defterim</b></div></div>
<div class="acts"><div class="a" style="background:#7a4e9a">🙈<b>Kapalı şema</b><i>terimi kapat, hatırla</i></div><div class="a" style="background:#2b4c7e">🕌<b>Cami sarayı</b><i>10 durak, hep aynı rota</i></div></div>
<div class="a wide" style="background:#b8860b">🌍<b>Dil bölümü</b><i>Boşnakça · İngilizce · Arapça cümleler, görsel kancalarla</i></div>
<div class="sec">Alanlar</div><div class="grid"><div>📿 Fıkıh</div><div>📖 Hadis</div><div>☪️ Kelam</div><div>📚 Kur'an</div></div>'''))
def gl(gid):
    g = G[gid]; return f'<div class="li"><span style="font-size:26px">{g["ic"]}</span><div><b>{g["t"]}</b><br><small>{len(g["c"])} {"sahne" if g["b"]=="A" else "kalıp" if g["b"]=="K" else "kelime"} · 0 bildim</small></div><span>›</span></div>'
screens.append(phone('Dil bölümü', '<p class="note">🇧🇦 Boşnakça · 🇬🇧 İngilizce · 🇸🇦 Arapça — her satır üç dil alt alta.</p><div class="two"><div class="btn">📡 Tanı testi</div><div class="btn o">🗺️ Eksik haritası</div></div><div class="btn o" style="margin-top:0">🔁 Dil tekrarı · bugün 20 kart</div><b>A · Cümleler (hikâye)</b>' + gl('a1') + '<b>K · Konuşmayı başlatan kalıplar</b>' + gl('k1') + '<b>B · Bağlaç, ek, zamir, fiil</b>' + gl('b2') + '<b>C · Günlük kelime havuzu</b>' + gl('c-yiyecek')))
a1 = G['a1']['c']
screens.append(phone('🛬 Saraybosna\'ya iniş · Gez', '<div class="seg"><b>Gez</b><span>Sına</span></div><div class="story">🛬 ' + G['a1']['s'] + '</div>' + phrase_card(a1[0], 1) + '<div style="text-align:center">⬇️</div>' + phrase_card(a1[1], 2)))
a5 = G['a5']['c']
screens.append(phone('🕌 Camide ve dualarda', '<div class="seg"><b>Gez</b><span>Sına</span></div>' + phrase_card(a5[1], 2, photo=True) + '<div style="text-align:center">⬇️</div>' + phrase_card(a5[3], 4)))
b1 = G['b1']['c']; b2 = G['b2']['c']
screens.append(phone('🔗 Bağlaçlar · 🧩 Ekler', '<div class="seg"><b>Gez</b><span>Sına</span></div>' + phrase_card(b1[2]) + phrase_card(b2[2])))
c = a1[2]
screens.append(phone('Sına', f'''<div class="seg"><span>Gez</span><b>Sına</b></div><div class="chips"><u>Karıştır</u><u>Yalnız bilemediklerim</u><u><b>Üçü</b></u><u>🇧🇦</u><u>🇬🇧</u><u>🇸🇦</u></div>
<small>3 / 6</small><div style="text-align:center;font-size:52px">{c["e"]}</div><div style="text-align:center;font-size:19px;font-weight:800">{c["t"]}</div>
<p class="note" style="text-align:center">Önce kendin söyle (sahneyi gözünün önüne getir).</p><div class="btn">👁️ Cevabı göster</div>{blocks(c)}<div class="two"><div class="btn o">Bilemedim</div><div class="btn">Bildim</div></div>'''))
screens.append(phone('Resim ekle (her yerde)', f'''<div class="card"><div class="row"><span class="em">{a1[1]["e"]}</span></div><div class="tr">{a1[1]["t"]}</div>
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

cy = G['c-yiyecek']['c']
cs = G['c-fiil1']['c']
tani = cs[0]
screens.append(phone('Tanı testi', f'''<small>7 / 30</small><div style="text-align:center;font-size:56px">{tani["e"]}</div><div style="text-align:center;font-size:21px;font-weight:800">{tani["t"]}</div><p class="note" style="text-align:center">Üç dilde söylemeyi dene.</p>{blocks(tani)}<p><b>Bilmediklerine dokun (kırmızı olur):</b></p><div class="chips"><u>🇧🇦 Boşnakça</u><u style="background:#f3c9c2">🇬🇧 İngilizce</u><u style="background:#f3c9c2">🇸🇦 Arapça</u></div><div class="btn">Sonraki</div>'''))
def bar(k, u, n):
    t = k + u + n
    return f'<div style="display:flex;height:10px;border-radius:5px;overflow:hidden;flex:1"><i style="flex:{k};background:#3f7a3a"></i><i style="flex:{u};background:#b3402f"></i><i style="flex:{n};background:#ddd"></i></div>'
rows = [('🔢 Sayılar', 14, 3, 3), ('⏰ Zaman', 12, 4, 4), ('🍽️ Yiyecekler', 18, 5, 2), ('🏃 Fiiller 1', 9, 10, 6), ('🕌 Din', 13, 3, 2), ('🛍️ Para', 6, 8, 3)]
hm = ''
for fl, nm, mul in [('🇧🇦 Boşnakça', 0, 1), ('🇬🇧 İngilizce', 1, 0), ('🇸🇦 Arapça', 2, 2)]:
    hm += f'<b style="display:block;margin-top:8px">{fl}: 74 bildim · 38 eksik · 410 taranmadı</b>'
    for r, (t, k, u, n) in enumerate(rows):
        kk, uu, nn = max(k - mul * 2, 1), u + mul * 2, n
        hm += f'<div style="display:flex;gap:6px;align-items:center;margin-top:5px"><span style="width:92px;font-size:10px">{t}</span>{bar(kk, uu, nn)}</div>'
screens.append(phone('Eksik haritası', '<small>🟢 biliyorum · 🔴 bilmiyorum · ⚪ taranmadı</small>' + hm))
tk = cs[11]
screens.append(phone('Dil tekrarı', f'''<small>3 / 20 · kutu 1</small><div style="text-align:center;font-size:54px">{tk["e"]}</div><div style="text-align:center;font-size:21px;font-weight:800">{tk["t"]}</div><p style="text-align:center">🇸🇦 Arapça nasıl denir?</p><div class="btn">👁️ Cevabı göster</div>{blocks(tk, 2)}<div class="two"><div class="btn o">Bilemedim</div><div class="btn">Bildim</div></div><p class="note">Bilemediğin hemen yarın; bildikçe 1 → 3 → 7 → 21 → 45 gün aralıkla geri gelir.</p>'''))
screens.append(phone('🍽️ Yiyecekler · kelime kartı', '<div class="seg"><b>Gez</b><span>Sına</span></div>' + ''.join(phrase_card(x) for x in [cy[17], cy[23]])))
tn = G['c-tanidik']['c']
k1 = G['k1']['c']
screens.append(phone('🎁 Tanıdık · 🆘 Kalıplar', '<div class="seg"><b>Gez</b><span>Sına</span></div>' + phrase_card(tn[0]) + phrase_card(k1[0])))

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
.lb{display:flex;align-items:flex-start;gap:6px;border-radius:8px;padding:5px 7px;margin-top:5px}.l0{background:#2b5fa81a}.l1{background:#b3402f1a}.l2{background:#3f7a3a1a}.fl{font-size:17px}.num{display:inline-block;width:20px;height:20px;border-radius:10px;background:#7a4e9a;color:#fff;text-align:center;font-size:11px;line-height:20px;margin-right:6px}.story{background:#fff3cd;border-radius:8px;padding:7px;font-size:11.5px;margin-bottom:6px}.opt{border:1px solid #999;border-radius:8px;padding:8px;margin:5px 0;background:#fff}.opt.ok{background:#dcebd8}'''
caps = [
 ('Dil bölümü: kalıplar, tanı ve eksik haritası', f'Toplam {NW} satır: 30 hikâyeli cümle, 26 kurtarıcı kalıp, 78 dil bilgisi kelimesi, {NW-134} günlük kelime. Önce tanı testiyle eksiklerin bulunur. (Eksik haritasındaki sayılar örnektir.)', [1, 12, 13]),
 ('Dil tekrarı, kelime kartı, tanıdık kelimeler', 'Bilemediklerin aralıklı tekrar kartı olur. Her kelime üç dilde alt alta, emoji ve kanca ile.', [14, 15, 16]),
 ('Hikâye, sına ve resim ekleme', 'A bölümü hikâye sırasıyla, sına modunda tek dil seçilebilir; resim düğmesi her satırda.', [2, 5, 6]),
 ('Ana sayfa, kapalı şema, cami sarayı', 'Önceki sürümlerden gelen ekranlar.', [0, 7, 8]),
 ('Görselden soru, fıkıh sahnesi, sayı şekilleri', 'Önceki sürümlerden gelen ekranlar.', [10, 9, 11]),
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
