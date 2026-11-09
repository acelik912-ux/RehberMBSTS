import 'package:flutter/material.dart';

import '../app_state.dart';
import '../content.dart';
import '../store.dart';
import '../widgets/rich_body.dart';

/// Leitner usulü tekrar: kart önce terimi (ve varsa senin çağrışım resmini) gösterir,
/// sen hatırlamaya çalışırsın, sonra çevirip kontrol edersin.
class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  late List<String> _queue = store.dueCards().where(entryExists).toList();
  bool _shown = false;
  int _done = 0;
  bool _reverse = false; // önce özeti göster, terimi bul

  void _grade(bool known) {
    final id = _queue.removeAt(0);
    store.grade(id, known);
    if (!known) _queue.add(id); // bilinemeyen kart bu oturumda tekrar gelir
    setState(() {
      _shown = false;
      _done++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final boxes = List.filled(6, 0);
    for (final c in store.cards.values) {
      boxes[c.box]++;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tekrar kartları'),
        actions: [
          IconButton(
            tooltip: 'Yön değiştir',
            icon: Icon(_reverse ? Icons.swap_horiz : Icons.swap_horiz_outlined),
            onPressed: () => setState(() {
              _reverse = !_reverse;
              _shown = false;
            }),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(children: [
            for (var b = 1; b <= 5; b++)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: [Colors.transparent, const Color(0xFFA8402F), const Color(0xFFB9862F), const Color(0xFF2E5A93), const Color(0xFF6A4C93), const Color(0xFF3F7A3A)][b],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(children: [
                    Text('${boxes[b]}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    Text('$b. kutu', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  ]),
                ),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            _reverse ? 'Ters yön: özeti okuyup terimi bul.' : 'Terimi gör, anlamını içinden söyle, sonra kartı çevir.',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        Expanded(child: _queue.isEmpty ? _empty() : _card(_queue.first)),
      ]),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.celebration, size: 56, color: Color(0xFFB9862F)),
            const SizedBox(height: 10),
            Text(_done > 0 ? 'Bugünlük bitti! $_done kart çalıştın.' : 'Bugün bekleyen kart yok.',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              store.cards.isEmpty
                  ? 'Kart eklemek için bir madde sayfasında üstteki kart simgesine dokun ya da alan sayfasındaki menüden "Hepsini tekrar kartlarına ekle"yi seç.'
                  : 'Bildiğin kartlar ${boxDays.sublist(1).join(", ")} gün aralıklarla geri gelir.',
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );

  Widget _card(String id) {
    final e = store.resolve(content, id)!;
    final a = areaById(e.area);
    final cue = store.cueImage(id);
    final box = store.cards[id]?.box ?? 1;
    final front = _reverse
        ? Text(e.summary.isEmpty ? e.title : e.summary.replaceAllMapped(linkRe, (m) => m.group(2) ?? m.group(1)!),
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, height: 1.4))
        : Column(mainAxisSize: MainAxisSize.min, children: [
            if (cue != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(store.imageFile(cue), height: 170, fit: BoxFit.cover),
                ),
              ),
            Text(e.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, fontFamily: 'serif')),
            if (e.aliases.isNotEmpty) Text(e.aliases.join(' · '), style: const TextStyle(color: Colors.grey)),
          ]);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: a.color, width: 2)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Row(children: [
                Expanded(child: Text(a.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: a.color, fontWeight: FontWeight.w700, fontSize: 12))),
                const SizedBox(width: 8),
                Text('$box. kutu · ${_queue.length}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
              const SizedBox(height: 20),
              front,
              const SizedBox(height: 20),
              if (!_shown)
                FilledButton.tonalIcon(
                  onPressed: () => setState(() => _shown = true),
                  icon: const Icon(Icons.flip),
                  label: const Text('Kartı çevir'),
                )
              else ...[
                const Divider(),
                if (_reverse)
                  Text(e.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, fontFamily: 'serif'))
                else
                  RichBody(text: e.summary.isEmpty ? '(Özet yok — sayfayı aç.)' : e.summary, exists: entryExists, onLink: (x) => openEntry(context, x), fontSize: 17),
                TextButton.icon(onPressed: () => openEntry(context, id), icon: const Icon(Icons.open_in_new), label: const Text('Sayfayı aç')),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 14),
        if (_shown)
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFA8402F), padding: const EdgeInsets.all(16)),
                onPressed: () => _grade(false),
                icon: const Icon(Icons.close),
                label: const FittedBox(child: Text('Bilemedim')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF3F7A3A), padding: const EdgeInsets.all(16)),
                onPressed: () => _grade(true),
                icon: const Icon(Icons.check),
                label: const FittedBox(child: Text('Bildim')),
              ),
            ),
          ]),
      ],
    );
  }
}
