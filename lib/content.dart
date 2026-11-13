import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Sınav alanı (Hadis, Fıkıh ...).
class Area {
  final String id;
  final String name;
  final int questions;
  final Color color;
  final IconData icon;
  const Area(this.id, this.name, this.questions, this.color, this.icon);
}

const areas = <Area>[
  Area('hadis', 'Hadis', 7, Color(0xFFB9862F), Icons.menu_book),
  Area('fikih', 'Fıkıh ve İlmihal', 20, Color(0xFFA8402F), Icons.balance),
  Area('kelam', 'Akaid ve Kelam', 7, Color(0xFF3F7A3A), Icons.lightbulb_outline),
  Area('kuran', "Kur'an Bilgisi", 7, Color(0xFF2E5A93), Icons.auto_stories),
  Area('tefsir', 'Tefsir', 7, Color(0xFF6A4C93), Icons.import_contacts),
  Area('siyer', 'Siyer ve İslam Tarihi', 7, Color(0xFF0F5C63), Icons.history_edu),
  Area('mezhep', 'Mezhepler Tarihi', 3, Color(0xFF7A5A3A), Icons.account_tree),
  Area('dinler', 'Dinler Tarihi', 2, Color(0xFF5B6775), Icons.public),
];

Area areaById(String id) => areas.firstWhere((a) => a.id == id, orElse: () => areas.first);

/// Bir madde (terim / konu sayfası).
class Entry {
  final String id;
  final String title;
  final String area;
  final String group;
  final List<String> aliases;
  final List<int> years;
  final String summary;
  final String body;
  final List<String> images;
  final bool custom;

  const Entry({
    required this.id,
    required this.title,
    required this.area,
    required this.group,
    this.aliases = const [],
    this.years = const [],
    this.summary = '',
    this.body = '',
    this.images = const [],
    this.custom = false,
  });

  factory Entry.fromJson(Map<String, dynamic> j, {bool custom = false}) => Entry(
        id: j['id'] as String,
        title: j['t'] as String,
        area: j['a'] as String,
        group: (j['g'] ?? 'Diğer') as String,
        aliases: List<String>.from(j['k'] ?? const []),
        years: List<int>.from(j['y'] ?? const []),
        summary: (j['o'] ?? '') as String,
        body: (j['b'] ?? '') as String,
        images: List<String>.from(j['img'] ?? const []),
        custom: custom,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        't': title,
        'a': area,
        'g': group,
        'k': aliases,
        'y': years,
        'o': summary,
        'b': body,
        'img': images,
      };

  Entry copyWith({String? body, String? summary, String? title, String? group, String? area}) => Entry(
        id: id,
        title: title ?? this.title,
        area: area ?? this.area,
        group: group ?? this.group,
        aliases: aliases,
        years: years,
        summary: summary ?? this.summary,
        body: body ?? this.body,
        images: images,
        custom: custom,
      );
}

/// Test sorusu.
class Question {
  final String area;
  final String text;
  final List<String> options;
  final int answer;
  final String explanation;
  final String entryId;
  const Question(this.area, this.text, this.options, this.answer, this.explanation, this.entryId);

  factory Question.fromJson(Map<String, dynamic> j) => Question(
        j['a'] as String,
        j['q'] as String,
        List<String>.from(j['s']),
        j['c'] as int,
        (j['x'] ?? '') as String,
        (j['e'] ?? '') as String,
      );
}

/// Türkçe/Arapça işaretlerden bağımsız arama anahtarı.
String norm(String s) {
  const map = {
    'â': 'a', 'Â': 'a', 'î': 'i', 'Î': 'i', 'û': 'u', 'Û': 'u', 'ı': 'i', 'İ': 'i', 'I': 'i',
    'ş': 's', 'Ş': 's', 'ç': 'c', 'Ç': 'c', 'ğ': 'g', 'Ğ': 'g', 'ö': 'o', 'Ö': 'o', 'ü': 'u', 'Ü': 'u',
    'ḥ': 'h', 'ṣ': 's', 'ṭ': 't', 'ẓ': 'z', 'ḍ': 'd',
  };
  final b = StringBuffer();
  for (final r in s.runes) {
    final c = String.fromCharCode(r);
    if (c == "'" || c == '’' || c == 'ʿ' || c == 'ʾ' || c == '-' || c == '‘') continue;
    b.write(map[c] ?? c.toLowerCase());
  }
  return b.toString();
}

/// Uygulama içine gömülü içerik.
class Content {
  final Map<String, Entry> entries;
  final List<Question> questions;
  Content(this.entries, this.questions);

  static Future<Content> load() async {
    final manifest = jsonDecode(await rootBundle.loadString('assets/content/index.json')) as Map<String, dynamic>;
    final map = <String, Entry>{};
    for (final f in List<String>.from(manifest['files'])) {
      final list = jsonDecode(await rootBundle.loadString('assets/content/$f')) as List;
      for (final j in list) {
        final e = Entry.fromJson(j as Map<String, dynamic>);
        map[e.id] = e;
      }
    }
    final qs = <Question>[];
    final qf = manifest['questions'] as String?;
    if (qf != null) {
      for (final j in jsonDecode(await rootBundle.loadString('assets/content/$qf')) as List) {
        qs.add(Question.fromJson(j as Map<String, dynamic>));
      }
    }
    return Content(map, qs);
  }
}

final linkRe = RegExp(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]');

/// Gövde metnindeki bağlantıların hedefleri.
Iterable<String> linksIn(String body) =>
    linkRe.allMatches(body).map((m) => m.group(1)!.trim()).where((id) => !id.startsWith('http'));
