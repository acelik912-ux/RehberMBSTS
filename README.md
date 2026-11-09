# Rehber MBSTS

Diyanet İşleri Başkanlığı MBSTS sınavı için Android çalışma uygulaması (Flutter).

- **Bağlantılı rehber:** Her madde içindeki terimlere dokunarak derine inilir (ör. Mutezile → adl → mihne). Her sayfanın altında "Bu terim nerelerde geçiyor?" listesi vardır.
- **Kendi notların:** Her maddeye yazı + galeriden/kameradan görsel eklenir. İlk görsel tekrar kartında ipucu olarak görünür.
- **Kendi maddelerin ve düzenleme:** Yeni madde açılabilir, hazır metinler düzenlenip istenince orijinale dönülebilir.
- **Tekrar kartları (Leitner):** 1-3-7-21-45 gün aralıklarla.
- **Test:** Alan alan sorular, yanlışlarım listesi, her soruda ilgili maddeye bağlantı.
- **Yedek:** Notlar, görseller ve kartlar tek .zip dosyasına alınıp geri yüklenir.

## İçerik nasıl güncellenir?

Metinler `content/*.txt` dosyalarındadır (biçim `tool/build_content.py` başında anlatılıyor).
Değiştirdikten sonra `python3 tool/build_content.py` çalıştırılır; bu komut `assets/content/*.json` dosyalarını üretir ve kırık bağlantıları gösterir.

## APK

`main` dalına her gönderimde GitHub Actions APK'yı derler ve **Releases** sayfasına koyar.
APK sabit anahtarla (`tool/rehber.keystore`) imzalanır; yeni sürüm eskisinin üstüne kurulur, notlar silinmez.
