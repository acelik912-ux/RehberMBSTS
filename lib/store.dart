import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'content.dart';

/// Kullanıcının notu: yazı + görseller. entryId boşsa serbest not.
class Note {
  final String id;
  String entryId;
  String text;
  List<String> images; // uygulama klasöründeki dosya adları
  final int created;
  Note({required this.id, required this.entryId, required this.text, required this.images, required this.created});

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: j['id'] as String,
        entryId: (j['e'] ?? '') as String,
        text: (j['t'] ?? '') as String,
        images: List<String>.from(j['i'] ?? const []),
        created: (j['c'] ?? 0) as int,
      );
  Map<String, dynamic> toJson() => {'id': id, 'e': entryId, 't': text, 'i': images, 'c': created};
}

/// Leitner kartı durumu.
class CardState {
  int box; // 1..5
  int due; // gün numarası (epoch gün)
  CardState(this.box, this.due);
  factory CardState.fromJson(Map<String, dynamic> j) => CardState(j['b'] as int, j['d'] as int);
  Map<String, dynamic> toJson() => {'b': box, 'd': due};
}

const boxDays = [0, 1, 3, 7, 21, 45]; // kutu -> sonraki tekrar aralığı (gün)

String qKey(Question q) => q.text.length > 70 ? q.text.substring(0, 70) : q.text;

int today() => DateTime.now().difference(DateTime(2024)).inDays;

/// Tüm kişisel veriler tek bir JSON dosyasında, görseller "gorseller" klasöründe tutulur.
class Store extends ChangeNotifier {
  late Directory dir;
  late Directory imgDir;
  final List<Note> notes = [];
  final Map<String, Entry> custom = {}; // kullanıcının eklediği maddeler
  final Map<String, String> overrides = {}; // düzenlenen hazır madde metinleri
  final Map<String, CardState> cards = {};
  final Set<String> favorites = {};
  final Set<String> read = {};
  final Map<String, int> quizWrong = {}; // soru metni hash -> yanlış sayısı
  final List<String> history = [];
  double ttsRate = 0.5;
  bool remindOn = false;
  int remindH = 20, remindM = 30;
  final List<DenemeResult> denemeler = [];
  final Map<String, List<String>> attach = {}; // yer anahtarı (ör. e:abdest, d:bs-selam-1) -> eklenen resim dosyaları
  final Map<String, CardState> dilCards = {}; // 'satırId|dilNo' -> aralıklı tekrar kartı
  final Map<String, bool> visual = {}; // kapalı şema kutusu / saray durağı -> bildim mi

  File get _file => File('${dir.path}/rehber_veri.json');

  Future<void> load() async {
    dir = await getApplicationDocumentsDirectory();
    imgDir = Directory('${dir.path}/gorseller');
    if (!imgDir.existsSync()) imgDir.createSync(recursive: true);
    if (_file.existsSync()) {
      try {
        _fromJson(jsonDecode(_file.readAsStringSync()) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('veri okunamadı: $e');
      }
    }
  }

  void _fromJson(Map<String, dynamic> j) {
    notes
      ..clear()
      ..addAll((j['notes'] as List? ?? []).map((e) => Note.fromJson(e as Map<String, dynamic>)));
    custom
      ..clear()
      ..addEntries((j['custom'] as List? ?? []).map((e) {
        final en = Entry.fromJson(e as Map<String, dynamic>, custom: true);
        return MapEntry(en.id, en);
      }));
    overrides
      ..clear()
      ..addAll(Map<String, String>.from(j['overrides'] ?? const {}));
    cards
      ..clear()
      ..addAll((j['cards'] as Map? ?? {}).map((k, v) => MapEntry(k as String, CardState.fromJson(v as Map<String, dynamic>))));
    favorites
      ..clear()
      ..addAll(List<String>.from(j['fav'] ?? const []));
    read
      ..clear()
      ..addAll(List<String>.from(j['read'] ?? const []));
    quizWrong
      ..clear()
      ..addAll(Map<String, int>.from(j['qw'] ?? const {}));
    history
      ..clear()
      ..addAll(List<String>.from(j['hist'] ?? const []));
    ttsRate = (j['tts'] as num?)?.toDouble() ?? 0.5;
    final rem = (j['rem'] as Map?) ?? const {};
    remindOn = rem['on'] == true;
    remindH = (rem['h'] as num?)?.toInt() ?? 20;
    remindM = (rem['m'] as num?)?.toInt() ?? 30;
    denemeler
      ..clear()
      ..addAll((j['dnm'] as List? ?? []).map((e) => DenemeResult.fromJson(e as Map<String, dynamic>)));
    dilCards
      ..clear()
      ..addAll(((j['wc'] as Map?) ?? const {}).map((k, v) => MapEntry(k as String, CardState.fromJson(v as Map<String, dynamic>))));
    attach
      ..clear()
      ..addAll(((j['att'] as Map?) ?? const {}).map((k, v) => MapEntry(k as String, List<String>.from(v as List))));
    visual
      ..clear()
      ..addAll(((j['vk'] as Map?) ?? const {}).map((k, v) => MapEntry(k as String, v == true)));
  }

  Map<String, dynamic> toJson() => {
        'v': 1,
        'notes': notes.map((n) => n.toJson()).toList(),
        'custom': custom.values.map((e) => e.toJson()).toList(),
        'overrides': overrides,
        'cards': cards.map((k, v) => MapEntry(k, v.toJson())),
        'fav': favorites.toList(),
        'read': read.toList(),
        'qw': quizWrong,
        'hist': history,
        'tts': ttsRate,
        'rem': {'on': remindOn, 'h': remindH, 'm': remindM},
        'dnm': denemeler.map((d) => d.toJson()).toList(),
        'vk': visual,
        'att': attach,
        'wc': dilCards.map((k, v) => MapEntry(k, v.toJson())),
      };

  Future<void> save() async {
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(jsonEncode(toJson()));
    await tmp.rename(_file.path);
    notifyListeners();
  }

  // ---------------- maddeler ----------------
  Entry? resolve(Content c, String id) {
    final e = custom[id] ?? c.entries[id];
    if (e == null) return null;
    final o = overrides[id];
    return o == null ? e : e.copyWith(body: o);
  }

  List<Entry> allEntries(Content c) => [
        ...c.entries.values.map((e) => resolve(c, e.id)!),
        ...custom.values,
      ];

  void visit(String id) {
    read.add(id);
    history.remove(id);
    history.insert(0, id);
    if (history.length > 30) history.removeLast();
    save();
  }

  Future<void> saveCustom(Entry e) async {
    custom[e.id] = e;
    await save();
  }

  Future<void> deleteCustom(String id) async {
    custom.remove(id);
    cards.remove(id);
    await save();
  }

  Future<void> setOverride(String id, String? body) async {
    if (body == null) {
      overrides.remove(id);
    } else {
      overrides[id] = body;
    }
    await save();
  }

  void toggleFav(String id) {
    favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
    save();
  }

  // ---------------- notlar ----------------
  List<Note> notesFor(String entryId) => notes.where((n) => n.entryId == entryId).toList()
    ..sort((a, b) => b.created.compareTo(a.created));

  File imageFile(String name) => File('${imgDir.path}/$name');

  /// Klavyeden (Gboard vb.) veya panodan gelen resim baytlarını kaydeder.
  Future<String> importBytes(List<int> bytes, [String ext = '.png']) async {
    final name = 'g${DateTime.now().microsecondsSinceEpoch}$ext';
    await imageFile(name).writeAsBytes(bytes);
    return name;
  }

  void attachImage(String slot, String name) {
    attach.putIfAbsent(slot, () => []).add(name);
    save();
  }

  void detachImage(String slot, String name) {
    attach[slot]?.remove(name);
    if (attach[slot]?.isEmpty ?? false) attach.remove(slot);
    save();
  }

  Future<String> importImage(String path) async {
    final ext = path.contains('.') ? path.substring(path.lastIndexOf('.')) : '.jpg';
    final name = 'g${DateTime.now().microsecondsSinceEpoch}$ext';
    await File(path).copy(imageFile(name).path);
    return name;
  }

  Future<void> upsertNote(Note n) async {
    notes.removeWhere((x) => x.id == n.id);
    notes.add(n);
    await save();
  }

  Future<void> deleteNote(Note n) async {
    notes.removeWhere((x) => x.id == n.id);
    for (final i in n.images) {
      final f = imageFile(i);
      if (f.existsSync()) f.deleteSync();
    }
    await save();
  }

  /// Bir maddeye bağlı ilk kullanıcı görseli (çağrışım resmi).
  String? cueImage(String entryId) {
    for (final n in notesFor(entryId)) {
      if (n.images.isNotEmpty) return n.images.first;
    }
    return null;
  }

  // ---------------- tekrar kartları ----------------
  bool inCards(String id) => cards.containsKey(id);

  void addCard(String id) {
    cards.putIfAbsent(id, () => CardState(1, today()));
    save();
  }

  void addCards(Iterable<String> ids) {
    for (final id in ids) {
      cards.putIfAbsent(id, () => CardState(1, today()));
    }
    save();
  }

  /// Görsel yoklamada (kapalı şema, saray) bir kutuyu işaretler; bilinmeyen madde tekrar kartlarına girer.
  void markVisual(String key, bool known, String entryId) {
    visual[key] = known;
    if (!known && entryId.isNotEmpty) {
      cards.putIfAbsent(entryId, () => CardState(1, today()));
    }
    save();
  }

  /// Dil satırında bir dili işaretler (dil: 0 Boşnakça, 1 İngilizce, 2 Arapça). Bilinmeyen tekrar kartına girer.
  void dilMark(String id, int dil, bool known) {
    visual['dl:$id:$dil'] = known;
    if (!known) dilCards.putIfAbsent('$id|$dil', () => CardState(1, today()));
    save();
  }

  List<String> dueDil() {
    final t = today();
    final l = dilCards.entries.where((e) => e.value.due <= t).map((e) => e.key).toList();
    l.sort((a, b) => dilCards[a]!.box.compareTo(dilCards[b]!.box));
    return l;
  }

  void dilGrade(String key, bool known) {
    final c = dilCards[key];
    if (c == null) return;
    c.box = known ? (c.box + 1).clamp(1, 5) : 1;
    c.due = today() + (known ? boxDays[c.box] : 0);
    final p = key.split('|');
    visual['dl:${p[0]}:${p[1]}'] = known;
    save();
  }

  void removeCard(String id) {
    cards.remove(id);
    save();
  }

  /// İçerikten kaldırılan maddelere ait kart ve favorileri temizler (notlar korunur).
  void prune(bool Function(String id) exists) {
    final before = cards.length + favorites.length;
    cards.removeWhere((id, _) => !exists(id));
    favorites.removeWhere((id) => !exists(id));
    if (cards.length + favorites.length != before) save();
  }

  List<String> dueCards() {
    final t = today();
    final l = cards.entries.where((e) => e.value.due <= t).map((e) => e.key).toList();
    l.sort((a, b) => cards[a]!.box.compareTo(cards[b]!.box));
    return l;
  }

  void grade(String id, bool known) {
    final c = cards[id];
    if (c == null) return;
    c.box = known ? (c.box + 1).clamp(1, 5) : 1;
    c.due = today() + (known ? boxDays[c.box] : 0);
    save();
  }

  // ---------------- test ----------------
  void markQuiz(Question q, bool right) {
    final k = qKey(q);
    if (right) {
      if (quizWrong.containsKey(k)) quizWrong[k] = (quizWrong[k]! - 1).clamp(0, 99);
      if (quizWrong[k] == 0) quizWrong.remove(k);
    } else {
      quizWrong[k] = (quizWrong[k] ?? 0) + 1;
    }
    save();
  }

  bool isWrongBefore(Question q) => quizWrong.containsKey(qKey(q));

  /// Deneme sonucunu kaydeder; yanlış ve boş soruları "Yanlışlarım"a ekler.
  Future<void> addDeneme(DenemeResult d, List<Question> qs, List<int?> answers) async {
    for (var i = 0; i < qs.length; i++) {
      final k = qKey(qs[i]);
      if (answers[i] == qs[i].answer) {
        if (quizWrong.containsKey(k)) quizWrong[k] = (quizWrong[k]! - 1).clamp(0, 99);
        if (quizWrong[k] == 0) quizWrong.remove(k);
      } else {
        quizWrong[k] = (quizWrong[k] ?? 0) + 1;
      }
    }
    denemeler.insert(0, d);
    if (denemeler.length > 50) denemeler.removeLast();
    await save();
  }

  // ---------------- yedek ----------------
  @visibleForTesting
  void replaceAllSync(Map<String, dynamic> j) => _fromJson(j);

  Future<void> replaceAll(Map<String, dynamic> j) async {
    _fromJson(j);
    await save();
  }
}

/// Bir deneme sınavının özeti. [areas]: alan -> [doğru, yanlış, boş]
class DenemeResult {
  final int time; // millisecondsSinceEpoch
  final int seconds; // harcanan süre
  final Map<String, List<int>> areas;
  DenemeResult(this.time, this.seconds, this.areas);

  int _sum(int i) => areas.values.fold(0, (a, v) => a + v[i]);
  int get right => _sum(0);
  int get wrong => _sum(1);
  int get empty => _sum(2);
  int get total => right + wrong + empty;

  factory DenemeResult.fromJson(Map<String, dynamic> j) => DenemeResult(
        (j['t'] as num).toInt(),
        (j['s'] as num?)?.toInt() ?? 0,
        (j['a'] as Map).map((k, v) => MapEntry(k as String, (v as List).map((x) => (x as num).toInt()).toList())),
      );
  Map<String, dynamic> toJson() => {'t': time, 's': seconds, 'a': areas};
}
