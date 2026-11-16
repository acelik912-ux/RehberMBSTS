import pathlib
H=pathlib.Path(__file__).parent
def page(name, body, h='#2b4c7e', hs='#e8eef7'):
    (H/f'{name}.html').write_text(f'''<!doctype html><html><head><meta charset="utf-8"><link rel="stylesheet" href="base.css"><style>:root{{--h:{h};--hs:{hs}}}</style></head><body><div id="g">{body}</div></body></html>''',encoding='utf-8')

# ---------- A. Sened kopukluğu
def chain(labels, cut, mask=None, color='#2b4c7e'):
    # vertical chain svg; labels top->bottom; cut = set of indexes crossed
    h=34*len(labels)+6
    s=f'<svg width="62" height="{h}" viewBox="0 0 62 {h}">'
    for i,l in enumerate(labels):
        y=20+34*i
        if i<len(labels)-1:
            dash=' stroke-dasharray="3,3"' if mask==i else ''
            s+=f'<line x1="31" y1="{y+13}" x2="31" y2="{y+21}" stroke="#666" stroke-width="2"{dash}/>'
        fill='#fde3df' if i in cut else '#fff'
        st='#a8402f' if i in cut else color
        s+=f'<circle cx="31" cy="{y}" r="13" fill="{fill}" stroke="{st}" stroke-width="2.2"/><text x="31" y="{y+4.5}" font-size="12" text-anchor="middle" font-weight="700" fill="{st}">{l}</text>'
        if i in cut:
            s+=f'<line x1="20" y1="{y-11}" x2="42" y2="{y+11}" stroke="#a8402f" stroke-width="2.5"/><line x1="42" y1="{y-11}" x2="20" y2="{y+11}" stroke="#a8402f" stroke-width="2.5"/>'
    return s+'</svg>'
L=['P','S','T','R','R','M']
cards=[
 ('Muallak','#7a4e9a','#f3ecf8',chain(L,{3,4}), 'Senedin <b>başından</b> (müellif tarafından) bir veya daha çok ravi atılır.','<b>Kök:</b> asmak → zincir havada <b>asılı</b>.<br><b>Örnek:</b> Buhârî\'nin bab başlıklarındaki ta\'lîkler.','🪝 Askı: alt ucu boş ip'),
 ('Mürsel','#2b4c7e','#e9f0fb',chain(L,{1}), '<b>Tâbiî</b>, sahabiyi anmadan "Resûlullah buyurdu" der. Düşen halka: <b>sahabi</b>.','<b>Kök:</b> salıvermek (irsâl).<br>Hanefî ve Mâlikîler güvenilir tâbiînin mürselini delil sayar.','🕊️ Salıverilen kuş: tepeden kaçtı'),
 ('Munkatı\'','#c4632b','#fcefe6',chain(L,{2,4}), 'Senedin <b>ortasından</b> bir ravi düşer; birden fazla yerde olabilir ama <b>peş peşe değil</b>.','<b>Kök:</b> kesilmek.','✂️ Kopan ip: tek tek kesik'),
 ('Mu\'dal','#a8402f','#fbecea',chain(L,{2,3}), 'Senedin ortasından <b>peş peşe iki veya daha fazla</b> ravi düşer.','<b>Kök:</b> zorlaştırılmış, çaresiz bırakılmış.','🪢 Çözülmez düğüm: yan yana iki halka yok'),
]
cs=''
for t,k,b,svg,d1,d2,akil in cards:
    cs+=f'<div class="c" style="--k:{k};--b:{b};display:flex;gap:8px">{svg}<div><div class="n">{t}</div><div class="t">{d1}</div><div class="w">{d2}</div><div class="w"><b>Akılda:</b> {akil}</div></div></div>'
mud=f'''<div class="c" style="--k:#2c7c86;--b:#e7f4f5;margin-top:9px"><div class="n">Müdelles (tedlîs) — kopukluk gizlenmiş</div>
<div class="g3" style="margin-top:6px">
<div class="t"><b>Tedlîsü'l-isnâd</b><br>Görüştüğü hocadan <u>duymadığı</u> hadisi "an fülân" diye, duymuş gibi aktarır.</div>
<div class="t"><b>Tedlîsü'ş-şüyûh</b><br>Hocasını tanınmasın diye bilinmeyen lakap/künyeyle anar.</div>
<div class="t"><b>Mürsel-i hafî</b><br>Aynı dönemde yaşadığı (muâsır) ama <u>hiç görüşmediği</u> birinden rivayet eder.</div></div>
<div class="w"><b>Kök:</b> karanlık; satıcının malın kusurunu gizlemesi. <b>Akılda:</b> 🎭 makyajlı yüz — kusur var ama gizli.</div></div>'''
body=f'''<h1>Senedde kopukluk: 5 zayıf hadis</h1><div class="sub"><b>P</b> = Hz. Peygamber · <b>S</b> = Sahabi · <b>T</b> = Tâbiî · <b>R</b> = Ravi · <b>M</b> = Müellif (kitabı yazan). Kırmızı çarpı = düşen ravi.</div>
<div class="grid">{cs}</div>{mud}
<div class="code"><b>KOD — "Neresi kopuk?"</b><br>⬆ <b>Tepe</b> (sahabi) → <b>Mürsel</b> · ⬇ <b>Dip</b> (müellif tarafı) → <b>Muallak</b> · ↔ <b>Orta, tek tek</b> → <b>Munkatı'</b> · ↔ <b>Orta, yan yana 2+</b> → <b>Mu'dal</b> · 🎭 <b>Gizli</b> → <b>Müdelles</b><br>Cümle: "<b>Mür</b>şit tepede, <b>Mual</b>lim dipte, <b>Mun</b>i ortada tek, <b>Mu'</b>dal ikiz, <b>Müd</b>elles maskeli."</div>
<div class="trap"><b>Tuzak:</b> Mürsel en üstten, muallak en alttan düşer. Munkatı'da düşenler yan yana değildir; yan yana ise mu'dal.</div>'''
page('hadis_kopukluk',body)

# ---------- B. Ravi ta'n haritası
rows_a=[('K','Kizb','Ravi hadiste yalan söyledi','Mevzû'),('İ','İttihâm bi\'l-kizb','Günlük hayatta yalancı bilinir, hadiste yalanı sabit değil','Metrûk'),('F','Fısk','Dinin emirlerine aykırı yaşar (günahkâr)','Münker'),('C','Cehâlet','Kimliği veya güvenilirliği bilinmiyor','Mechûl / Mübhem'),('B','Bid\'at','Sapkın görüş sahibi','Propagandacı değilse çoğunluk kabul eder')]
rows_z=[('F','Fuhşu\'l-galat','Çok fazla hata yapar','Münker'),('G','Gaflet','Aşırı dalgın, dikkatsiz','Münker'),('V','Vehm','Senette/metinde yanılır; sonradan fark edilir','Muallel'),('M','Muhâlefetü\'s-sikât','Güvenilir ravilere aykırı rivayet','Şâz, Münker, Müdrec, Maklûb, Muztarib, Musahhaf'),('S','Sû\'-i hıfz','Zayıf hafıza, unutkanlık','Sürekliyse kabul edilmez; sonradan olduysa muhtalit')]
def tbl(rows,k):
    r=''.join(f'<tr><td style="font-size:18px;font-weight:900;color:{k}">{a}</td><td><b>{b}</b><br><span style="color:#555">{c}</span></td><td><b>{d}</b></td></tr>' for a,b,c,d in rows)
    return f'<table><tr><th></th><th>Ta\'n (kusur)</th><th>Sonuç</th></tr>{r}</table>'
body=f'''<h1>Ravideki 10 kusur (ta'n) → zayıf hadis</h1><div class="sub">Ravi iki şeyle ölçülür: <b>adalet</b> = kişilik (güvenilir mi?) · <b>zabt</b> = hafıza (doğru aktarıyor mu?). Beşer kusur, toplam on.</div>
<div class="grid"><div class="c" style="--k:#2b4c7e;--b:#e9f0fb"><div class="n">I. Adalete yönelik 5 kusur</div>{tbl(rows_a,'#2b4c7e')}</div>
<div class="c" style="--k:#c4632b;--b:#fcefe6"><div class="n">II. Zabta yönelik 5 kusur</div>{tbl(rows_z,'#c4632b')}</div></div>
<div class="code"><b>KOD — Adalet:</b> "<b>K</b>ötü <b>İ</b>nsan <b>F</b>ırsatı <b>C</b>ebinde <b>B</b>ekler" → Kizb · İttihâm · Fısk · Cehâlet · Bid'at<br>
<b>KOD — Zabt:</b> "<b>F</b>azla <b>G</b>afil <b>V</b>ezir <b>M</b>illeti <b>S</b>attı" → Fuhş-ı galat · Gaflet · Vehm · Muhâlefet · Sû'-i hıfz<br>
<b>Sıralı merdiven:</b> Yalancı → <b>mevzû</b> · Yalanla itham → <b>metrûk</b> · Vehim → <b>muallel</b> (gizli illet) · Sika'ya aykırı sika → <b>şâz</b> · Sika'ya aykırı zayıf → <b>münker</b></div>
<div class="trap"><b>ÖSYM sordu:</b> Muztarib, muallel, münker, şâz, maklûb listesinin başlığı → "<b>Ravideki kusur</b> sebebiyle zayıf hadisler" (senedde kopukluk değil!).</div>'''
page('ravi_tan',body)

# ---------- C. Tahammül
yol=[('S','Semâ\'','Hoca okur, öğrenci <b>dinler</b>.','haddesenâ, semi\'tü','👂',100),
('K','Kırâat (arz)','Öğrenci okur, hoca <b>dinleyip onaylar</b>.','ahberanâ, kara\'tü alâ','📖',92),
('İ','İcâzet','Hoca rivayet için <b>izin</b> verir.','ecâzenî','🤝',75),
('M','Münâvele','Hoca kitabını <b>elden verir</b> (izinle).','nâvelenî','📚',68),
('M','Mükâtebe (kitâbet)','Hoca hadisi <b>yazıp gönderir</b>.','kebebe ileyye','✉️',60),
('İ','İ\'lâm','Hoca "bunlar benim rivayetlerim" diye <b>bildirir</b>, izin vermez.','tartışmalı','📢',40),
('V','Vasiyyet','Ölüm/yolculuk öncesi kitabını <b>vasiyet</b> eder.','tartışmalı','📜',30),
('V','Vicâde','Birinin yazdığı hadisleri <b>bulur</b> (vâcid).','"vecedtü bi-hattı fülân"','🔍',20)]
r=''.join(f'<tr><td style="font-size:20px;font-weight:900;color:#2c7c86">{a}</td><td style="font-size:18px">{e}</td><td><b>{b}</b><br>{c}</td><td style="color:#555;font-size:11.5px">{d}</td><td style="width:120px"><div style="height:10px;border-radius:5px;background:linear-gradient(90deg,#2c7c86 {p}%,#e3e8ef {p}%)"></div></td></tr>' for a,b,c,d,e,p in yol)
body=f'''<h1>Tahammül yolları: hadisi hocadan almanın 8 yolu</h1><div class="sub">Sıra <b>güçlüden zayıfa</b>. <b>Tahammül</b> = almak, <b>edâ</b> = aktarmak. Çubuk: yöntemin güvenilirlik derecesi.</div>
<table><tr><th></th><th></th><th>Yol</th><th>Edâ lafzı</th><th>Güç</th></tr>{r}</table>
<div class="code"><b>KOD:</b> "<b>S</b>abah <b>K</b>ahvesini <b>İ</b>çen <b>M</b>ehmet <b>M</b>ektubu <b>İ</b>lk <b>V</b>apurda <b>V</b>erdi"<br>→ Semâ · Kırâat · İcâzet · Münâvele · Mükâtebe · İ'lâm · Vasiyyet · Vicâde<br>
<b>Hoca okur</b> = semâ 👂 · <b>Öğrenci okur</b> = kırâat 📖 · <b>Hoca okur, öğrenci yazar</b> = <b>imlâ</b> (yazdıran: <b>mümlî</b>, yazan: <b>müstemlî</b>)</div>
<div class="trap"><b>Tuzak:</b> En makbul iki yol semâ ve kırâattir. İ'lâm, vasiyyet ve vicâde ile rivayeti âlimlerin çoğu yeterli görmez; vicâdede ravi "haddesenî" diyemez, "falanın yazısında buldum" der.</div>'''
page('tahammul_kod',body,h='#2c7c86',hs='#e7f4f5')

# ---------- D. Nikah
body='''<h1>Nikâh akdi ve şartları</h1><div class="sub"><b>Rükün</b>: akdin özü · <b>Kuruluş (in'ikad)</b>: yoksa nikâh hiç kurulmaz · <b>Geçerlilik (sıhhat)</b>: yoksa nikâh fâsid/geçersiz.</div>
<div class="grid">
<div class="c" style="--k:#2b4c7e;--b:#e9f0fb"><div class="n">1 · Rükün</div><div class="t"><b>Hanefî:</b> yalnız <b>icap ve kabul</b> (irade beyanı).<br><b>Şâfiî:</b> icap-kabul + <b>eşler, veli, iki şahit</b> de rükündür.</div></div>
<div class="c" style="--k:#3f7a3a;--b:#ecf6ea"><div class="n">2 · Kuruluş şartları</div><div class="t">• <b>Ehliyet</b> (akıl; ehliyetsizin nikâhını velisi yapar)<br>• İrade beyanının <b>aynı mecliste</b>, usulüne uygun olması<br>• <b>Veli</b>: Hanefîler dışında kadının velisinin izni şart<br>• <b>Evlenme engeli</b> bulunmaması<br>• <b>Fâsid şart</b> bulunmaması (ör. süreli nikâh)</div></div>
<div class="c" style="--k:#c4632b;--b:#fcefe6"><div class="n">3 · Alenilik ve şahitler <span class="tag">ÖSYM</span></div><div class="t">• <b>Hanefî:</b> 2 erkek <u>veya</u> <b>1 erkek + 2 kadın</b><br>• <b>Cumhur:</b> 2 erkek<br>• Şahit: Müslüman, akıllı, ergen<br>• <b>Mâlikî:</b> esas olan <b>ilan</b>; şahit olsa da "gizli kalsın" şartı varsa nikâh geçersiz</div></div>
<div class="c" style="--k:#a8402f;--b:#fbecea"><div class="n">4 · İkrah (zorlama) <span class="tag">Dikkat</span></div><div class="t">• <b>Cumhur:</b> zorla kıyılan nikâh <b>geçersiz</b>.<br>• <b>Hanefî:</b> <b>geçerli</b> — zorlananın rızası yok ama seçimi (ihtiyarı) vardır.<br>Dayanak: "Üç şeyin ciddisi de şakası da ciddidir: <b>nikâh, boşama, ric'at</b>" (Ebû Dâvûd, Tirmizî — Talâk).</div></div>
</div>
<div class="code"><b>KOD — Hanefî şahit:</b> "<b>2K + 1E</b> = şahitlik tamam" (iki kadın bir erkek) · Cumhur: "<b>2E</b>"<br>
<b>KOD — Kuruluş:</b> "<b>E</b>v <b>İ</b>çin <b>V</b>eli <b>E</b>vet <b>F</b>ermanı" → Ehliyet · İrade (tek meclis) · Veli · Engel yok · Fâsid şart yok<br>
<b>KOD — Hanefî'nin üç farkı:</b> "<b>Velisiz</b> olur, <b>kadın şahit</b> olur, <b>zorla</b> olur."</div>
<div class="trap"><b>Tuzak:</b> Hanefî'de akıllı ve ergen kadın velisiz evlenebilir (denk olmayan evliliğe velinin itiraz hakkı vardır). İmam Muhammed bu konuda cumhurun görüşündedir.</div>'''
page('nikah_sartlari',body)

# ---------- E. İddet akış
body='''<h1>İddet: hangi durumda ne kadar?</h1><div class="sub">Soru sırası: <b>1) Ölüm mü boşanma mı?</b> → <b>2) Hamile mi?</b> → <b>3) Zifaf/halvet var mı?</b> → <b>4) Âdet görüyor mu?</b></div>
<table><tr><th>Durum</th><th>Şart</th><th>İddet</th></tr>
<tr><td>☠️ <b>Kocanın ölümü</b></td><td>Hamile değil — <b>zifaf olmasa da</b></td><td><b>4 ay 10 gün</b> (Bakara 234)</td></tr>
<tr><td>🤰 Ölüm veya boşanma</td><td>Hamile</td><td><b>Doğumla biter</b> (Talâk 4)</td></tr>
<tr><td>💔 Boşanma</td><td>Zifaf ve sahih halvet <b>yok</b></td><td><b>İddet yok</b> (Ahzâb 49)</td></tr>
<tr><td>💔 Boşanma / fesih</td><td>Zifaf/halvet var, âdet görüyor</td><td><b>3 kurû'</b>: Hanefî 3 hayız · Şâfiî 3 temizlik (Bakara 228)</td></tr>
<tr><td>💔 Boşanma / fesih</td><td>Yaşlılık veya küçüklük, âdet yok</td><td><b>3 kamerî ay</b> (Talâk 4)</td></tr>
<tr><td>💔 Boşanma / fesih</td><td>Emzirme, hastalık gibi <b>geçici</b> sebep</td><td>Sebep bitince 3 hayız / 3 temizlik</td></tr>
<tr><td>💔 Boşanma / fesih</td><td>Sebebi <b>bilinmeyen</b> kesilme</td><td>Gebelik yoksa 3 ay, belirsizse 1 yıl (Mâlikî çözümü)</td></tr>
<tr><td>💔 Boşanma / fesih</td><td>İstihâze (sürekli kan)</td><td>Bilinen âdet düzenine göre 3 dönem; yoksa 3 ay</td></tr></table>
<div class="code"><b>KOD — ayetler:</b> "<b>228 kurû', 234 vefat, Talâk 4 ay ve gebe, Ahzâb 49 iddet yok</b>"<br>
<b>KOD — vefat:</b> "<b>Ölüm zifafa bakmaz, boşanma bakar.</b>"<br>
<b>KOD — sonuçlar:</b> "<b>E-M-N-M-N</b>" → Evlenme yasağı · Mesken · Nafaka (ric'îde) · Mirasçılık (ric'îde) · Nesep</div>
<div class="trap"><b>ÖSYM 2026:</b> Nikâh kıyılmış, düğün olmamış, koca şehit → <b>4 ay 10 gün</b>. <b>2024:</b> Ric'î boşanma iddetinde koca ölürse kadın <b>vefat iddetine</b> geçer.</div>'''
page('iddet_akis',body,h='#7a4e9a',hs='#f3ecf8')

# ---------- F. Sünnetin Kur'an'ı açıklaması (4M-4T)
body='''<h1>Sünnet Kur'an'ı nasıl açıklar? 4M → 4T</h1><div class="sub">Kur'an'daki dört tür ifade (<b>4 M</b>) Hz. Peygamber'in açıklamalarıyla dört şekilde netleşir (<b>4 T</b>). ÖSYM bu bölümden defalarca soru sordu.</div>
<div class="grid">
<div class="c" style="--k:#2b4c7e;--b:#e9f0fb"><div class="n">Mücmel → Tebyîn</div><div class="t">Lafzın kendisi kapalı; ne kastedildiği karine olmadan anlaşılmaz.</div><div class="w"><b>Örnek:</b> namaz, zekât, hac, diyet ve kısas emirleri → nasıl yapılacağını sünnet açıkladı.<br>Kelime örnekleri: "as'ase" (Tekvîr 17), "helû'" (Meâric 19).</div></div>
<div class="c" style="--k:#3f7a3a;--b:#ecf6ea"><div class="n">Mübhem → Tafsîl</div><div class="t">Kim veya ne olduğu açıkça söylenmeyen ifadenin ayrıntılandırılması.</div><div class="w"><b>Bakara 238</b> "orta namaz" → ikindi <span class="tag">ÖSYM</span><br>Fâtiha: nimet verilenler (Nisâ 69); gazaba uğrayanlar ve sapanlar<br>Abese 1-2: âmâ → Abdullah b. Ümmü Mektûm<br>Hz. Âdem'in eşi → Havva <span class="tag">ÖSYM</span></div></div>
<div class="c" style="--k:#c4632b;--b:#fcefe6"><div class="n">Mutlak → Takyîd</div><div class="t">Anlamı sınırlanmamış ifadeye sünnetin sınır getirmesi.</div><div class="w"><b>Müzzemmil 20</b> "Kur'an'dan kolayınıza geleni okuyun" + hadis: "Fâtiha'sız namaz olmaz".<br><b>Mâide 38</b> hırsızın elini kesin + hadis: <b>bilekten</b> kesilir.</div></div>
<div class="c" style="--k:#a8402f;--b:#fbecea"><div class="n">Müşkil → Tavzîh</div><div class="t">İlk bakışta çelişkili görünen ifadedeki güçlüğün giderilmesi.</div><div class="w"><b>Meryem 71</b> "Hepiniz oraya varacaksınız (vürûd)" ↔ müminlerin cennete gireceğini bildiren ayetler.<br>Çözüm: <b>varmak</b> (vürûd) ile <b>azap görmek</b> aynı değildir; ateş müminlere, İbrahim'e olduğu gibi serin ve esenlik olacaktır.</div></div>
</div>
<div class="code"><b>KOD — eşleştir:</b> <b>Mü</b>cmel-<b>Teb</b>yin · <b>Müb</b>hem-<b>Taf</b>sil · <b>Mut</b>lak-<b>Tak</b>yid · <b>Müş</b>kil-<b>Tav</b>zih<br>
Cümle: "<b>Kapalı</b> kapıyı <b>aç</b> (tebyîn), <b>isimsizi</b> <b>tanıt</b> (tafsîl), <b>sınırsızı</b> <b>çerçevele</b> (takyîd), <b>çelişkiyi</b> <b>çöz</b> (tavzîh)."<br>
Akılda: <b>Mübhem = isim yok</b> (kim?), <b>Mücmel = yöntem yok</b> (nasıl?).</div>'''
page('sunnet_4t',body,h='#3f7a3a',hs='#ecf6ea')

# ---------- G. Kıraat
body='''<h1>Kıraat: kim, nerede, hangi şartla?</h1><div class="sub"><b>Kıraat</b>: Kur'an'ın farklı okunuş tarzları. <b>İmam</b> → <b>ravi</b> (imamdan alan) → <b>tarik</b> (raviden alan) → <b>vecih</b> (okuyucunun tercihine bağlı fark).</div>
<div class="grid">
<div class="c" style="--k:#2b4c7e;--b:#e9f0fb"><div class="n">Kırâat-i seb'a (7 imam)</div>
<table><tr><th>Şehir</th><th>İmam</th></tr><tr><td>Medine</td><td><b>Nâfi'</b></td></tr><tr><td>Mekke</td><td><b>İbn Kesîr</b></td></tr><tr><td>Basra</td><td><b>Ebû Amr</b></td></tr><tr><td>Şam</td><td><b>İbn Âmir</b></td></tr><tr><td>Kûfe</td><td><b>Âsım · Hamza · Kisâî</b></td></tr></table>
<div class="w">10'a tamamlayanlar: <b>Ebû Ca'fer</b> (Medine), <b>Ya'kûb</b> (Basra), <b>Halef</b> (Kûfe).<br>Bugün en yaygın okuyuş: <b>Âsım kıraati – Hafs rivayeti</b>.</div></div>
<div class="c" style="--k:#3f7a3a;--b:#ecf6ea"><div class="n">Sahih kıraatin 3 şartı</div>
<div class="t">1. <b>Senet</b>: Sahih ve kesintisiz senetle Hz. Peygamber'e ulaşmalı.<br>2. <b>Dil</b>: Arap dili kurallarına uymalı.<br>3. <b>Mushaf</b>: Hz. Osman mushaflarının yazımına aykırı olmamalı.</div>
<div class="n" style="margin-top:8px;color:#a8402f">Sahih olmayanlar</div>
<div class="t"><b>Şâz</b>: senedi sahih ve güvenilir olmayan.<br><b>Müdrec</b>: sahabenin açıklama notunun Kur'an sanılması.<br><b>Mevzû</b>: aslı olmayan, uydurma okuyuş.</div>
<div class="w">Sahih kıraat senet bakımından: <b>mütevâtir</b> veya <b>meşhur</b>. Meşhur, sahih olmayanlardan değildir!</div></div></div>
<div class="code"><b>KOD — şehirler:</b> "<b>Na</b>-<b>Ke</b>-<b>Am</b>-<b>Âm</b> + <b>Kûfe'de ÂH-K</b>" → Medine Nâfi', Mekke İbn Kesîr, Basra Ebû Amr, Şam İbn Âmir; Kûfe'de üç imam: <b>Â</b>sım, <b>H</b>amza, <b>K</b>isâî ("Âh Kûfe!")<br>
<b>KOD — şartlar:</b> "<b>SeDiM</b>" → Senet · Dil · Mushaf<br>
<b>KOD — kim belirledi:</b> Yediyi <b>İbn Mücâhid</b> seçti (Kitâbü's-Seb'a); <b>Dânî</b> (et-Teysîr) ve <b>Şâtıbî</b> (Şâtıbiyye) bu tasnifi yerleştirdi. Yedi sayısı, sahih okuyuşların yalnız yedi olduğu anlamına gelmez.</div>'''
page('kiraat',body)

# ---------- H. Gazveler
gz=[('2/623','Ebvâ (Veddân)','ilk gazve',0),('2/624','Safevân','I. Bedir',0),('2/624','Bedir','büyük zafer',1),('3/625','Uhud','okçular',1),('4/626','Bedrülmev\'id','III. Bedir',0),('5/627','Hendek','Selmân',1),('5/627','Benî Kurayza','ihanet',1),('5-6/627','Benî Mustalik','Müreysî',1),('6/628','Hudeybiye','antlaşma',0),('7/628','Hayber','Yahudi tehdidi biter',1),('8/630','Mekke\'nin fethi','Hudeybiye bozuldu',1),('8/630','Huneyn','müellefe',1),('8/630','Tâif','kuşatma',1),('9/630','Tebük','son gazve',0)]
r=''.join(f'<div style="display:flex;align-items:center;gap:8px;padding:3px 0"><div style="width:72px;font-size:11.5px;color:#555">{d}</div><div style="width:16px;height:16px;border-radius:50%;background:{"#a8402f" if c else "#fff"};border:2.5px solid {"#a8402f" if c else "#8a6d1c"}"></div><div style="font-size:13px"><b>{n}</b> <span style="color:#666">· {x}</span></div></div>' for d,n,x,c in gz)
body=f'''<h1>Gazve ve seriyye</h1><div class="sub"><b>Gazve</b>: Hz. Peygamber'in bizzat katıldığı sefer · <b>Seriyye</b>: bir sahabinin komutasında gönderilen birlik. Çarpışma olup olmaması ayrımı değiştirmez.</div>
<div class="grid"><div class="c" style="--k:#8a6d1c;--b:#f8f2df"><div class="n">Zaman çizelgesi</div><div class="w">🔴 = çarpışma oldu · ⚪ = çarpışma olmadı</div>{r}</div>
<div><div class="c" style="--k:#2b4c7e;--b:#e9f0fb"><div class="n">Sayılar</div><div class="t"><b>27 gazve</b> (Vâkıdî, İbn Sa'd); bunların <b>9</b>'unda çarpışma oldu.</div><div class="w">Konuyu işleyen eserlere <b>megâzî</b> denir: Vâkıdî, Kitâbü'l-Megâzî.</div></div>
<div class="c" style="--k:#3f7a3a;--b:#ecf6ea;margin-top:8px"><div class="n">İlgili ayetler</div><div class="t"><b>Hac 39</b>: Saldırıya uğrayanlara savaş izni (ilk izin)<br><b>Bakara 190</b>: Size savaşanlarla savaşın, haddi aşmayın<br><b>Bakara 193</b>: Fitne kalmayıncaya kadar<br><b>Tevbe 52</b>: İki güzel sonuç: şehitlik veya zafer</div></div>
<div class="c" style="--k:#a8402f;--b:#fbecea;margin-top:8px"><div class="n">Savaş ilkeleri</div><div class="t">Sivillere dokunulmaz · yağma ve tahrip yasak · esirlere iyi davranılır · antlaşmalara sadakat</div></div></div></div>
<div class="code"><b>KOD — 9 çarpışmalı gazve:</b> "<b>B</b>ir <b>U</b>zun <b>H</b>ikâye: <b>K</b>ız <b>M</b>ektebe <b>H</b>ediye <b>M</b>ektup <b>H</b>ızlıca <b>T</b>aşıdı" → Bedir · Uhud · Hendek · Kurayza · Mustalik · Hayber · Mekke · Huneyn · Tâif<br>
<b>KOD — 3 Bedir:</b> I. Safevân (takip) · II. <b>Büyük Bedir</b> (çarpışma) · III. Bedrülmev'id (randevu, savaş yok)</div>'''
page('gazveler',body,h='#8a6d1c',hs='#f8f2df')

# ---------- I/J. Kod kartları
def kodpage(name,title,sub,items,h,hs):
    cs=''.join(f'<div class="c" style="--k:{h};--b:{hs}"><div class="n">{t}</div><div class="t">{c}</div></div>' for t,c in items)
    page(name,f'<h1>{title}</h1><div class="sub">{sub}</div><div class="grid">{cs}</div>',h=h,hs=hs)
kodpage('hadis_kodlari','Hadis: kod kartları','Sınavdan önce son tekrar için tek sayfada hadis usulünün hafıza kodları.',[
('Kaynağına göre','"<b>Ku</b>dret <b>Mer</b>mer <b>Mev</b>ki <b>Mak</b>amda" → Kudsî · Merfû · Mevkûf · Maktû<br>(Allah → Peygamber → Sahabe → Tâbiûn)'),
('Sünnet çeşitleri','"<b>Ka</b>fa – <b>Fi</b>il – <b>Tak</b>dir" → Kavlî · Fiilî · Takrîrî'),
('Ravi sayısı','Mütevâtir: yalan üzerine birleşmeleri imkânsız topluluk<br>"<b>Meşhur Aziz Garip = 3 – 2 – 1</b>"'),
('Destek rivayetler','Aynı sahabi → <b>mütâbi</b> · Farklı sahabi → <b>şâhid</b> · Arama işi → <b>i\'tibâr</b>'),
('Kopukluk yeri','Tepe → <b>Mürsel</b> · Dip → <b>Muallak</b> · Orta tek → <b>Munkatı\'</b> · Orta 2+ yan yana → <b>Mu\'dal</b> · Gizli → <b>Müdelles</b>'),
('Ravi kusuru','Adalet: "<b>K</b>ötü <b>İ</b>nsan <b>F</b>ırsatı <b>C</b>ebinde <b>B</b>ekler"<br>Zabt: "<b>F</b>azla <b>G</b>afil <b>V</b>ezir <b>M</b>illeti <b>S</b>attı"'),
('Aykırılık','Şâz ↔ mahfûz (aykırı olan <b>sika</b>) · Münker ↔ ma\'rûf (aykırı olan <b>zayıf</b>)'),
('Değişiklik','Musahhaf = <b>nokta</b> · Muharref = <b>hareke</b> · Maklûb = <b>yer</b> · Müdrec = <b>ekleme</b> · Muztarib = <b>denk çelişki</b>'),
('Tahammül 8 yol','"<b>S</b>abah <b>K</b>ahvesini <b>İ</b>çen <b>M</b>ehmet <b>M</b>ektubu <b>İ</b>lk <b>V</b>apurda <b>V</b>erdi"'),
('Kütüb-i Sitte','"<b>B</b>ugün <b>M</b>utlaka <b>E</b>v <b>T</b>emizliği <b>N</b>e <b>İ</b>yi" → Buhârî · Müslim · Ebû Dâvûd · Tirmizî · Nesâî · İbn Mâce'),
('Eser türleri','Câmi\' = 8 konu, herkesi toplar · Sünen = ahkâm · Müsned = sahabiye göre · Mu\'cem = alfabe · Etrâf = baş kısmı · Zevâid = fazlalar'),
('Vürûd–nüzûl','Hadiste "<b>vürûd</b>" (geliş) · Kur\'an\'da "<b>nüzûl</b>" (iniş). Garîbü\'l-hadis ↔ Garîbü\'l-Kur\'an'),
],'#2b4c7e','#e9f0fb')
kodpage('fikih_kodlari','Fıkıh: kod kartları','Sınavın üçte biri fıkıh (20 soru). En çok sorulan konuların hafıza kodları.',[
('Mezhep – delil','"<b>H</b>anefî <b>H</b>asta" → İsti<b>h</b>san · "<b>M</b>âlik <b>M</b>edine" → <b>M</b>esâlih + <b>M</b>edine ameli · Şâfiî → kıyas ve hadis, istihsanı reddeder'),
('Teklîfî – vaz\'î','Emir/yasak → <b>teklîfî</b> (farz, vacip, sünnet, mübah, mekruh, haram) · "şu olunca / olmadan" → <b>vaz\'î</b> (sebep, şart, mâni\')'),
('Abdest bozanlar','Gülümseme: hiçbiri · Sesli gülme: <b>namaz</b> · Kahkaha: <b>namaz + abdest</b>'),
('Hac günü (10 Zilhicce)','"<b>TaKıTı</b>" → <b>Ta</b>ş · <b>K</b>urban · <b>Tı</b>raş · sonra ziyaret tavafı'),
('Haccın rükünleri','Hanefî: <b>Arafat vakfesi + ziyaret tavafı</b>; ihram şart'),
('Kefaret','Oruç: "<b>1 – 60 – 60</b>" (köle · 60 gün oruç · 60 fakir) · Yemin: <b>10 – 10 – 1 / yoksa 3</b>'),
('Kurban ortaklığı','Küçükbaş <b>1</b>, büyükbaş en fazla <b>7</b>; Hanefî\'de hepsi ibadet niyetiyle'),
('İddet','"<b>228 kurû\', 234 vefat, Talâk 4 ay ve gebe, Ahzâb 49 iddet yok</b>" · Ölüm zifafa bakmaz'),
('Nikâh','Hanefî şahit: <b>2K + 1E</b> · "Velisiz olur, kadın şahit olur, zorla olur" (Hanefî)'),
('Miras sırası','"<b>Kefen – Kredi – Kâğıt – Kardeş</b>" → cenaze · borç · vasiyet · mirasçılar<br>Karı: 1/4 – çocuk varsa 1/8 · Koca: 1/2 – 1/4'),
('Ortaklıklar','Mu<b>d</b>ârebe = <b>D</b>ükkân parası · Mü<b>z</b>âraa = <b>Z</b>emin · Mü<b>s</b>âkât = <b>S</b>ulama · Vü<b>c</b>ûh = <b>C</b>epte para yok, itibar var'),
('Akitler','Karşılıksız + mülk = <b>hibe</b> · Karşılıksız + kullanım = <b>âriyet</b> · Bedelli + mülk = <b>bey\'</b> · Bedelli + kullanım = <b>icâre</b>'),
],'#3f7a3a','#ecf6ea')

# ---------- K. Cami hafıza sarayı: kroki ve 10 durak
dur=[(1,'🗼','Minare','Uzaktan ilk görünen yer'),(2,'🚪','Avlu kapısı','Avluya girilen büyük kapı'),(3,'⛲','Şadırvan','Avlunun ortasındaki çeşme'),
(4,'🏛️','Son cemaat yeri','Kapının önündeki sütunlu revak'),(5,'👟','Ayakkabılık','Girişteki ahşap raflar'),(6,'🎙️','Müezzin mahfili','Müezzinin durduğu bölme'),
(7,'📖','Kürsü','Vaazın verildiği yer'),(8,'🪜','Minber','Hutbenin okunduğu yer'),(9,'🕌','Mihrap','İmamın durduğu niş'),(10,'🔵','Kubbe','Başını kaldırınca gördüğün tavan')]
pos={1:(150,300),2:(386,530),3:(386,430),4:(292,307),5:(326,262),6:(540,240),7:(279,69),8:(489,78),9:(386,34),10:(386,160)}
def badge(n):
    x,y=pos[n]
    return f'<circle cx="{x}" cy="{y}" r="15" fill="#7a4e9a" stroke="#fff" stroke-width="2.5"/><text x="{x}" y="{y+5}" font-size="14" font-weight="800" text-anchor="middle" fill="#fff">{n}</text>'
route=' '.join(f'{pos[n][0]},{pos[n][1]}' for n in [2,3,4]) + ' 386,292 ' + ' '.join(f'{pos[n][0]},{pos[n][1]}' for n in [5,6,7,8,9,10])
cols=''.join(f'<circle cx="{x}" cy="330" r="6" fill="#b9a27a"/>' for x in (196,262,328,444,510,576))
svg=f'''<svg viewBox="0 0 772 570" width="772" height="570" style="display:block;background:#fbf8f1;border-radius:12px;border:1.5px solid #d9cfb8">
<rect x="116" y="330" width="540" height="200" fill="#eef3e6" stroke="#8a7a55" stroke-width="3"/>
<rect x="358" y="524" width="56" height="12" fill="#fbf8f1"/>
<rect x="176" y="284" width="420" height="46" fill="#f3e9d2" stroke="#8a7a55" stroke-width="2"/>{cols}
<rect x="176" y="34" width="420" height="250" fill="#fff" stroke="#5a4a2a" stroke-width="4"/>
<rect x="364" y="278" width="44" height="12" fill="#fff"/>
<path d="M356 34 A30 30 0 0 1 416 34" fill="#e9f0fb" stroke="#2b4c7e" stroke-width="3"/>
<circle cx="386" cy="160" r="80" fill="none" stroke="#2b4c7e" stroke-width="2" stroke-dasharray="6,5"/>
<rect x="262" y="52" width="34" height="34" rx="4" fill="#fcefe6" stroke="#c4632b" stroke-width="2"/>
<path d="M476 50 h26 v60 h-26 Z M476 65 h26 M476 80 h26 M476 95 h26" fill="#ecf6ea" stroke="#3f7a3a" stroke-width="2"/>
<rect x="500" y="214" width="80" height="52" rx="4" fill="#f3ecf8" stroke="#7a4e9a" stroke-width="2"/>
<rect x="296" y="253" width="60" height="18" rx="3" fill="#f8f2df" stroke="#8a6d1c" stroke-width="2"/>
<circle cx="386" cy="430" r="32" fill="#e7f4f5" stroke="#2c7c86" stroke-width="3"/><circle cx="386" cy="430" r="12" fill="#bfe3e6"/>
<circle cx="150" cy="300" r="20" fill="#f3e9d2" stroke="#5a4a2a" stroke-width="3"/>
<path d="M150 322 Q96 560 386 560 L386 540" fill="none" stroke="#c79a1e" stroke-width="2.5" stroke-dasharray="7,6"/>
<polyline points="{route}" fill="none" stroke="#c79a1e" stroke-width="2.5" stroke-dasharray="7,6"/>
<text x="386" y="20" font-size="12" text-anchor="middle" fill="#555">▲ kıble</text>
<text x="640" y="350" font-size="12" text-anchor="end" fill="#6b7a55">avlu</text>
<text x="590" y="52" font-size="12" text-anchor="end" fill="#777">harim (içerisi)</text>
{''.join(badge(n) for n in range(1,11))}
</svg>'''
leg=''.join(f'<div class="dk"><span class="no">{n}</span><span class="em">{e}</span><div><b class="dn">{t}</b><br><span class="dd">{d}</span></div></div>' for n,e,t,d in dur)
body=f'''<style>.dk{{display:flex;gap:8px;align-items:center;border:1.5px solid #d6c9e3;border-radius:10px;padding:6px 9px;background:#faf6fd}}
.no{{flex:0 0 26px;height:26px;border-radius:50%;background:#7a4e9a;color:#fff;font-weight:800;display:flex;align-items:center;justify-content:center;font-size:13px}}
.em{{font-size:22px}}.dn{{font-size:14.5px;color:#4a2f63}}.dd{{font-size:11.5px;color:#555}}</style>
<h1>Cami hafıza sarayı: 10 durak</h1><div class="sub">Rota hep aynı: önce uzaktan minareyi gör, avludan geç, içeri gir. İçeride <b>cuma sırası</b>: vaaz (kürsü) → hutbe (minber) → namaz (mihrap). En son başını kaldır: kubbe.</div>
{svg}
<div class="grid" style="margin-top:10px">{leg}</div>
<div class="code"><b>Nasıl kullanılır?</b> Ezberleyeceğin listenin her öğesini sırayla bir durağa koy ve orada <b>abartılı, hareketli</b> bir sahne kur. Hatırlamak için gözünü kapat, camiyi minareden kubbeye yürü; her durakta sahneyi gör.<br>
<b>Kod — sıra:</b> "<b>M</b>inareyi gör, <b>A</b>vludan gir, <b>Ş</b>adırvanda dur, <b>S</b>on cemaatte bekle, <b>A</b>yakkabını çıkar; <b>M</b>ahfil, <b>K</b>ürsü, <b>M</b>inber, <b>M</b>ihrap, <b>K</b>ubbe."</div>'''
page('saray_rota',body,h='#7a4e9a',hs='#f3ecf8')
