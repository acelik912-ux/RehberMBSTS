"""tool/icon/kaynak.jpg -> tool/android_res (simge: klasik + uyarlanabilir). Çalıştır: python3 tool/icon/uret.py"""
import pathlib
from PIL import Image, ImageDraw

here = pathlib.Path(__file__).parent
out = here.parent / 'android_res'
src = Image.open(here / 'kaynak.jpg').convert('RGB')
legacy = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
for d, px in legacy.items():
    p = out / f'mipmap-{d}'
    p.mkdir(parents=True, exist_ok=True)
    big = src.resize((px * 4, px * 4), Image.LANCZOS)
    mask = Image.new('L', big.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, big.size[0] - 1, big.size[1] - 1], radius=int(px * 4 * 0.22), fill=255)
    big.putalpha(mask)
    big.resize((px, px), Image.LANCZOS).save(p / 'ic_launcher.png')
    fpx = px * 108 // 48
    canvas = Image.new('RGBA', (fpx, fpx), (0, 0, 0, 0))
    inner = int(fpx * 0.75)
    canvas.paste(src.resize((inner, inner), Image.LANCZOS), ((fpx - inner) // 2, (fpx - inner) // 2))
    canvas.save(p / 'ic_launcher_foreground.png')
(out / 'mipmap-anydpi-v26').mkdir(parents=True, exist_ok=True)
(out / 'mipmap-anydpi-v26/ic_launcher.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
''', encoding='utf-8')
(out / 'values').mkdir(parents=True, exist_ok=True)
(out / 'values/ic_launcher_background.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#B9DCF0</color>
</resources>
''', encoding='utf-8')
