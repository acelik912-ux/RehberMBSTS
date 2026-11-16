import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../hafiza.dart';
import '../tts.dart';
import '../widgets/read_bar.dart';

class GQ {
  final SemaMask sema;
  final int box;
  final List<String> options;
  final int answer;
  GQ(this.sema, this.box, this.options, this.answer);
}

/// Şemadan kapatılan bir kutunun ne olduğunu dört şıktan bulma sınavı.
List<GQ> buildGorselSorular(Hafiza h, [Random? rnd, int count = 10]) {
  rnd ??= Random();
  bool ok(MaskBox b) => b.text.length >= 2 && b.text.length <= 45;
  final cand = <(SemaMask, int)>[
    for (final s in h.semalar)
      for (var i = 0; i < s.boxes.length; i++)
        if (ok(s.boxes[i])) (s, i),
  ]..shuffle(rnd);
  final out = <GQ>[];
  for (final (s, i) in cand) {
    final right = s.boxes[i].text;
    // Yanlış şıklar başka şemalardan gelir; aynı görselde görünen yazıdan çıkarım yapılamasın.
    final other = <String>{
      for (final o in h.semalar)
        if (o.id != s.id)
          for (final b in o.boxes)
            if (ok(b) && b.text != right) b.text,
    }.toList()
      ..shuffle(rnd);
    final shownHere = {for (var k = 0; k < s.boxes.length; k++) if (k != i) s.boxes[k].text};
    final wrong = other.where((t) => !shownHere.contains(t)).take(3).toList();
    if (wrong.length < 3) continue;
    final opts = [...wrong, right]..shuffle(rnd);
    out.add(GQ(s, i, opts, opts.indexOf(right)));
    if (out.length >= count) break;
  }
  return out;
}

class GorselSoruScreen extends StatefulWidget {
  const GorselSoruScreen({super.key});

  @override
  State<GorselSoruScreen> createState() => _GorselSoruScreenState();
}

class _GorselSoruScreenState extends State<GorselSoruScreen> {
  List<GQ>? _qs;
  int _i = 0, _right = 0;
  int? _chosen;

  @override
  void initState() {
    super.initState();
    Hafiza.load().then((h) {
      if (mounted) setState(() => _qs = buildGorselSorular(h));
    });
  }

  void _pick(int k) {
    final q = _qs![_i];
    final ok = k == q.answer;
    final b = q.sema.boxes[q.box];
    store.markVisual('${q.sema.id}|${q.box}', ok, entryExists(b.entryId) ? b.entryId : '');
    setState(() {
      _chosen = k;
      if (ok) _right++;
    });
  }

  Widget _image(GQ q, double w) {
    final h = w / q.sema.aspect;
    const pad = 0.004;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(children: [
        Positioned.fill(child: Image.asset('assets/sema/${q.sema.id}.png', fit: BoxFit.fill)),
        if (_chosen == null)
          for (final r in q.sema.boxes[q.box].rects)
            Positioned(
              left: (r.left - pad) * w,
              top: (r.top - pad) * h,
              width: (r.width + 2 * pad) * w,
              height: (r.height + 2 * pad) * h,
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFF7A4E9A), borderRadius: BorderRadius.circular(3), border: Border.all(color: const Color(0xFFFFC83D), width: 2.5)),
              ),
            ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qs = _qs;
    return Readable(
      label: 'Görselden soru',
      items: () => [ReadItem('Görselden soru', 'Şemada sarı çerçeveli kutu kapalı. Ne yazdığını dört şıktan bul.')],
      child: Scaffold(
        appBar: AppBar(title: const Text('Görselden soru')),
        body: qs == null
            ? const Center(child: CircularProgressIndicator())
            : _i >= qs.length
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('$_right / ${qs.length} doğru', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        const Text('Yanlışlarının maddeleri Tekrar kartlarına eklendi.'),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: () => Hafiza.load().then((h) => setState(() {
                                _qs = buildGorselSorular(h);
                                _i = 0;
                                _right = 0;
                                _chosen = null;
                              })),
                          child: const Text('Yeni set'),
                        ),
                      ]),
                    ),
                  )
                : ListView(padding: const EdgeInsets.all(12), children: [
                    Text('Soru ${_i + 1} / ${qs.length} · ${qs[_i].sema.title}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 6),
                    LayoutBuilder(builder: (context, c) => ClipRRect(borderRadius: BorderRadius.circular(8), child: _image(qs[_i], c.maxWidth))),
                    const SizedBox(height: 10),
                    const Text('Sarı çerçeveli kapalı kutuda ne yazıyordu?', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    for (var k = 0; k < qs[_i].options.length; k++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.all(12),
                            backgroundColor: _chosen == null
                                ? null
                                : k == qs[_i].answer
                                    ? const Color(0x333F7A3A)
                                    : k == _chosen
                                        ? const Color(0x33A8402F)
                                        : null,
                          ),
                          onPressed: _chosen == null ? () => _pick(k) : null,
                          child: Text(qs[_i].options[k], style: const TextStyle(fontSize: 14.5)),
                        ),
                      ),
                    if (_chosen != null)
                      FilledButton(onPressed: () => setState(() { _i++; _chosen = null; }), child: Text(_i + 1 == qs.length ? 'Bitir' : 'Sonraki')),
                  ]),
      ),
    );
  }
}
