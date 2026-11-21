"""Boşnakça ve harekeli Arapça için Türkçe okunuş üretir (yaklaşık, öğrenme amaçlı)."""
import re, unicodedata

def bs_oku(s):
    t = s.lower()
    for a, b in [('dž', '§'), ('đ', '§'), ('lj', 'ly'), ('nj', 'ny'), ('č', 'ç'), ('ć', 'ç'), ('š', 'ş'), ('ž', 'j'),
                 ('ije', 'iye'), ('je', 'ye'), ('ja', 'ya'), ('ju', 'yu'), ('j', 'y'), ('c', 'ts'), ('§', 'c')]:
        t = t.replace(a, b)
    return t

AR = {'ب': 'b', 'ت': 't', 'ث': 's', 'ج': 'c', 'ح': 'h', 'خ': 'h', 'د': 'd', 'ذ': 'z', 'ر': 'r', 'ز': 'z', 'س': 's', 'ش': 'ş',
      'ص': 's', 'ض': 'd', 'ط': 't', 'ظ': 'z', 'ع': '\'', 'غ': 'g', 'ف': 'f', 'ق': 'k', 'ك': 'k', 'ل': 'l', 'م': 'm', 'ن': 'n',
      'ه': 'h', 'ة': 'e', 'ء': '\'', 'أ': '\'', 'إ': '\'', 'ؤ': '\'', 'ئ': '\'', 'ى': 'â', 'آ': 'â'}
V = {'َ': 'e', 'ُ': 'u', 'ِ': 'i'}
TAN = {'ً': 'en', 'ٌ': 'un', 'ٍ': 'in'}
SUK, SHD, MADD = 'ْ', 'ّ', 'ٓ'

def ar_oku(s):
    out = []
    chars = list(s)
    n = len(chars)
    i = 0
    last_v = ''
    while i < n:
        c = chars[i]
        if c == ' ' or not ('؀' <= c <= 'ۿ'):
            out.append(c); i += 1; last_v = ''; continue
        # sonraki işaretler
        j = i + 1
        marks = ''
        while j < n and unicodedata.category(chars[j]) == 'Mn':
            marks += chars[j]; j += 1
        vow = next((V[m] for m in marks if m in V), '')
        tan = next((TAN[m] for m in marks if m in TAN), '')
        shd = SHD in marks
        if c == 'ا':
            if last_v == 'e': out.append('â') if False else None
            # uzatma: önceki harf fetha ise 'â' yaz
            if out and out[-1].endswith('e') and last_v == 'e':
                out[-1] = out[-1][:-1] + 'â'
            elif not out or out[-1] == ' ':
                out.append('')  # hemze elif
            i = j; continue
        if c == 'و' and last_v == 'u' and not vow:
            out[-1] = out[-1][:-1] + 'û'; last_v = ''; i = j; continue
        if c == 'ي' and last_v == 'i' and not vow:
            out[-1] = out[-1][:-1] + 'î'; last_v = ''; i = j; continue
        base = AR.get(c, 'v' if c == 'و' else 'y' if c == 'ي' else '')
        if c == 'ل' and i >= 1 and chars[i - 1] == 'ا' and (i == 1 or chars[i - 2] == ' '):
            pass
        piece = base * (2 if shd and base not in "'" else 1) + vow
        if c == 'ة':
            piece = 'e' if not tan else ''
        piece += tan
        out.append(piece)
        last_v = vow
        i = j
    r = ''.join(out)
    r = r.replace("el-", "el-")
    return re.sub(r'\s+', ' ', r).strip()

if __name__ == '__main__':
    import sys
    for ln in open('content/dil.txt', encoding='utf-8'):
        f = [x.strip() for x in ln.split('|')]
        if len(f) == 9 and not ln.startswith(('#', '@')):
            print(f[2], '|', f[3], '=>', bs_oku(f[2]), '||', f[6], '|', f[7], '=>', ar_oku(f[6]))
