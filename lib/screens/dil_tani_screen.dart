import 'package:flutter/material.dart';

import '../app_state.dart';
import '../dil.dart';
import '../tts.dart';
import '../widgets/read_bar.dart';
import 'dil_screen.dart' show LangBlocks;

/// Tanı testi: Türkçe kelime gelir, üç dilde hangilerini bilmediğini işaretlersin.
class DilTaniScreen extends StatefulWidget {
  const DilTaniScreen({super.key});

  @override
  State<DilTaniScreen> createState() => _DilTaniScreenState();
}

class _DilTaniScreenState extends State<DilTaniScreen> {
  List<Cumle>? _deck;
  int _i = 0;
  bool _shown = false;
  final List<bool> _known = [true, true, true];
  int _done = 0;

  @override
  void initState() {
    super.initState();
    DilVeri.load().then((v) {
      if (!mounted) return;
      final pool = [
        for (final g in v.gruplar.where((g) => g.bolum == 'C' || g.bolum == 'B')) ...g.items,
      ].where((c) => !store.visual.containsKey('dl:${c.id}:0') && !store.visual.containsKey('dl:${c.id}:1') && !store.visual.containsKey('dl:${c.id}:2')).toList()
        ..shuffle();
      setState(() => _deck = pool.take(30).toList());
    });
  }

  void _next() {
    final c = _deck![_i];
    for (var l = 0; l < 3; l++) {
      store.dilMark(c.id, l, _known[l]);
    }
    setState(() {
      _i++;
      _done++;
      _shown = false;
      _known.setAll(0, [true, true, true]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final deck = _deck;
    return Readable(
      label: 'Tanı testi',
      items: () => [ReadItem('Tanı testi', 'Türkçe kelimeyi gör, üç dilde söylemeye çalış, sonra bilmediklerini işaretle.')],
      child: Scaffold(
        appBar: AppBar(title: const Text('Tanı testi')),
        body: deck == null
            ? const Center(child: CircularProgressIndicator())
            : deck.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Taranmamış kelime kalmadı. "Eksik haritası"na bak.', textAlign: TextAlign.center)))
                : _i >= deck.length
                    ? ListView(padding: const EdgeInsets.all(20), children: [
                        Text('$_done kelime tarandı.', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        const Text('Bilmediklerin Dil tekrarı kartlarına eklendi. Eksik haritasında dil ve temaya göre nerede açık olduğunu görebilirsin.'),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DilHaritaScreen())),
                          child: const Text('Eksik haritasını gör'),
                        ),
                      ])
                    : _body(deck[_i], deck.length),
      ),
    );
  }

  Widget _body(Cumle c, int n) => ListView(padding: const EdgeInsets.all(14), children: [
        Text('${_i + 1} / $n', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        Center(child: Text(c.emoji, style: const TextStyle(fontSize: 60))),
        Center(child: Text(c.turkish, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
        const SizedBox(height: 6),
        const Center(child: Text('Üç dilde söylemeyi dene.', style: TextStyle(fontSize: 12.5, color: Colors.grey))),
        const SizedBox(height: 12),
        if (!_shown) FilledButton.icon(onPressed: () => setState(() => _shown = true), icon: const Icon(Icons.visibility), label: const Text('Cevapları göster')),
        if (_shown) ...[
          LangBlocks(c: c),
          const SizedBox(height: 10),
          const Text('Bilmediklerine dokun (kırmızı olur):', style: TextStyle(fontWeight: FontWeight.w700)),
          Wrap(spacing: 8, children: [
            for (var l = 0; l < 3; l++)
              FilterChip(
                label: Text('${dilTanimlari[l].flag} ${dilTanimlari[l].name}'),
                selected: !_known[l],
                selectedColor: const Color(0x55B3402F),
                onSelected: (v) => setState(() => _known[l] = !v),
              ),
          ]),
          const SizedBox(height: 12),
          FilledButton(onPressed: _next, child: const Text('Sonraki')),
        ],
      ]);
}

/// Dil ve temaya göre bildim / bilmedim / taranmadı sayıları.
class DilHaritaScreen extends StatelessWidget {
  const DilHaritaScreen({super.key});

  @override
  Widget build(BuildContext context) => Readable(
        label: 'Eksik haritası',
        items: () => [ReadItem('Eksik haritası', 'Her dil ve tema için bildiğin, bilmediğin ve taranmamış kelime sayıları.')],
        child: Scaffold(
          appBar: AppBar(title: const Text('Eksik haritası')),
          body: FutureBuilder<DilVeri>(
            future: DilVeri.load(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final v = snap.data!;
              final themes = v.gruplar.where((g) => g.bolum == 'C' || g.bolum == 'B').toList();
              return AnimatedBuilder(
                animation: store,
                builder: (context, _) => ListView(padding: const EdgeInsets.all(14), children: [
                  const Text('🟢 biliyorum · 🔴 bilmiyorum · ⚪ taranmadı', style: TextStyle(fontSize: 12.5)),
                  for (var l = 0; l < 3; l++) ...[
                    const SizedBox(height: 14),
                    Builder(builder: (context) {
                      var k = 0, u = 0, n = 0;
                      for (final g in themes) {
                        for (final c in g.items) {
                          final s = store.visual['dl:${c.id}:$l'];
                          if (s == null) {
                            n++;
                          } else if (s) {
                            k++;
                          } else {
                            u++;
                          }
                        }
                      }
                      return Text('${dilTanimlari[l].flag} ${dilTanimlari[l].name}: $k bildim · $u eksik · $n taranmadı', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15));
                    }),
                    for (final g in themes)
                      Builder(builder: (context) {
                        var k = 0, u = 0, n = 0;
                        for (final c in g.items) {
                          final s = store.visual['dl:${c.id}:$l'];
                          if (s == null) {
                            n++;
                          } else if (s) {
                            k++;
                          } else {
                            u++;
                          }
                        }
                        Widget bar(int f, Color col) => f == 0 ? const SizedBox.shrink() : Expanded(flex: f, child: Container(height: 10, color: col));
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(children: [
                            SizedBox(width: 130, child: Text('${g.icon} ${g.title}', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Row(children: [bar(k, const Color(0xFF3F7A3A)), bar(u, const Color(0xFFB3402F)), bar(n, const Color(0xFFDDDDDD))]),
                              ),
                            ),
                          ]),
                        );
                      }),
                  ],
                ]),
              );
            },
          ),
        ),
      );
}

/// Aralıklı tekrar: eksik işaretlenen dil/kelime çiftleri geri gelir (en fazla 20'şer).
class DilTekrarScreen extends StatefulWidget {
  const DilTekrarScreen({super.key});

  @override
  State<DilTekrarScreen> createState() => _DilTekrarScreenState();
}

class _DilTekrarScreenState extends State<DilTekrarScreen> {
  List<String> _queue = [];
  DilVeri? _v;
  int _i = 0;
  bool _shown = false;
  int _right = 0, _wrong = 0;

  @override
  void initState() {
    super.initState();
    DilVeri.load().then((v) {
      if (mounted) setState(() { _v = v; _queue = store.dueDil().take(20).toList(); });
    });
  }

  void _mark(bool ok) {
    store.dilGrade(_queue[_i], ok);
    setState(() {
      ok ? _right++ : _wrong++;
      _i++;
      _shown = false;
    });
  }

  @override
  Widget build(BuildContext context) => Readable(
        label: 'Dil tekrarı',
        items: () => [ReadItem('Dil tekrarı', 'Bilmediğin kelimeler aralıklarla geri gelir.')],
        child: Scaffold(
          appBar: AppBar(title: const Text('Dil tekrarı')),
          body: _v == null
              ? const Center(child: CircularProgressIndicator())
              : _queue.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Bugün tekrar edecek kart yok. Tanı testi yaparak eksiklerini bul.', textAlign: TextAlign.center)))
                  : _i >= _queue.length
                      ? Center(child: Text('Bitti: $_right bildim, $_wrong bilemedim.\nBekleyen: ${store.dueDil().length}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)))
                      : _card(),
        ),
      );

  Widget _card() {
    final p = _queue[_i].split('|');
    final c = _v!.byId(p[0]);
    final l = int.parse(p[1]);
    if (c == null) {
      store.dilCards.remove(_queue[_i]);
      WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _i++));
      return const SizedBox.shrink();
    }
    return ListView(padding: const EdgeInsets.all(14), children: [
      Text('${_i + 1} / ${_queue.length} · kutu ${store.dilCards[_queue[_i]]?.box ?? 1}', style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 8),
      Center(child: Text(c.emoji, style: const TextStyle(fontSize: 56))),
      Center(child: Text(c.turkish, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
      const SizedBox(height: 6),
      Center(child: Text('${dilTanimlari[l].flag} ${dilTanimlari[l].name} nasıl denir?', style: const TextStyle(fontSize: 14))),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: () => setState(() => _shown = true), icon: const Icon(Icons.visibility), label: const Text('Cevabı göster')),
      if (_shown) ...[
        LangBlocks(c: c, only: l),
        if (c.hook.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('🎬 ${c.hook}', style: const TextStyle(fontSize: 13.5))),
      ],
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => _mark(false), child: const Text('Bilemedim'))),
        const SizedBox(width: 10),
        Expanded(child: FilledButton(onPressed: () => _mark(true), child: const Text('Bildim'))),
      ]),
    ]);
  }
}
