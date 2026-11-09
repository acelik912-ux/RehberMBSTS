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
AREAS = {'hadis', 'fikih', 'kelam', 'kuran', 'tefsir', 'siyer', 'mezhep', 'dinler', 'video'}
FILES = ['hadis', 'kelam', 'fikih', 'kuran', 'siyer', 'videolar']
LINK = re.compile(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]')


def parse(name):
    area = 'video' if name == 'videolar' else name
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
            allent[e['id']] = e
        (OUT / f'{f}.json').write_text(json.dumps(ents, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
        files.append(f'{f}.json')
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
    (OUT / 'sorular.json').write_text(json.dumps(qs, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
    (OUT / 'index.json').write_text(json.dumps({'files': files, 'questions': 'sorular.json'}, ensure_ascii=False), encoding='utf-8')
    by = {}
    for e in allent.values():
        by[e['a']] = by.get(e['a'], 0) + 1
    print(f'{len(allent)} madde, {len(qs)} soru', by)
    if errors:
        print('\n'.join(errors))
        sys.exit(1)


if __name__ == '__main__':
    main()
