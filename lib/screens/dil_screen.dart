import 'package:flutter/material.dart';

import '../app_state.dart';
import '../dil.dart';
import '../tts.dart';
import '../widgets/photo_bar.dart';
import '../widgets/read_bar.dart';

const _arabicFonts = ['Noto Naskh Arabic', 'Droid Arabic Naskh', 'Amiri', 'Traditional Arabic', 'Geeza Pro'];
const _langColors = [Color(0x1A2B5FA8), Color(0x1AB3402F), Color(0x1A3F7A3A)];

Future<void> _say(Cumle c, int i) {
  final d = dilTanimlari[i];
  return reader.sayPhrase(c.texts[i], d.voice, fallback: d.fallback);
}

/// Bir satırın üç dilini alt alta gösterir. [only] verilirse yalnız o dil (sınav odağı).
class LangBlocks extends StatelessWidget {
  final Cumle c;
  final int? only;
  const LangBlocks({super.key, required this.c, this.only});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < 3; i++)
          if (only == null || only == i)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
              decoration: BoxDecoration(color: _langColors[i], borderRadius: BorderRadius.circular(8)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(dilTanimlari[i].flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: dilTanimlari[i].rtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.texts[i],
                        textDirection: dilTanimlari[i].rtl ? TextDirection.rtl : TextDirection.ltr,
                        style: dilTanimlari[i].rtl
                            ? const TextStyle(fontSize: 26, height: 1.9, fontWeight: FontWeight.w600, fontFamilyFallback: _arabicFonts)
                            : const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w800, height: 1.3),
                      ),
                      Text('🔊 ${c.readings[i]}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF7A4E9A), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                IconButton(visualDensity: VisualDensity.compact, onPressed: () => _say(c, i), icon: const Icon(Icons.volume_up, size: 20), tooltip: 'Dinle'),
              ]),
            ),
      ]);
}

class DilScreen extends StatelessWidget {
  const DilScreen({super.key});

  @override
  Widget build(BuildContext context) => Readable(
        label: 'Dil bölümü',
        items: () => [ReadItem('Dil bölümü', 'Boşnakça, İngilizce ve Arapça cümle ve kelimeler, üç dil alt alta, görsel hikâyelerle.')],
        child: Scaffold(
          appBar: AppBar(title: const Text('Dil bölümü')),
          body: FutureBuilder<DilVeri>(
            future: DilVeri.load(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final v = snap.data!;
              return AnimatedBuilder(
                animation: store,
                builder: (context, _) => ListView(padding: const EdgeInsets.all(14), children: [
                  const Text('🇧🇦 Boşnakça · 🇬🇧 İngilizce · 🇸🇦 Arapça — her cümle ve kelime üçü alt alta, okunuşu, kancası ve görseliyle.', style: TextStyle(fontSize: 13.5, height: 1.4)),
                  for (final b in v.bolumler) ...[
                    const SizedBox(height: 14),
                    Text(b.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text(b.desc, style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
                    for (final g in v.of(b.id))
                      Card(
                        child: ListTile(
                          leading: Text(g.icon, style: const TextStyle(fontSize: 30)),
                          title: Text(g.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${g.items.length} ${g.sirali ? 'sahne' : 'kelime'} · ${g.items.where((c) => store.visual['dil:${c.id}'] == true).length} bildim'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DilCalisScreen(grup: g))),
                        ),
                      ),
                  ],
                ]),
              );
            },
          ),
        ),
      );
}

class DilCalisScreen extends StatefulWidget {
  final DilGrup grup;
  final bool sinaBasla;
  const DilCalisScreen({super.key, required this.grup, this.sinaBasla = false});

  @override
  State<DilCalisScreen> createState() => _DilCalisScreenState();
}

class _DilCalisScreenState extends State<DilCalisScreen> {
  late bool _quiz = widget.sinaBasla;
  late bool _shuffle = !widget.grup.sirali;
  bool _onlyUnknown = false;
  int? _focus; // null: üç dil, 0..2: tek dil
  int _i = 0;
  bool _shown = false;
  int _right = 0, _wrong = 0;
  late List<Cumle> _deck = _makeDeck();

  DilGrup get g => widget.grup;

  List<Cumle> _makeDeck() {
    var l = [...g.items];
    if (_onlyUnknown) l = l.where((c) => store.visual['dil:${c.id}'] != true).toList();
    if (_shuffle) l.shuffle();
    return l;
  }

  void _restart() => setState(() {
        _deck = _makeDeck();
        _i = 0;
        _shown = false;
        _right = _wrong = 0;
      });

  void _mark(bool ok) {
    store.markVisual('dil:${_deck[_i].id}', ok, '');
    setState(() {
      ok ? _right++ : _wrong++;
      _i++;
      _shown = false;
    });
  }

  Future<void> _sayAll(Cumle c) async {
    for (var i = 0; i < 3; i++) {
      await _say(c, i);
    }
  }

  @override
  Widget build(BuildContext context) => Readable(
        label: g.title,
        items: () => [
          ReadItem(g.title, g.story),
          for (final c in g.items) ReadItem(c.turkish, '${c.turkish}. ${c.hook}'),
        ],
        child: Scaffold(
          appBar: AppBar(title: Text('${g.icon} ${g.title}', style: const TextStyle(fontSize: 16))),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Gez'), icon: Icon(Icons.style)),
                  ButtonSegment(value: true, label: Text('Sına'), icon: Icon(Icons.psychology)),
                ],
                selected: {_quiz},
                onSelectionChanged: (v) {
                  _quiz = v.first;
                  _restart();
                },
              ),
            ),
            Expanded(child: _quiz ? _sina() : _gez()),
          ]),
        ),
      );

  Widget _gez() => ListView(padding: const EdgeInsets.all(12), children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0x1AFFC83D), borderRadius: BorderRadius.circular(10)),
          child: Text('${g.icon} ${g.story}', style: const TextStyle(fontSize: 13.5, height: 1.4)),
        ),
        for (var n = 0; n < g.items.length; n++) ...[
          if (g.sirali && n > 0) const Center(child: Text('⬇️', style: TextStyle(fontSize: 18))),
          _card(g.items[n], n),
        ],
      ]);

  Widget _card(Cumle c, int n) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              if (g.sirali) CircleAvatar(radius: 12, backgroundColor: const Color(0xFF7A4E9A), child: Text('${n + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
              if (g.sirali) const SizedBox(width: 8),
              Text(c.emoji, style: const TextStyle(fontSize: 32)),
              const Spacer(),
              if (store.visual['dil:${c.id}'] == true) const Icon(Icons.check_circle, color: Color(0xFF3F7A3A), size: 20),
              IconButton(onPressed: () => _sayAll(c), icon: const Icon(Icons.play_circle_outline), tooltip: 'Üçünü sırayla dinle'),
            ]),
            Text(c.turkish, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
            LangBlocks(c: c),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0x1AFFC83D), borderRadius: BorderRadius.circular(8)),
              child: Text('🎬 ${c.hook}', style: const TextStyle(fontSize: 13.5, height: 1.35)),
            ),
            PhotoBar(slot: 'd:${c.id}', label: 'Kendi resmini ekle'),
          ]),
        ),
      );

  Widget _sina() {
    if (_deck.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Bilmediğin satır kalmadı. "Yalnız bilemediklerim"i kapatabilirsin.', textAlign: TextAlign.center)));
    }
    final chips = Wrap(spacing: 8, runSpacing: 0, children: [
      FilterChip(label: const Text('Karıştır'), selected: _shuffle, onSelected: (v) { _shuffle = v; _restart(); }),
      FilterChip(label: const Text('Yalnız bilemediklerim'), selected: _onlyUnknown, onSelected: (v) { _onlyUnknown = v; _restart(); }),
      for (final e in [(null, 'Üçü'), (0, '🇧🇦'), (1, '🇬🇧'), (2, '🇸🇦')])
        ChoiceChip(label: Text(e.$2), selected: _focus == e.$1, onSelected: (_) => setState(() => _focus = e.$1)),
    ]);
    if (_i >= _deck.length) {
      return ListView(padding: const EdgeInsets.all(14), children: [
        chips,
        const SizedBox(height: 20),
        Center(child: Text('Bitti: $_right bildim, $_wrong bilemedim.', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
        const SizedBox(height: 12),
        Center(child: FilledButton(onPressed: _restart, child: const Text('Baştan'))),
      ]);
    }
    final c = _deck[_i];
    return ListView(padding: const EdgeInsets.all(14), children: [
      chips,
      const SizedBox(height: 8),
      Text('${_i + 1} / ${_deck.length}', style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 8),
      Center(child: Text(c.emoji, style: const TextStyle(fontSize: 56))),
      Center(child: Text(c.turkish, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
      const SizedBox(height: 6),
      const Center(child: Text('Önce kendin söyle (sahneyi gözünün önüne getir).', style: TextStyle(fontSize: 12.5, color: Colors.grey))),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: () => setState(() => _shown = true), icon: const Icon(Icons.visibility), label: const Text('Cevabı göster')),
      if (_shown) ...[
        LangBlocks(c: c, only: _focus),
        const SizedBox(height: 6),
        Text('🎬 ${c.hook}', style: const TextStyle(fontSize: 13.5, height: 1.35)),
      ],
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => _mark(false), child: const Text('Bilemedim'))),
        const SizedBox(width: 10),
        Expanded(child: FilledButton(onPressed: () => _mark(true), child: const Text('Bildim'))),
      ]),
    ]);
  }
}
