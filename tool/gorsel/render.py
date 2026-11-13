# Kullanım: python3 tool/gorsel/render.py ad1 ad2 ...  → assets/sema/<ad>.png
import asyncio, sys, pathlib
from playwright.async_api import async_playwright
from PIL import Image
root = pathlib.Path(__file__).resolve().parents[2]
async def main(names):
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path='/usr/bin/google-chrome')
        pg = await b.new_page(viewport={'width': 800, 'height': 1200}, device_scale_factor=2)
        for name in names:
            await pg.goto((root / f'tool/gorsel/{name}.html').as_uri())
            out = root / f'assets/sema/{name}.png'
            await pg.locator('#g').screenshot(path=str(out))
            Image.open(out).convert('RGB').quantize(colors=256, method=Image.Quantize.MEDIANCUT).save(out, optimize=True)
            print(name, out.stat().st_size // 1024, 'KB')
        await b.close()
asyncio.run(main(sys.argv[1:]))
