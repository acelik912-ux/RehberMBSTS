import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../content.dart';
import '../store.dart';

const denemeMinutes = 90;
const _letters = ['A', 'B', 'C', 'D', 'E'];

/// Gerçek dağılıma göre soru seçer: Fıkıh 20, Kur'an 7, Tefsir 7, Kelam 7, Hadis 7, Siyer 7, Mezhepler 3, Dinler 2.
List<Question> buildDeneme([Random? rnd]) {
  rnd ??= Random();
  final out = <Question>[];
  for (final a in areas.where((a) => a.questions > 0)) {
    final pool = content.questions.where((q) => q.area == a.id).toList()..shuffle(rnd);
    // Daha önce yanlış yapılan sorular biraz öne alınır.
    pool.sort((x, y) => (store.isWrongBefore(y) ? 1 : 0) - (store.isWrongBefore(x) ? 1 : 0));
    final take = pool.take(a.questions).toList()..shuffle(rnd);
    out.addAll(take);
  }
  return out;
}

String mmss(int sec) {
  final m = sec ~/ 60, s = sec % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class DenemeScreen extends StatefulWidget {
  const DenemeScreen({super.key});

  @override
  State<DenemeScreen> createState() => _DenemeScreenState();
}

class _DenemeScreenState extends State<DenemeScreen> {
  late final List<Question> _qs = buildDeneme();
  late final List<int?> _ans = List<int?>.filled(_qs.length, null);
  final _start = DateTime.now();
  Timer? _timer;
  int _i = 0;
  bool _done = false;

  int get _elapsed => DateTime.now().difference(_start).inSeconds;
  int get _left => max(0, denemeMinutes * 60 - _elapsed);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _done) return;
      if (_left == 0) {
        _finish();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_done) return;
    _done = true;
    _timer?.cancel();
    final res = <String, List<int>>{};
    for (var k = 0; k < _qs.length; k++) {
      final r = res.putIfAbsent(_qs[k].area, () => [0, 0, 0]);
      if (_ans[k] == null) {
        r[2]++;
      } else if (_ans[k] == _qs[k].answer) {
        r[0]++;
      } else {
        r[1]++;
      }
    }
    final d = DenemeResult(_start.millisecondsSinceEpoch, min(_elapsed, denemeMinutes * 60), res);
    await store.addDeneme(d, _qs, _ans);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => DenemeResultScreen(result: d, questions: _qs, answers: _ans)),
    );
  }

  Future<void> _askFinish() async {
    final empty = _ans.where((a) => a == null).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Denemeyi bitir'),
        content: Text(empty == 0 ? 'Bütün soruları cevapladın. Bitirilsin mi?' : '$empty soru boş. Yine de bitirilsin mi?\n(Yanlış doğruyu götürmez; boş bırakma!)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Devam et')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Bitir')),
        ],
      ),
    );
    if (ok == true) _finish();
  }

  void _grid() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            for (var k = 0; k < _qs.length; k++)
              SizedBox(
                width: 44,
                height: 40,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: _ans[k] != null ? areaById(_qs[k].area).color.withValues(alpha: 0.25) : null,
                    side: BorderSide(color: k == _i ? Theme.of(context).colorScheme.primary : Colors.grey, width: k == _i ? 2 : 1),
                  ),
                  onPressed: () {
                    Navigator.pop(c);
                    setState(() => _i = k);
                  },
                  child: Text('${k + 1}'),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_qs.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('Deneme')), body: const Center(child: Text('Soru yok.')));
    }
    final q = _qs[_i];
    final a = areaById(q.area);
    final answered = _ans.where((x) => x != null).length;
    final warn = _left < 10 * 60;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askFinish();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Soru ${_i + 1} / ${_qs.length}'),
          actions: [
            Center(
              child: Text(mmss(_left),
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: warn ? const Color(0xFFA8402F) : null)),
            ),
            IconButton(tooltip: 'Soru listesi', icon: const Icon(Icons.grid_view), onPressed: _grid),
            TextButton(onPressed: _askFinish, child: const Text('Bitir')),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(value: answered / _qs.length, color: a.color),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('${a.name} · cevaplanan $answered / ${_qs.length}', style: TextStyle(color: a.color, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(q.text, style: const TextStyle(fontSize: 18, height: 1.45, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            for (var k = 0; k < q.options.length; k++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: _ans[_i] == k ? a.color.withValues(alpha: 0.28) : Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _ans[_i] = _ans[_i] == k ? null : k),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        CircleAvatar(radius: 13, backgroundColor: a.color, child: Text(_letters[k], style: const TextStyle(color: Colors.white, fontSize: 12))),
                        const SizedBox(width: 12),
                        Expanded(child: Text(q.options[k], style: const TextStyle(fontSize: 16))),
                      ]),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _i == 0 ? null : () => setState(() => _i--),
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Önceki'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _i + 1 < _qs.length
                    ? FilledButton.icon(
                        onPressed: () => setState(() => _i++),
                        icon: const Icon(Icons.chevron_right),
                        label: const Text('Sonraki'),
                      )
                    : FilledButton.icon(onPressed: _askFinish, icon: const Icon(Icons.flag), label: const Text('Bitir')),
              ),
            ]),
            const SizedBox(height: 8),
            const Text('Seçtiğin şıkka tekrar dokunursan cevap silinir. Doğru cevaplar sonunda gösterilir.',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class DenemeResultScreen extends StatefulWidget {
  final DenemeResult result;
  final List<Question> questions;
  final List<int?> answers;
  const DenemeResultScreen({super.key, required this.result, required this.questions, required this.answers});

  @override
  State<DenemeResultScreen> createState() => _DenemeResultScreenState();
}

class _DenemeResultScreenState extends State<DenemeResultScreen> {
  bool _onlyMistakes = true;

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final idx = [
      for (var k = 0; k < widget.questions.length; k++)
        if (!_onlyMistakes || widget.answers[k] != widget.questions[k].answer) k
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Deneme sonucu')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          DenemeSummary(result: r),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Text('Cevap anahtarı', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
            FilterChip(
              label: const Text('Yalnız yanlış/boş'),
              selected: _onlyMistakes,
              onSelected: (v) => setState(() => _onlyMistakes = v),
            ),
          ]),
          const SizedBox(height: 6),
          if (idx.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Hepsi doğru. Tebrikler!')),
          for (final k in idx) _Review(no: k + 1, q: widget.questions[k], chosen: widget.answers[k]),
        ],
      ),
    );
  }
}

/// Alan alan doğru / yanlış / boş tablosu.
class DenemeSummary extends StatelessWidget {
  final DenemeResult result;
  const DenemeSummary({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final r = result;
    final pct = r.total == 0 ? 0 : (100 * r.right / r.total).round();
    TableRow row(List<String> c, {bool bold = false, Color? color}) => TableRow(children: [
          for (var k = 0; k < c.length; k++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
              child: Text(c[k],
                  textAlign: k == 0 ? TextAlign.left : TextAlign.center,
                  style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: color)),
            ),
        ]);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('${r.right}', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900)),
            Text(' / ${r.total}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('%$pct başarı', style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('Süre: ${mmss(r.seconds)}', style: const TextStyle(color: Colors.grey)),
            ]),
          ]),
          const Text('Yanlış doğruyu götürmez: net = doğru sayısı.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          Table(
            columnWidths: const {0: FlexColumnWidth(3)},
            children: [
              row(['Alan', 'D', 'Y', 'B'], bold: true),
              for (final a in areas)
                if (r.areas.containsKey(a.id)) row([a.name, '${r.areas[a.id]![0]}', '${r.areas[a.id]![1]}', '${r.areas[a.id]![2]}'], color: a.color),
              row(['Toplam', '${r.right}', '${r.wrong}', '${r.empty}'], bold: true),
            ],
          ),
          if (_weakest(r) != null) ...[
            const SizedBox(height: 8),
            Text('En çok kayıp: ${_weakest(r)} — bu alanın maddelerine ve yanlışlarına dön.', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ]),
      ),
    );
  }

  static String? _weakest(DenemeResult r) {
    String? best;
    var lost = 0;
    for (final a in areas) {
      final v = r.areas[a.id];
      if (v == null) continue;
      final l = v[1] + v[2];
      if (l > lost) {
        lost = l;
        best = a.name;
      }
    }
    return best;
  }
}

class _Review extends StatelessWidget {
  final int no;
  final Question q;
  final int? chosen;
  const _Review({required this.no, required this.q, required this.chosen});

  @override
  Widget build(BuildContext context) {
    final a = areaById(q.area);
    final ok = chosen == q.answer;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(ok ? Icons.check_circle : (chosen == null ? Icons.radio_button_unchecked : Icons.cancel),
                color: ok ? const Color(0xFF3F7A3A) : const Color(0xFFA8402F), size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text('$no. soru · ${a.name}', style: TextStyle(color: a.color, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 4),
          Text(q.text, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(chosen == null ? 'Boş bıraktın.' : 'Senin cevabın: ${_letters[chosen!]}) ${q.options[chosen!]}'),
          Text('Doğru cevap: ${_letters[q.answer]}) ${q.options[q.answer]}', style: const TextStyle(fontWeight: FontWeight.w700)),
          if (q.explanation.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(q.explanation, style: const TextStyle(color: Colors.grey))),
          if (q.entryId.isNotEmpty && entryExists(q.entryId))
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => openEntry(context, q.entryId),
                icon: const Icon(Icons.menu_book, size: 18),
                label: Text('Konuyu aç: ${store.resolve(content, q.entryId)!.title}'),
              ),
            ),
        ]),
      ),
    );
  }
}

/// Önceki denemelerin listesi.
class DenemeHistoryScreen extends StatelessWidget {
  const DenemeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = store.denemeler;
    return Scaffold(
      appBar: AppBar(title: const Text('Deneme geçmişi')),
      body: list.isEmpty
          ? const Center(child: Text('Henüz deneme çözmedin.'))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final d in list) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                    child: Text(_date(d.time), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  DenemeSummary(result: d),
                ],
              ],
            ),
    );
  }

  static String _date(int ms) {
    final t = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.day)}.${two(t.month)}.${t.year} ${two(t.hour)}:${two(t.minute)}';
  }
}
