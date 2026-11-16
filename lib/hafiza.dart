import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';

/// Kapalı şema: görselin üzerinde kapatılacak bir yazı (bir veya birkaç dikdörtgen).
class MaskBox {
  final String text;
  final String entryId;
  final List<Rect> rects; // 0..1 arası oranlar: sol, üst, genişlik, yükseklik
  MaskBox(this.text, this.entryId, this.rects);
}

class SemaMask {
  final String id, title, area;
  final double aspect; // genişlik / yükseklik
  final List<MaskBox> boxes;
  final List<Rect> hints; // açık kalan ipucu kutuları
  SemaMask(this.id, this.title, this.area, this.aspect, this.boxes, this.hints);
}

class Durak {
  final int no;
  final String icon, title, desc;
  Durak(this.no, this.icon, this.title, this.desc);
}

class SarayOge {
  final int stop;
  final String info, entryId, scene;
  SarayOge(this.stop, this.info, this.entryId, this.scene);
}

class SarayTur {
  final String id, title, area, icon, role, entryId;
  final List<SarayOge> items;
  SarayTur(this.id, this.title, this.area, this.icon, this.role, this.entryId, this.items);
}

Rect _rect(dynamic l) {
  final r = List<num>.from(l as List);
  return Rect.fromLTWH(r[0].toDouble(), r[1].toDouble(), r[2].toDouble(), r[3].toDouble());
}

/// Görsel hafıza içeriği: kapalı şemalar ve cami hafıza sarayı.
class Hafiza {
  final List<SemaMask> semalar;
  final List<Durak> duraklar;
  final List<SarayTur> turlar;
  Hafiza(this.semalar, this.duraklar, this.turlar);

  static Hafiza? _cache;

  static Future<Hafiza> load() async {
    if (_cache != null) return _cache!;
    final idx = jsonDecode(await rootBundle.loadString('assets/content/index.json')) as Map<String, dynamic>;
    final mj = jsonDecode(await rootBundle.loadString('assets/content/${idx['maskeler'] ?? 'maskeler.json'}')) as Map<String, dynamic>;
    final semalar = <SemaMask>[];
    mj.forEach((id, v) {
      final j = v as Map<String, dynamic>;
      semalar.add(SemaMask(
        id,
        j['t'] as String,
        j['a'] as String,
        (j['asp'] as num).toDouble(),
        [
          for (final b in j['m'] as List)
            MaskBox((b['t'] ?? '') as String, (b['e'] ?? '') as String, [for (final r in b['r'] as List) _rect(r)]),
        ],
        [for (final r in (j['h'] as List? ?? const [])) _rect(r)],
      ));
    });
    final sj = jsonDecode(await rootBundle.loadString('assets/content/${idx['saray'] ?? 'saray.json'}')) as Map<String, dynamic>;
    final duraklar = [
      for (final d in sj['d'] as List) Durak(d['n'] as int, d['ic'] as String, d['t'] as String, d['d'] as String),
    ];
    final turlar = [
      for (final t in sj['r'] as List)
        SarayTur(t['id'] as String, t['t'] as String, t['a'] as String, t['ic'] as String, t['r'] as String, t['e'] as String, [
          for (final o in t['o'] as List) SarayOge(o['n'] as int, o['b'] as String, o['e'] as String, o['s'] as String),
        ]),
    ];
    return _cache = Hafiza(semalar, duraklar, turlar);
  }
}
