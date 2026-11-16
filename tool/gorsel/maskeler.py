"""Kapalı şema tanımları: hangi şemada hangi yazılar kapatılacak.

Her şema: başlık, alan, ipucu kutuları (dokununca açılır, puanlanmaz) ve maskeler.
Maske biçimleri:
  ('yazı', 'madde-id')            -> yazının ipucu kutuları dışındaki bütün geçtiği yerler
  ('=yazı', 'madde-id')           -> yalnızca tek başına duran (ör. kalın) yazı
  ('yazı', 'madde-id', 'etiket')  -> panelde gösterilecek farklı etiket
  {'sel': 'css', 'entries': [...]} -> seçiciye uyan her öğe bir maske
"""
HINT = '.code, .trap'
SEMALAR = {
 'hadis_kopukluk': dict(t='Senedde kopukluk: 5 zayıf hadis', a='hadis', hint=HINT, m=[
   ('Mürsel-i hafî', 'mudelles'), ('=Muallak', 'muallak'), ('=Mürsel', 'mursel'), ("=Munkatı'", 'munkati'), ("=Mu'dal", 'mudal'),
   ('=başından', 'muallak', 'Muallak: senedin başından (müellif tarafından)'), ('=sahabi', 'mursel', 'Mürselde düşen halka: sahabi'),
   ('=peş peşe değil', 'munkati', "Munkatı': peş peşe değil"), ('=peş peşe iki veya daha fazla', 'mudal', "Mu'dal: peş peşe iki veya daha fazla"),
   ('Müdelles (tedlîs)', 'mudelles'), ("=Tedlîsü'l-isnâd", 'mudelles'), ("=Tedlîsü'ş-şüyûh", 'mudelles')]),
 'ravi_tan': dict(t='Ravideki 10 kusur', a='hadis', hint=HINT, m=[
   ('=Kizb', 'ravi-tan'), ("=İttihâm bi'l-kizb", 'ravi-tan'), ('=Fısk', 'ravi-tan'), ('=Cehâlet', 'ravi-tan'), ("=Bid'at", 'ravi-tan'),
   ('=Mevzû', 'mevzu', 'Kizb → Mevzû'), ('=Metrûk', 'metruk', 'İttihâm → Metrûk'),
   ("=Fuhşu'l-galat", 'ravi-tan'), ('=Gaflet', 'ravi-tan'), ('=Vehm', 'ravi-tan'), ("=Muhâlefetü's-sikât", 'ravi-tan'), ("=Sû'-i hıfz", 'ravi-tan'),
   ('=Münker', 'munker', 'Fısk, fuhşu\'l-galat, gaflet → Münker'), ('=Muallel', 'muallel', 'Vehm → Muallel')]),
 'tahammul_kod': dict(t='Tahammül yolları: 8 yol', a='hadis', hint=HINT, m=[
   ("=Semâ'", 'tahammul-yollari'), ('=Kırâat (arz)', 'tahammul-yollari'), ('=İcâzet', 'tahammul-yollari'), ('=Münâvele', 'tahammul-yollari'),
   ('=Mükâtebe (kitâbet)', 'tahammul-yollari'), ("=İ'lâm", 'tahammul-yollari'), ('=Vasiyyet', 'tahammul-yollari'), ('=Vicâde', 'tahammul-yollari')]),
 'hadis_kodlari': dict(t='Hadis kod kartları', a='hadis', hint='', m=[
   {'sel': '.grid .c .t', 'entries': ['merfu', 'sunnet', 'meshur', 'mutabi', 'zayif', 'ravi-tan', 'saz', 'musahhaf', 'tahammul-yollari', 'kutub-i-sitte', 'cami', 'esbabu-vurud']}]),
 'nikah_sartlari': dict(t='Nikâh akdi ve şartları', a='fikih', hint=HINT, m=[
   ('=icap ve kabul', 'nikah', 'Hanefî\'de rükün: icap ve kabul'), ('=eşler, veli, iki şahit', 'nikah', 'Şâfiî\'de ek rükünler: eşler, veli, iki şahit'),
   ('=aynı mecliste', 'nikah', 'İrade beyanı: aynı mecliste'), ('=1 erkek + 2 kadın', 'nikah', 'Hanefî şahit: 2 erkek veya 1 erkek + 2 kadın'),
   ('=ilan', 'nikah', 'Mâlikî: esas olan ilan'), ('=geçersiz', 'nikah', 'Cumhur: zorla nikâh geçersiz'), ('=geçerli', 'nikah', 'Hanefî: zorla nikâh geçerli'),
   ("=nikâh, boşama, ric'at", 'nikah', "Şakası da ciddi üç şey: nikâh, boşama, ric'at")]),
 'iddet_akis': dict(t='İddet: hangi durumda ne kadar?', a='fikih', hint=HINT, m=[
   ('=zifaf olmasa da', 'iddet', 'Vefat iddeti: zifaf olmasa da'), ('=4 ay 10 gün', 'iddet', 'Kocanın ölümü: 4 ay 10 gün'), ('=Doğumla biter', 'iddet', 'Hamile: doğumla biter'),
   ('=İddet yok', 'iddet', 'Zifaf ve halvet yoksa: iddet yok'), ("=3 kurû'", 'iddet', "Âdet gören: 3 kurû'"),
   ('Hanefî 3 hayız · Şâfiî 3 temizlik', 'iddet'), ('=3 kamerî ay', 'iddet', 'Âdet görmeyen: 3 kamerî ay')]),
 'fikih_kodlari': dict(t='Fıkıh kod kartları', a='fikih', hint='', m=[
   {'sel': '.grid .c .t', 'entries': ['fikih-usulu', 'ser-i-hukum', 'abdest', 'hac', 'hac', 'kefaret', 'kurban', 'iddet', 'nikah', 'miras', 'sirketler', 'akit-turleri']}]),
 'varlik_delilleri': dict(t="Allah'ın varlığının delilleri", a='kelam', hint='.sub, .foot', m=[
   ('Hudûs', 'hudus-delili'), ('İmkân', 'imkan-delili'), ('Gaye ve nizam (inâyet)', 'gaye-nizam'), ('İhtirâ (yaratma)', 'ihtira-delili'),
   ("Temânu'", 'temanu'), ('Fıtrat', 'fitrat-delili'), ('Kabûl-i âmme', 'kabul-i-amme'), ('Ahlak (vicdan)', 'ahlak-delili'),
   ('=muhdis', 'hudus-delili', 'Hudûs: bir muhdis var etmiştir'), ("=Vâcibü'l-vücûd", 'imkan-delili', "İmkân: Vâcibü'l-vücûd gerekir"),
   ('=Birlik (vahdâniyet)', 'temanu', "Temânu': birlik (vahdâniyet) delili")]),
 'sunnet_4t': dict(t="Sünnet Kur'an'ı nasıl açıklar? 4M → 4T", a='tefsir', hint=HINT, m=[
   ('Tebyîn', 'sunnetin-beyani', 'Mücmel → Tebyîn'), ('Tafsîl', 'sunnetin-beyani', 'Mübhem → Tafsîl'), ('Takyîd', 'sunnetin-beyani', 'Mutlak → Takyîd'), ('Tavzîh', 'sunnetin-beyani', 'Müşkil → Tavzîh'),
   ('ikindi', 'sunnetin-beyani', 'Orta namaz: ikindi'), ('Abdullah b. Ümmü Mektûm', 'sunnetin-beyani'), ('Havva', 'sunnetin-beyani', "Hz. Âdem'in eşi: Havva"),
   ("Fâtiha'sız namaz olmaz", 'sunnetin-beyani'), ('=bilekten', 'sunnetin-beyani', 'El bilekten kesilir')]),
 'kiraat': dict(t='Kıraat: kim, nerede, hangi şartla?', a='kuran', hint=HINT, m=[
   ("=Nâfi'", 'kiraat', "Medine: Nâfi'"), ('=İbn Kesîr', 'kiraat', 'Mekke: İbn Kesîr'), ('=Ebû Amr', 'kiraat', 'Basra: Ebû Amr'), ('=İbn Âmir', 'kiraat', 'Şam: İbn Âmir'),
   ('=Âsım · Hamza · Kisâî', 'kiraat', 'Kûfe: Âsım, Hamza, Kisâî'), ('=Âsım kıraati – Hafs rivayeti', 'kiraat'),
   ('=Senet', 'kiraat', '1. şart: Senet'), ('=Dil', 'kiraat', '2. şart: Dil'), ('=Mushaf', 'kiraat', '3. şart: Mushaf'),
   ('=Şâz', 'kiraat'), ('=Müdrec', 'kiraat'), ('=Mevzû', 'kiraat')]),
 'gazveler': dict(t='Gazve ve seriyye', a='siyer', hint=HINT, m=[
   ('=Bedir', 'gazveler'), ('=Uhud', 'gazveler'), ('=Hendek', 'gazveler'), ('=Benî Kurayza', 'gazveler'), ('=Benî Mustalik', 'gazveler'),
   ('=Hayber', 'gazveler'), ("=Mekke'nin fethi", 'gazveler'), ('=Huneyn', 'gazveler'), ('=Tâif', 'gazveler'),
   ('=27 gazve', 'gazveler'), ('=9', 'gazveler', "Çarpışma olan gazve sayısı: 9"), ('=megâzî', 'gazveler', 'Gazveleri anlatan eserler: megâzî'), ('=Hac 39', 'gazveler', 'İlk savaş izni: Hac 39')]),
 'saray_rota': dict(t='Cami hafıza sarayı: 10 durak', a='fikih', hint=HINT, m=[
   {'sel': '.dn', 'entries': []}]),
}
