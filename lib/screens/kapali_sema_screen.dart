import 'package:flutter/material.dart';

import '../app_state.dart';
import '../content.dart';
import '../hafiza.dart';
import '../tts.dart';
import '../widgets/read_bar.dart';
import 'gorsel_soru_screen.dart';

/// Kapalı şema: şemadaki terimler kapatılır; kutuyu önce aklından söyle, sonra aç.
class KapaliSemaListScreen extends StatelessWidget {
  const KapaliSemaListScreen({super.key});

  @override
  Widget build(BuildContext context) => Readable(
        label: 'Kapalı şema',
        items: () => [ReadItem('Kapalı şema', 'Şemadaki terimler kapatılır. Önce aklından söyle, sonra kutuyu aç. Bilemediklerin tekrar kartlarına eklenir.')],
        child: Scaffold(
          appBar: AppBar(title: const Text('Kapalı şema')),
          body: FutureBuilder<Hafiza>(
            future: Hafiza.load(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final list = snap.data!.semalar;
              return AnimatedBuilder(
                animation: store,
                builder: (context, _) => ListView(padding: const EdgeInsets.all(14), children: [
                  const Text(
                    'Şemadaki terimler kapalı gelir. Kutuyu aklından söyle, sonra aç; "Bilemedim" dediğin madde tekrar kartlarına eklenir.',
                    style: TextStyle(fontSize: 13.5, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GorselSoruScreen())),
                    icon: const Icon(Icons.quiz),
                    label: const Text('Çoktan seçmeli sına (10 soru)'),
                  ),
                  const SizedBox(height: 8),
                  for (final s in list)
                    Builder(builder: (context) {
                      final known = [for (var i = 0; i < s.boxes.length; i++) store.visual['${s.id}|$i'] == true].where((x) => x).length;
                      final a = areaById(s.area);
                      return Card(
                        child: ListTile(
                          leading: Icon(a.icon, color: a.color),
                          title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${a.name} · ${s.boxes.length} kutu · $known bildim'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => KapaliSemaScreen(sema: s))),
                        ),
                      );
                    }),
                ]),
              );
            },
          ),
        ),
      );
}

class KapaliSemaScreen extends StatefulWidget {
  final SemaMask sema;
  const KapaliSemaScreen({super.key, required this.sema});

  @override
  State<KapaliSemaScreen> createState() => _KapaliSemaScreenState();
}

class _KapaliSemaScreenState extends State<KapaliSemaScreen> {
  final Set<int> _open = {};
  int _cur = 0;
  int _right = 0, _wrong = 0;

  SemaMask get s => widget.sema;
  bool get _done => _right + _wrong >= s.boxes.length;

  void _next() {
    for (var k = 1; k <= s.boxes.length; k++) {
      final i = (_cur + k) % s.boxes.length;
      if (!_open.contains(i)) {
        _cur = i;
        return;
      }
    }
  }

  void _mark(bool ok) {
    final b = s.boxes[_cur];
    store.markVisual('${s.id}|$_cur', ok, entryExists(b.entryId) ? b.entryId : '');
    setState(() {
      ok ? _right++ : _wrong++;
      _open.add(_cur);
      _next();
    });
  }

  Widget _image(double w) {
    final h = w / s.aspect;
    const pad = 0.004;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(children: [
        Positioned.fill(child: Image.asset('assets/sema/${s.id}.png', fit: BoxFit.fill)),
        for (var i = 0; i < s.boxes.length; i++)
          for (final r in s.boxes[i].rects)
            if (!_open.contains(i))
              Positioned(
                left: (r.left - pad) * w,
                top: (r.top - pad) * h,
                width: (r.width + 2 * pad) * w,
                height: (r.height + 2 * pad) * h,
                child: GestureDetector(
                  onTap: () => setState(() => _cur = i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF7A4E9A),
                      borderRadius: BorderRadius.circular(3),
                      border: i == _cur ? Border.all(color: const Color(0xFFFFC83D), width: 2.5) : null,
                    ),
                  ),
                ),
              ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = s.boxes[_cur];
    final shown = _open.contains(_cur);
    return Readable(
      label: s.title,
      items: () => [
        ReadItem(s.title, 'Kapalı şema. ${s.boxes.length} kutu var. Sarı çerçeveli kutuda ne yazdığını düşün, sonra aç.'),
        if (shown) ReadItem('Cevap', b.text),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text(s.title, style: const TextStyle(fontSize: 16))),
        body: ListView(padding: const EdgeInsets.all(12), children: [
          LayoutBuilder(builder: (context, c) => ClipRRect(borderRadius: BorderRadius.circular(8), child: _image(c.maxWidth))),
          const SizedBox(height: 12),
          if (_done) _summary() else _panel(b),
        ]),
      ),
    );
  }

  Widget _panel(MaskBox b) {
    final shown = _open.contains(_cur);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Kutu ${_cur + 1} / ${s.boxes.length} · bildim $_right · bilemedim $_wrong', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Sarı çerçeveli kutuda ne yazıyor? Aklından söyle.', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => setState(() => _open.add(_cur)),
            icon: const Icon(Icons.visibility),
            label: const Text('Kutuyu aç'),
          ),
          if (shown) ...[
            const SizedBox(height: 8),
            Text(b.text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton(onPressed: () => _mark(false), child: const Text('Bilemedim')),
            ),
            const SizedBox(width: 10),
            Expanded(child: FilledButton(onPressed: () => _mark(true), child: const Text('Bildim'))),
          ]),
        ]),
      ),
    );
  }

  Widget _summary() => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Bitti: $_right bildim, $_wrong bilemedim.', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            if (_wrong > 0) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Bilemediklerinin maddeleri Tekrar kartlarına eklendi.')),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () => setState(() {
                _open.clear();
                _cur = 0;
                _right = _wrong = 0;
              }),
              child: const Text('Baştan başla'),
            ),
          ]),
        ),
      );
}
