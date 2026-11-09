# Rehber MBSTS — çalışma notları

- Flutter uygulaması; `android/` klasörü derlemede `flutter create` + `tool/patch_android.py` ile oluşturulur (depoda yok).
- Yerelde Flutter yok: kod kontrolü ve testler GitHub Actions'ta (`.github/workflows/apk.yml`) çalışır. Push'tan sonra Actions sonucunu takip et.
- İmza anahtarı `tool/rehber.keystore` (şifre rehber2026). ASLA değiştirme/silme; yoksa telefonda güncelleme üstüne kurulmaz.
- İçerik kaynağı `content/*.txt`; değişiklikten sonra mutlaka `python3 tool/build_content.py` çalıştır (JSON üretir + bağlantı doğrular). Üretilen `assets/content/*.json` da commit edilir.
- Şemalar `assets/sema/*.png` (çalışma PDF'inden alınmış görseller).
- Kullanıcı verisi telefonda `rehber_veri.json` + `gorseller/` klasöründe; veri biçimini değiştirirsen eski veriyi okuyabilmeye dikkat et.
- Kullanıcıyla Türkçe konuş; kullanıcı Samsung S25 kullanıyor, APK'yı Releases sayfasından indiriyor.
- Özetler kaynak kitaplardan kopyalanmaz; kendi cümlelerimizle yazılır.
