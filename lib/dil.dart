import 'dart:convert';

import 'package:flutter/services.dart';

class Cumle {
  final String id, emoji, native, reading, turkish, hook;
  Cumle(this.id, this.emoji, this.native, this.reading, this.turkish, this.hook);
}

class DilKategori {
  final String id, title, icon;
  final List<Cumle> phrases;
  DilKategori(this.id, this.title, this.icon, this.phrases);
}

class Dil {
  final String id, name, flag, voice, note;
  final bool rtl;
  final List<DilKategori> categories;
  Dil(this.id, this.name, this.flag, this.voice, this.rtl, this.note, this.categories);

  int get count => categories.fold(0, (a, k) => a + k.phrases.length);
  List<Cumle> get all => [for (final k in categories) ...k.phrases];

  static List<Dil>? _cache;

  static Future<List<Dil>> load() async {
    if (_cache != null) return _cache!;
    final j = jsonDecode(await rootBundle.loadString('assets/content/dil.json')) as List;
    return _cache = [
      for (final d in j)
        Dil(d['id'] as String, d['ad'] as String, d['bay'] as String, d['ses'] as String, d['rtl'] as bool, d['not'] as String, [
          for (final k in d['k'] as List)
            DilKategori(k['id'] as String, k['t'] as String, k['ic'] as String, [
              for (final c in k['c'] as List) Cumle(c['id'] as String, c['e'] as String, c['n'] as String, c['o'] as String, c['t'] as String, c['k'] as String),
            ]),
        ]),
    ];
  }
}
