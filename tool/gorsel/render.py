# Kullanım: python3 tool/gorsel/render.py varlik_delilleri  → assets/sema/varlik_delilleri.png
import asyncio, sys, pathlib
from playwright.async_api import async_playwright
root = pathlib.Path(__file__).resolve().parents[2]
async def main(name):
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path='/usr/bin/google-chrome')
        pg = await b.new_page(viewport={'width': 800, 'height': 1200}, device_scale_factor=2)
        await pg.goto((root / f'tool/gorsel/{name}.html').as_uri())
        await pg.locator('#g').screenshot(path=str(root / f'assets/sema/{name}.png'))
        await b.close()
asyncio.run(main(sys.argv[1]))
