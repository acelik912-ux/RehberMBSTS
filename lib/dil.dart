import 'dart:convert';

import 'package:flutter/services.dart';

/// Üç dilin ortak tanımı: her satırda sırayla Boşnakça, İngilizce, Arapça alt alta gösterilir.
class DilTanim {
  final String flag, name, voice;
  final String? fallback;
  final bool rtl;
  const DilTanim(this.flag, this.name, this.voice, this.fallback, this.rtl);
}

const dilTanimlari = [
  DilTanim('🇧🇦', 'Boşnakça', 'bs-BA', 'hr-HR', false),
  DilTanim('🇬🇧', 'İngilizce', 'en-US', null, false),
  DilTanim('🇸🇦', 'Arapça', 'ar-SA', null, true),
];

/// Bir satır: Türkçe karşılık + üç dilde metin ve okunuş.
class Cumle {
  final String id, emoji, turkish, hook;
  final List<String> texts; // [Boşnakça, İngilizce, Arapça]
  final List<String> readings;
  Cumle(this.id, this.emoji, this.turkish, this.texts, this.readings, this.hook);
}

class DilGrup {
  final String id, bolum, title, icon, story;
  final List<Cumle> items;
  DilGrup(this.id, this.bolum, this.title, this.icon, this.story, this.items);
  bool get sirali => bolum == 'A'; // hikâye gruplarında sahneler sırayla gelir
}

class DilBolum {
  final String id, title, desc;
  DilBolum(this.id, this.title, this.desc);
}

class DilVeri {
  final List<DilBolum> bolumler;
  final List<DilGrup> gruplar;
  DilVeri(this.bolumler, this.gruplar);

  int get count => gruplar.fold(0, (a, g) => a + g.items.length);
  List<DilGrup> of(String bolum) => gruplar.where((g) => g.bolum == bolum).toList();

  static DilVeri? _cache;

  static Future<DilVeri> load() async {
    if (_cache != null) return _cache!;
    final j = jsonDecode(await rootBundle.loadString('assets/content/dil.json')) as Map<String, dynamic>;
    return _cache = DilVeri(
      [for (final b in j['b'] as List) DilBolum(b['id'] as String, b['t'] as String, b['d'] as String)],
      [
        for (final g in j['g'] as List)
          DilGrup(g['id'] as String, g['b'] as String, g['t'] as String, g['ic'] as String, g['s'] as String, [
            for (final c in g['c'] as List)
              Cumle(c['id'] as String, c['e'] as String, c['t'] as String, [c['bs'] as String, c['en'] as String, c['ar'] as String],
                  [c['bo'] as String, c['eo'] as String, c['ao'] as String], c['k'] as String),
          ]),
      ],
    );
  }
}
