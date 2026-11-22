import 'package:flutter/material.dart';

import '../app_state.dart';
import '../content.dart';
import '../hafiza.dart';
import '../tts.dart';
import '../widgets/read_bar.dart';
import 'entry_screen.dart' show showImage;

/// Cami hafıza sarayı: 10 sabit durak; ezberlenecek listeler bu duraklara yerleştirilir.
class SarayScreen extends StatelessWidget {
  const SarayScreen({super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder<Hafiza>(
        future: Hafiza.load(),
        builder: (context, snap) {
          final h = snap.data;
          return Readable(
            label: 'Cami hafıza sarayı',
            items: () => [
              ReadItem(
                'Cami hafıza sarayı',
                h == null
                    ? ''
                    : 'Rota hep aynı: ${h.duraklar.map((d) => d.title).join(', ')}. Ezberleyeceğin listenin her öğesini sırayla bir durağa koy ve orada abartılı bir sahne kur.',
              ),
            ],
            child: Scaffold(
              appBar: AppBar(title: const Text('Cami hafıza sarayı')),
              body: h == null
                  ? const Center(child: CircularProgressIndicator())
                  : AnimatedBuilder(
                      animation: store,
                      builder: (context, _) => ListView(padding: const EdgeInsets.all(14), children: [
                        const Text(
                          'Her listeyi aynı camiye yerleştiriyoruz: minareden kubbeye hep aynı 10 durak. Önce bir turu gez, sonra gözünü kapatıp sına.',
                          style: TextStyle(fontSize: 13.5, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => showImage(context, Image.asset('assets/sema/saray_rota.png')),
                          child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset('assets/sema/saray_rota.png')),
                        ),
                        const SizedBox(height: 6),
                        Wrap(spacing: 6, runSpacing: 4, children: [
                          for (final d in h.duraklar) Chip(label: Text('${d.no} ${d.icon} ${d.title}', style: const TextStyle(fontSize: 12)), visualDensity: VisualDensity.compact),
                        ]),
                        const SizedBox(height: 12),
                        Text('Turlar', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        for (final t in h.turlar)
                          Card(
                            child: ListTile(
                              leading: Text(t.icon, style: const TextStyle(fontSize: 26)),
                              title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text(
                                '${areaById(t.area).name} · ${t.items.length} durak · '
                                '${[for (final o in t.items) store.visual['saray:${t.id}|${o.stop}'] == true].where((x) => x).length} bildim',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.push(context, MaterialPageRoute(settings: RouteSettings(name: 'saray:${t.id}'), builder: (_) => SarayTurScreen(tur: t, duraklar: h.duraklar))),
                            ),
                          ),
                      ]),
                    ),
            ),
          );
        },
      );
}

class SarayTurScreen extends StatefulWidget {
  final SarayTur tur;
  final List<Durak> duraklar;
  const SarayTurScreen({super.key, required this.tur, required this.duraklar});

  @override
  State<SarayTurScreen> createState() => _SarayTurScreenState();
}

class _SarayTurScreenState extends State<SarayTurScreen> {
  bool _quiz = false;
  int _i = 0;
  bool _shown = false;
  int _right = 0, _wrong = 0;

  SarayTur get t => widget.tur;
  Durak _durak(int n) => widget.duraklar.firstWhere((d) => d.no == n);

  void _mark(bool ok) {
    final o = t.items[_i];
    store.markVisual('saray:${t.id}|${o.stop}', ok, entryExists(o.entryId) ? o.entryId : '');
    setState(() {
      ok ? _right++ : _wrong++;
      _i++;
      _shown = false;
    });
  }

  @override
  Widget build(BuildContext context) => Readable(
        label: t.title,
        items: () => [
          ReadItem(t.title, '${t.role}.'),
          for (final o in t.items) ReadItem('${_durak(o.stop).title}: ${o.info}', '${_durak(o.stop).title}. ${o.info}. ${o.scene}'),
        ],
        child: Scaffold(
          appBar: AppBar(title: Text(t.title, style: const TextStyle(fontSize: 16))),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Gez'), icon: Icon(Icons.directions_walk)),
                  ButtonSegment(value: true, label: Text('Sına'), icon: Icon(Icons.psychology)),
                ],
                selected: {_quiz},
                onSelectionChanged: (v) => setState(() {
                  _quiz = v.first;
                  _i = 0;
                  _shown = false;
                  _right = _wrong = 0;
                }),
              ),
            ),
            Expanded(child: _quiz ? _sina() : _gez()),
          ]),
        ),
      );

  Widget _gez() => ListView(padding: const EdgeInsets.all(14), children: [
        Text('${t.icon} ${t.role}', style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
        const SizedBox(height: 8),
        for (final o in t.items)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(radius: 13, backgroundColor: const Color(0xFF7A4E9A), child: Text('${o.stop}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 8),
                  Text(_durak(o.stop).icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_durak(o.stop).title, style: const TextStyle(fontWeight: FontWeight.w800))),
                ]),
                const SizedBox(height: 6),
                Text(o.info, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF7A4E9A))),
                const SizedBox(height: 4),
                Text(o.scene, style: const TextStyle(fontSize: 14.5, height: 1.45)),
                if (entryExists(o.entryId))
                  Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => openEntry(context, o.entryId), child: const Text('Maddeye git'))),
              ]),
            ),
          ),
      ]);

  Widget _sina() {
    if (_i >= t.items.length) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Tur bitti: $_right bildim, $_wrong bilemedim.', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            if (_wrong > 0) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Bilemediklerin Tekrar kartlarına eklendi.')),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => setState(() { _i = 0; _right = _wrong = 0; }), child: const Text('Baştan')),
          ]),
        ),
      );
    }
    final o = t.items[_i];
    final d = _durak(o.stop);
    return ListView(padding: const EdgeInsets.all(14), children: [
      Text('${_i + 1} / ${t.items.length}', style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 8),
      Center(child: Text(d.icon, style: const TextStyle(fontSize: 64))),
      Center(child: Text('${o.stop}. durak: ${d.title}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
      const SizedBox(height: 6),
      Center(child: Text(d.desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.grey))),
      const SizedBox(height: 14),
      const Center(child: Text('Gözünü kapat: bu durakta ne vardı?', style: TextStyle(fontWeight: FontWeight.w700))),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: () => setState(() => _shown = true), icon: const Icon(Icons.visibility), label: const Text('Cevabı göster')),
      if (_shown) ...[
        const SizedBox(height: 12),
        Text(o.info, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF7A4E9A))),
        const SizedBox(height: 6),
        Text(o.scene, style: const TextStyle(fontSize: 14.5, height: 1.45)),
      ],
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => _mark(false), child: const Text('Bilemedim'))),
        const SizedBox(width: 10),
        Expanded(child: FilledButton(onPressed: () => _mark(true), child: const Text('Bildim'))),
      ]),
    ]);
  }
}
