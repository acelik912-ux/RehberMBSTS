import 'package:flutter/material.dart';

import '../app_state.dart';
import '../dil.dart';
import '../tts.dart';
import '../widgets/photo_bar.dart';
import '../widgets/read_bar.dart';

String _fallback(String voice) => voice.startsWith('bs') ? 'hr-HR' : voice;

class DilScreen extends StatelessWidget {
  const DilScreen({super.key});

  @override
  Widget build(BuildContext context) => Readable(
        label: 'Dil bölümü',
        items: () => [ReadItem('Dil bölümü', 'Boşnakça, İngilizce ve Arapça cümleleri görsellerle ezberle.')],
        child: Scaffold(
          appBar: AppBar(title: const Text('Dil bölümü')),
          body: FutureBuilder<List<Dil>>(
            future: Dil.load(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              return AnimatedBuilder(
                animation: store,
                builder: (context, _) => ListView(padding: const EdgeInsets.all(14), children: [
                  const Text(
                    'Her cümlenin görseli, okunuşu ve Türkçe ses benzetmesi (kanca) var. Önce gez, sonra kapatıp sına; hoparlörle doğru söylenişi dinle.',
                    style: TextStyle(fontSize: 13.5, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  for (final d in snap.data!)
                    Card(
                      child: ListTile(
                        leading: Text(d.flag, style: const TextStyle(fontSize: 34)),
                        title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                        subtitle: Text('${d.count} cümle · ${d.all.where((c) => store.visual['dil:${c.id}'] == true).length} bildim'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DilKategorilerScreen(dil: d))),
                      ),
                    ),
                ]),
              );
            },
          ),
        ),
      );
}

class DilKategorilerScreen extends StatelessWidget {
  final Dil dil;
  const DilKategorilerScreen({super.key, required this.dil});

  @override
  Widget build(BuildContext context) => Readable(
        label: dil.name,
        items: () => [ReadItem(dil.name, dil.note)],
        child: Scaffold(
          appBar: AppBar(title: Text('${dil.flag} ${dil.name}')),
          body: AnimatedBuilder(
            animation: store,
            builder: (context, _) => ListView(padding: const EdgeInsets.all(14), children: [
              Text(dil.note, style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
              const SizedBox(height: 8),
              for (final k in dil.categories)
                Card(
                  child: ListTile(
                    leading: Text(k.icon, style: const TextStyle(fontSize: 28)),
                    title: Text(k.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${k.phrases.length} cümle · ${k.phrases.where((c) => store.visual['dil:${c.id}'] == true).length} bildim'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DilCalisScreen(dil: dil, kat: k))),
                  ),
                ),
              const SizedBox(height: 6),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DilCalisScreen(dil: dil, kat: DilKategori('${dil.id}-hepsi', 'Tüm cümleler', '📚', dil.all), sinaBasla: true)),
                ),
                icon: const Icon(Icons.psychology),
                label: const Text('Hepsinden sına'),
              ),
            ]),
          ),
        ),
      );
}

class DilCalisScreen extends StatefulWidget {
  final Dil dil;
  final DilKategori kat;
  final bool sinaBasla;
  const DilCalisScreen({super.key, required this.dil, required this.kat, this.sinaBasla = false});

  @override
  State<DilCalisScreen> createState() => _DilCalisScreenState();
}

class _DilCalisScreenState extends State<DilCalisScreen> {
  late bool _quiz = widget.sinaBasla;
  bool _onlyUnknown = false;
  bool _reverse = false; // false: Türkçe+görsel -> cümleyi hatırla; true: cümle -> Türkçe
  int _i = 0;
  bool _shown = false;
  int _right = 0, _wrong = 0;
  late List<Cumle> _deck = _makeDeck();

  List<Cumle> _makeDeck() {
    var l = [...widget.kat.phrases];
    if (_onlyUnknown) l = l.where((c) => store.visual['dil:${c.id}'] != true).toList();
    return l..shuffle();
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

  void _say(Cumle c) => reader.sayPhrase(c.native, widget.dil.voice, fallback: _fallback(widget.dil.voice));

  TextDirection get _dir => widget.dil.rtl ? TextDirection.rtl : TextDirection.ltr;

  @override
  Widget build(BuildContext context) => Readable(
        label: widget.kat.title,
        items: () => [for (final c in widget.kat.phrases) ReadItem(c.turkish, '${c.turkish}. Okunuşu: ${c.reading}. ${c.hook}')],
        child: Scaffold(
          appBar: AppBar(title: Text('${widget.dil.flag} ${widget.kat.title}', style: const TextStyle(fontSize: 16))),
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
        for (final c in widget.kat.phrases)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Text(c.emoji, style: const TextStyle(fontSize: 34)),
                  const Spacer(),
                  if (store.visual['dil:${c.id}'] == true) const Icon(Icons.check_circle, color: Color(0xFF3F7A3A), size: 20),
                  IconButton(onPressed: () => _say(c), icon: const Icon(Icons.volume_up), tooltip: 'Dinle'),
                ]),
                Text(c.native, textDirection: _dir, textAlign: widget.dil.rtl ? TextAlign.right : TextAlign.left, style: TextStyle(fontSize: widget.dil.rtl ? 28 : 22, fontWeight: FontWeight.w800, height: 1.3)),
                const SizedBox(height: 4),
                Text('🔊 ${c.reading}', style: const TextStyle(fontSize: 14.5, color: Color(0xFF7A4E9A), fontWeight: FontWeight.w600)),
                Text(c.turkish, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0x1AFFC83D), borderRadius: BorderRadius.circular(8)),
                  child: Text('💡 ${c.hook}', style: const TextStyle(fontSize: 13.5, height: 1.35)),
                ),
                PhotoBar(slot: 'd:${c.id}', label: 'Kendi resmini ekle'),
              ]),
            ),
          ),
      ]);

  Widget _sina() {
    if (_deck.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Bilmediğin cümle kalmadı. Aşağıdan "Hepsi"ni seçebilirsin.', textAlign: TextAlign.center)));
    }
    if (_i >= _deck.length) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Bitti: $_right bildim, $_wrong bilemedim.', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _restart, child: const Text('Tekrar karıştır')),
          ]),
        ),
      );
    }
    final c = _deck[_i];
    return ListView(padding: const EdgeInsets.all(14), children: [
      Wrap(spacing: 8, children: [
        FilterChip(label: const Text('Yalnız bilemediklerim'), selected: _onlyUnknown, onSelected: (v) { _onlyUnknown = v; _restart(); }),
        FilterChip(label: const Text('Cümle → Türkçe'), selected: _reverse, onSelected: (v) { _reverse = v; _restart(); }),
      ]),
      const SizedBox(height: 8),
      Text('${_i + 1} / ${_deck.length}', style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 10),
      if (!_reverse) ...[
        Center(child: Text(c.emoji, style: const TextStyle(fontSize: 56))),
        Center(child: Text(c.turkish, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
        const SizedBox(height: 6),
        const Center(child: Text('Bunu hedef dilde söyle (gözünün önüne sahneyi getir).', style: TextStyle(fontSize: 12.5, color: Colors.grey))),
      ] else ...[
        Center(child: Text(c.native, textDirection: _dir, textAlign: TextAlign.center, style: TextStyle(fontSize: widget.dil.rtl ? 32 : 24, fontWeight: FontWeight.w800))),
        const SizedBox(height: 6),
        const Center(child: Text('Türkçesi ne? Sonra görseli ve kancayı hatırla.', style: TextStyle(fontSize: 12.5, color: Colors.grey))),
      ],
      const SizedBox(height: 14),
      FilledButton.icon(onPressed: () => setState(() => _shown = true), icon: const Icon(Icons.visibility), label: const Text('Cevabı göster')),
      if (_shown) ...[
        const SizedBox(height: 12),
        if (!_reverse)
          Center(child: Text(c.native, textDirection: _dir, textAlign: TextAlign.center, style: TextStyle(fontSize: widget.dil.rtl ? 30 : 24, fontWeight: FontWeight.w800, color: const Color(0xFF7A4E9A)))),
        if (_reverse) Center(child: Text('${c.emoji}  ${c.turkish}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF7A4E9A)))),
        Center(child: Text('🔊 ${c.reading}', style: const TextStyle(fontSize: 15))),
        const SizedBox(height: 6),
        Text('💡 ${c.hook}', style: const TextStyle(fontSize: 13.5, height: 1.35)),
        Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => _say(c), icon: const Icon(Icons.volume_up), label: const Text('Dinle'))),
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
