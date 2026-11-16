import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'app_state.dart';
import 'content.dart';

/// Sesle okunacak bir parça: bir madde, bir soru veya bir not.
class ReadItem {
  final String title;
  final String text;
  final String? entryId;
  final String area;
  const ReadItem(this.title, this.text, {this.entryId, this.area = 'hadis'});
}

/// Bir maddeyi okunacak parçaya çevirir.
ReadItem? entryItem(String id) {
  final e = store.resolve(content, id);
  if (e == null) return null;
  return ReadItem(e.title, speechText(e, notes: store.notesFor(e.id).map((n) => n.text).toList()), entryId: id, area: e.area);
}

/// Test sorusunu okunacak metne çevirir. [withAnswer] ise doğru cevap ve açıklama da okunur.
ReadItem questionItem(Question q, {int? no, bool withAnswer = false, int? chosen}) {
  const letters = ['A', 'B', 'C', 'D', 'E'];
  final b = StringBuffer(no == null ? 'Soru.\n' : '$no. soru.\n');
  b.writeln('${clean(q.text)}.');
  for (var k = 0; k < q.options.length; k++) {
    b.writeln('${letters[k]} şıkkı: ${clean(q.options[k])}.');
  }
  if (withAnswer) {
    if (chosen != null) b.writeln(chosen == q.answer ? 'Senin cevabın doğru.' : 'Senin cevabın ${letters[chosen]} idi.');
    b.writeln('Doğru cevap ${letters[q.answer]}: ${clean(q.options[q.answer])}.');
    if (q.explanation.isNotEmpty) b.writeln('Açıklama: ${clean(q.explanation)}.');
  }
  return ReadItem(no == null ? 'Soru' : '$no. soru', b.toString(), entryId: q.entryId.isEmpty ? null : q.entryId, area: q.area);
}

/// Maddeleri Türkçe sesle okur. Tek madde veya sıralı liste (ör. bir alanın tamamı) çalabilir.
class Reader extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool playing = false;
  bool turkishMissing = false;
  List<ReadItem> queue = [];
  int index = 0;
  double rate = 0.5; // Android'de 0.5 normal hız
  int _session = 0; // durdurulunca eski döngüyü kesmek için

  static const rates = [0.35, 0.45, 0.5, 0.6, 0.75];

  ReadItem? get current => playing && index < queue.length ? queue[index] : null;
  String? get currentId => current?.entryId;

  Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    try {
      await _tts.awaitSpeakCompletion(true);
      final ok = await _tts.isLanguageAvailable('tr-TR');
      turkishMissing = ok != true;
      await _tts.setLanguage('tr-TR');
      await _tts.setPitch(1.0);
    } catch (e) {
      debugPrint('tts: $e');
    }
  }

  Future<void> setRate(double r) async {
    rate = r;
    store.ttsRate = r;
    store.save();
    await _tts.setSpeechRate(r);
    notifyListeners();
  }

  void cycleRate() {
    final i = rates.indexOf(rate);
    setRate(rates[(i + 1) % rates.length]);
  }

  /// Tek bir maddeyi okur.
  Future<void> playEntry(String id) => playList([id]);

  /// Listeyi baştan (veya [start]'tan) sırayla okur.
  Future<void> playList(List<String> ids, {int start = 0}) =>
      playItems(ids.map(entryItem).whereType<ReadItem>().toList(), start: start);

  /// Hazır parçaları (madde, soru, not) sırayla okur.
  Future<void> playItems(List<ReadItem> items, {int start = 0}) async {
    await _init();
    await _tts.stop();
    rate = store.ttsRate;
    await _tts.setSpeechRate(rate);
    queue = items;
    if (queue.isEmpty) return;
    index = start.clamp(0, queue.length - 1);
    playing = true;
    final s = ++_session;
    notifyListeners();
    while (s == _session && index < queue.length) {
      for (final chunk in chunks(queue[index].text)) {
        if (s != _session) return;
        await _tts.speak(chunk);
      }
      if (s != _session) return;
      index++;
      notifyListeners();
    }
    if (s == _session) {
      playing = false;
      notifyListeners();
    }
  }

  Future<void> next() async {
    if (!playing || index + 1 >= queue.length) return stop();
    await playItems(queue, start: index + 1);
  }

  Future<void> previous() async {
    if (!playing) return;
    await playItems(queue, start: (index - 1).clamp(0, queue.length - 1));
  }

  Future<void> stop() async {
    _session++;
    playing = false;
    await _tts.stop();
    notifyListeners();
  }
}

final reader = Reader();

/// Madde metnini okunacak düz metne çevirir (bağlantı ve biçim işaretleri temizlenir).
String speechText(Entry e, {List<String> notes = const []}) {
  final b = StringBuffer('${e.title}.\n');
  if (e.summary.isNotEmpty) b.writeln('${clean(e.summary)}.');
  for (final raw in e.body.split('\n')) {
    final l = raw.trim();
    if (l.isEmpty) continue;
    if (RegExp(r'^\[\[https?://').hasMatch(l) || l.startsWith('http')) continue;
    if (l.startsWith('## ')) {
      b.writeln('${clean(l.substring(3))}.');
    } else if (l.startsWith('- ')) {
      b.writeln('${clean(l.substring(2))}.');
    } else if (l.startsWith('> ')) {
      b.writeln('İpucu: ${clean(l.substring(2))}.');
    } else if (l.startsWith('!! ')) {
      b.writeln('Dikkat: ${clean(l.substring(3))}.');
    } else if (l.startsWith('%% ')) {
      b.writeln('Akılda tut: ${clean(l.substring(3))}.');
    } else if (l.startsWith('&& ')) {
      final i = l.indexOf(' | ');
      b.writeln('Sahne: ${clean(i < 0 ? l.substring(3) : l.substring(i + 3))}.');
    } else {
      b.writeln('${clean(l)}.');
    }
  }
  final own = notes.where((n) => n.trim().isNotEmpty).toList();
  if (own.isNotEmpty) {
    b.writeln('Senin notların.');
    for (final n in own) {
      b.writeln('${clean(n)}.');
    }
  }
  return b.toString().replaceAll(RegExp(r'\.\.+'), '.').replaceAllMapped(RegExp(r'([:;!?])\.'), (m) => m.group(1)!);
}

String clean(String s) {
  var t = s.replaceAllMapped(linkRe, (m) => m.group(2) ?? (m.group(1)!.startsWith('http') ? '' : m.group(1)!));
  t = t.replaceAll('**', '');
  t = t.replaceAll(RegExp(r'https?://\S+'), '');
  t = t.replaceAll('→', ', ').replaceAll('↔', ' ile ').replaceAll('·', ', ').replaceAll('✔', 'doğru: ').replaceAll('✘', 'yanlış: ');
  t = t.replaceAll('≥', 'en az ').replaceAll(' – ', ', ').replaceAll('—', ', ');
  t = t.replaceAllMapped(RegExp(r'(\d+)/(\d+)'), (m) {
    final a = m.group(1)!, b = m.group(2)!;
    if (b.length >= 3) return 'hicri $a, miladi $b';
    const den = {'2': 'ikide', '3': 'üçte', '4': 'dörtte', '5': 'beşte', '6': 'altıda', '8': 'sekizde', '10': 'onda', '20': 'yirmide'};
    const num = {'1': 'bir', '2': 'iki'};
    if (den.containsKey(b) && num.containsKey(a)) return '${den[b]} ${num[a]}';
    return '$a bölü $b';
  });
  t = t.replaceAll('/', ' ya da ');
  t = t.replaceAll(RegExp(r'[؀-ۿ]+'), ''); // Arapça harfler Türkçe sesle okunamaz
  t = t.replaceAll(RegExp(r'\(\s*\)'), '').replaceAll(RegExp(r' {2,}'), ' ');
  return t.trim().replaceAll(RegExp(r'[.\s]+$'), '');
}

/// Android TTS tek seferde ~4000 karakter okur; satır sınırlarından bölerek parçalar.
List<String> chunks(String text, {int max = 1500}) {
  final out = <String>[];
  final b = StringBuffer();
  for (final line in text.split('\n')) {
    if (b.length + line.length > max && b.isNotEmpty) {
      out.add(b.toString());
      b.clear();
    }
    b.writeln(line);
  }
  if (b.isNotEmpty) out.add(b.toString());
  return out;
}
