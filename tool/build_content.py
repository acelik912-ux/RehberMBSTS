"""content/*.txt dosyalarını assets/content/*.json'a çevirir ve bağlantıları doğrular.

Madde biçimi:
@@ id | Başlık | Grup | diğer ad 1; diğer ad 2 | 2023,2024
= tek cümlelik özet
gövde satırları ... ([[id]] veya [[id|yazı]] bağlantı)
@img sema/dosya.png

Bir dosyada alan değiştirmek için:  @area tefsir
Sorular (content/sorular.txt):
?? alan | ilgili-madde-id
Soru metni
A) ...
*B) doğru şık
= açıklama
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / 'content'
OUT = ROOT / 'assets' / 'content'
AREAS = {'hadis', 'fikih', 'kelam', 'kuran', 'tefsir', 'siyer', 'mezhep', 'dinler'}
FILES = ['hadis', 'kelam', 'fikih', 'kuran', 'siyer']
LINK = re.compile(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]')


def parse(name):
    area = name
    entries = []
    cur = None
    for raw in (SRC / f'{name}.txt').read_text(encoding='utf-8').split('\n'):
        line = raw.rstrip()
        if line.startswith('@area '):
            area = line.split()[1]
            continue
        if line.startswith('@@ '):
            parts = [p.strip() for p in line[3:].split('|')]
            parts += [''] * (5 - len(parts))
            cur = {'id': parts[0], 't': parts[1], 'a': area, 'g': parts[2] or 'Diğer',
                   'k': [x.strip() for x in parts[3].split(';') if x.strip()],
                   'y': [int(x) for x in re.split(r'[ ,]+', parts[4]) if x.strip()],
                   'o': '', 'b': [], 'img': []}
            entries.append(cur)
            continue
        if cur is None:
            continue
        if line.startswith('= ') and not cur['o'] and not cur['b']:
            cur['o'] = line[2:].strip()
        elif line.startswith('@img '):
            cur['img'].append('assets/' + line[5:].strip())
        else:
            cur['b'].append(line)
    for e in entries:
        e['b'] = '\n'.join(e['b']).strip('\n')
        if not e['img']:
            del e['img']
    return entries


def parse_questions():
    p = SRC / 'sorular.txt'
    out = []
    if not p.exists():
        return out
    for block in re.split(r'\n\s*\n', p.read_text(encoding='utf-8').strip()):
        lines = [l for l in block.strip().split('\n') if l.strip()]
        head = lines[0][3:].split('|')
        q = {'a': head[0].strip(), 'e': head[1].strip() if len(head) > 1 else '', 'q': '', 's': [], 'c': -1, 'x': ''}
        text = []
        for l in lines[1:]:
            m = re.match(r'^(\*?)([A-E])\) (.*)$', l)
            if m:
                if m.group(1):
                    q['c'] = len(q['s'])
                q['s'].append(m.group(3).strip())
            elif l.startswith('= '):
                q['x'] = l[2:].strip()
            else:
                text.append(l.strip())
        q['q'] = ' '.join(text)
        out.append(q)
    return out


def parse_saray(allent, errors):
    """content/saray.txt -> assets/content/saray.json (duraklar + turlar)."""
    duraklar, turlar, cur = [], [], None
    for raw in (ROOT / 'content/saray.txt').read_text(encoding='utf-8').splitlines():
        ln = raw.strip()
        if not ln or ln.startswith('#'):
            continue
        if ln.startswith('@durak '):
            n, ic, t, d = [x.strip() for x in ln[7:].split('|', 3)]
            duraklar.append({'n': int(n), 'ic': ic, 't': t, 'd': d})
        elif ln.startswith('@tur '):
            i, t, a, ic, role, e = [x.strip() for x in ln[5:].split('|', 5)]
            if e not in allent:
                errors.append(f'saray turu maddesi yok: {i} -> {e}')
            if a not in AREAS:
                errors.append(f'saray turu alanı: {i} -> {a}')
            cur = {'id': i, 't': t, 'a': a, 'ic': ic, 'r': role, 'e': e, 'o': []}
            turlar.append(cur)
        else:
            n, info, eid, sahne = [x.strip() for x in ln.split('|', 3)]
            if cur is None or not n.isdigit() or not 1 <= int(n) <= len(duraklar):
                errors.append(f'saray satırı hatalı: {ln[:50]}')
                continue
            if eid not in allent:
                errors.append(f'saray maddesi yok: {cur["id"]} -> {eid}')
            cur['o'].append({'n': int(n), 'b': info, 'e': eid, 's': sahne})
    return {'d': duraklar, 'r': turlar}


def parse_dil():
    """content/dil.txt -> assets/content/dil.json (bölümler, gruplar, üç dilli satırlar)."""
    bolumler, gruplar, cur = [], [], None
    for raw in (ROOT / 'content/dil.txt').read_text(encoding='utf-8').splitlines():
        ln = raw.strip()
        if not ln or ln.startswith('#'):
            continue
        if ln.startswith('@bolum '):
            i, t, d = [x.strip() for x in ln[7:].split('|', 2)]
            bolumler.append({'id': i, 't': t, 'd': d})
        elif ln.startswith('@grup '):
            i, b, t, ic, st = [x.strip() for x in ln[6:].split('|', 4)]
            if b not in [x['id'] for x in bolumler]:
                raise SystemExit('dil grubunun bölümü yok: ' + ln[:40])
            cur = {'id': i, 'b': b, 't': t, 'ic': ic, 's': st, 'c': []}
            gruplar.append(cur)
        else:
            f = [x.strip() for x in ln.split('|')]
            if len(f) != 9 or not all(f):
                raise SystemExit('dil satırı 9 alan olmalı: ' + ln[:50])
            em, tr, bs, bo, en, eo, ar, ao, k = f
            cur['c'].append({'id': f"{cur['id']}-{len(cur['c']) + 1}", 'e': em, 't': tr, 'bs': bs, 'bo': bo, 'en': en, 'eo': eo, 'ar': ar, 'ao': ao, 'k': k})
    return {'b': bolumler, 'g': gruplar}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    allent = {}
    files = []
    errors = []
    for f in FILES:
        ents = parse(f)
        for e in ents:
            if e['id'] in allent:
                errors.append(f'tekrarlanan id: {e["id"]}')
            if e['a'] not in AREAS:
                errors.append(f'geçersiz alan: {e["id"]} {e["a"]}')
            e['_f'] = f
            allent[e['id']] = e
        files.append(f'{f}.json')
    icons = {}
    for ln in (ROOT / 'content/ikonlar.txt').read_text(encoding='utf-8').splitlines():
        if not ln.strip() or ln.startswith('#'):
            continue
        parts = [x.strip() for x in ln.split('|')]
        if len(parts) != 3 or parts[0] not in allent:
            errors.append(f'ikon satırı hatalı: {ln}')
            continue
        icons[parts[0]] = parts[1:]
    for e in allent.values():
        if e['id'] in icons:
            e['ic'], e['ih'] = icons[e['id']]
        else:
            errors.append(f'ikonu yok: {e["id"]}')
    byfile = {}
    for e in allent.values():
        byfile.setdefault(e.pop('_f'), []).append(e)
    for f in FILES:
        ents = byfile.get(f, [])
        (OUT / f'{f}.json').write_text(json.dumps(ents, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
    for e in allent.values():
        for m in LINK.finditer(e['b'] + ' ' + e['o']):
            if not m.group(1).strip().startswith('http') and m.group(1).strip() not in allent:
                errors.append(f'kırık bağlantı: {e["id"]} -> {m.group(1)}')
        for i in e.get('img', []):
            if not (ROOT / i).exists():
                errors.append(f'eksik görsel: {e["id"]} -> {i}')
    qs = parse_questions()
    for q in qs:
        if q['c'] < 0 or len(q['s']) < 2:
            errors.append(f'soru hatalı: {q["q"][:50]}')
        if q['e'] and q['e'] not in allent:
            errors.append(f'soru maddesi yok: {q["e"]}')
        if q['a'] not in AREAS:
            errors.append(f'soru alanı: {q["a"]}')
    (OUT / 'saray.json').write_text(json.dumps(parse_saray(allent, errors), ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
    (OUT / 'dil.json').write_text(json.dumps(parse_dil(), ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
    (OUT / 'sorular.json').write_text(json.dumps(qs, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
    (OUT / 'index.json').write_text(json.dumps({'files': files, 'questions': 'sorular.json', 'saray': 'saray.json', 'maskeler': 'maskeler.json'}, ensure_ascii=False), encoding='utf-8')
    by = {}
    for e in allent.values():
        by[e['a']] = by.get(e['a'], 0) + 1
    print(f'{len(allent)} madde, {len(qs)} soru', by)
    if errors:
        print('\n'.join(errors))
        sys.exit(1)


if __name__ == '__main__':
    main()
