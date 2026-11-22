import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../content.dart';
import '../tts.dart';
import '../widgets/read_bar.dart';
import 'deneme_screen.dart';

class QuizMenuScreen extends StatelessWidget {
  const QuizMenuScreen({super.key});

  @override
  Widget build(BuildContext context) => Readable(
        label: 'yanlış yaptığım sorular (cevaplı)',
        items: () => [for (final q in content.questions.where(store.isWrongBefore)) questionItem(q, withAnswer: true)],
        child: _page(context),
      );

  Widget _page(BuildContext context) {
    return ListenableBuilder(listenable: store, builder: (context, _) => _build(context));
  }

  Widget _build(BuildContext context) {
    final wrong = content.questions.where(store.isWrongBefore).length;
    final last = store.denemeler.isEmpty ? null : store.denemeler.first;
    return Scaffold(
      appBar: AppBar(title: const Text('Test')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: const Color(0xFF2E5A93),
            child: ListTile(
              textColor: Colors.white,
              iconColor: Colors.white,
              leading: const Icon(Icons.timer),
              title: const Text('Deneme sınavı · 60 soru / 90 dk', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(last == null
                  ? 'Gerçek dağılım: Fıkıh 20, Kur\'an 7, Tefsir 7, Kelam 7, Hadis 7, Siyer 7, Mezhep 3, Dinler 2'
                  : 'Son deneme: ${last.right}/${last.total} doğru · ${store.denemeler.length} deneme'),
              onTap: () => Navigator.push(context, MaterialPageRoute(settings: RouteSettings(name: 'deneme'), builder: (_) => const DenemeScreen())),
            ),
          ),
          if (last != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(settings: RouteSettings(name: 'deneme-gecmis'), builder: (_) => const DenemeHistoryScreen())),
                icon: const Icon(Icons.bar_chart),
                label: const Text('Deneme geçmişi'),
              ),
            ),
          Card(
            color: const Color(0xFFA8402F),
            child: ListTile(
              textColor: Colors.white,
              iconColor: Colors.white,
              leading: const Icon(Icons.shuffle),
              title: const Text('Karışık test (15 soru)', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Bütün alanlardan rastgele'),
              onTap: () => Navigator.push(context, MaterialPageRoute(settings: RouteSettings(name: 'quiz'), builder: (_) => const QuizScreen())),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.replay),
              title: const Text('Yanlışlarım', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(wrong == 0 ? 'Henüz yanlış yok' : '$wrong soru tekrar bekliyor'),
              enabled: wrong > 0,
              onTap: () => Navigator.push(context, MaterialPageRoute(settings: RouteSettings(name: 'quiz-yanlis'), builder: (_) => const QuizScreen(onlyWrong: true))),
            ),
          ),
          const Padding(padding: EdgeInsets.fromLTRB(8, 14, 8, 6), child: Text('Alana göre', style: TextStyle(fontWeight: FontWeight.w800))),
          for (final a in areas)
            if (content.questions.any((q) => q.area == a.id))
              ListTile(
                leading: CircleAvatar(backgroundColor: a.color, child: Icon(a.icon, color: Colors.white, size: 18)),
                title: Text(a.name),
                subtitle: Text('${content.questions.where((q) => q.area == a.id).length} soru'),
                onTap: () => Navigator.push(context, MaterialPageRoute(settings: RouteSettings(name: 'quiz:${a.id}'), builder: (_) => QuizScreen(area: a.id))),
              ),
        ],
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  final String? area;
  final bool onlyWrong;
  const QuizScreen({super.key, this.area, this.onlyWrong = false});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final List<Question> _qs;
  int _i = 0;
  int? _chosen;
  int _right = 0;

  @override
  void initState() {
    super.initState();
    var pool = content.questions.where((q) => widget.area == null || q.area == widget.area).toList();
    if (widget.onlyWrong) pool = pool.where(store.isWrongBefore).toList();
    pool.shuffle(Random());
    _qs = pool.take(widget.area == null && !widget.onlyWrong ? 15 : 20).toList();
  }

  void _answer(int i) {
    if (_chosen != null) return;
    final q = _qs[_i];
    final ok = i == q.answer;
    store.markQuiz(q, ok);
    setState(() {
      _chosen = i;
      if (ok) _right++;
    });
  }

  @override
  Widget build(BuildContext context) => Readable(
        label: 'bu soru',
        items: () => _i < _qs.length ? [questionItem(_qs[_i], no: _i + 1, withAnswer: _chosen != null, chosen: _chosen)] : [ReadItem('Sonuç', '${_qs.length} sorudan $_right doğru.')],
        child: _page(context),
      );

  Widget _page(BuildContext context) {
    if (_qs.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('Test')), body: const Center(child: Text('Soru yok.')));
    }
    if (_i >= _qs.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sonuç')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$_right / ${_qs.length}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(_right == _qs.length ? 'Mükemmel!' : 'Yanlışların "Yanlışlarım" listesine eklendi.'),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Bitir')),
          ]),
        ),
      );
    }
    final q = _qs[_i];
    final a = areaById(q.area);
    const letters = ['A', 'B', 'C', 'D', 'E'];
    return Scaffold(
      appBar: AppBar(
        title: Text('Soru ${_i + 1} / ${_qs.length}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_i + 1) / _qs.length, color: a.color),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(a.name, style: TextStyle(color: a.color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(q.text, style: const TextStyle(fontSize: 18, height: 1.45, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          for (var k = 0; k < q.options.length; k++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: _chosen == null
                    ? Theme.of(context).colorScheme.surfaceContainerHigh
                    : k == q.answer
                        ? const Color(0xFF3F7A3A).withValues(alpha: 0.25)
                        : k == _chosen
                            ? const Color(0xFFA8402F).withValues(alpha: 0.25)
                            : Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _answer(k),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      CircleAvatar(radius: 13, backgroundColor: a.color, child: Text(letters[k], style: const TextStyle(color: Colors.white, fontSize: 12))),
                      const SizedBox(width: 12),
                      Expanded(child: Text(q.options[k], style: const TextStyle(fontSize: 16))),
                      if (_chosen != null && k == q.answer) const Icon(Icons.check_circle, color: Color(0xFF3F7A3A)),
                      if (_chosen != null && k == _chosen && k != q.answer) const Icon(Icons.cancel, color: Color(0xFFA8402F)),
                    ]),
                  ),
                ),
              ),
            ),
          if (_chosen != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: a.color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_chosen == q.answer ? 'Doğru!' : 'Doğru cevap: ${letters[q.answer]}', style: const TextStyle(fontWeight: FontWeight.w800)),
                if (q.explanation.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(q.explanation)),
                if (q.entryId.isNotEmpty && entryExists(q.entryId))
                  TextButton.icon(
                    onPressed: () => openEntry(context, q.entryId),
                    icon: const Icon(Icons.menu_book),
                    label: Text('Konuyu aç: ${store.resolve(content, q.entryId)!.title}'),
                  ),
              ]),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => setState(() {
                _i++;
                _chosen = null;
              }),
              child: Text(_i + 1 < _qs.length ? 'Sonraki soru' : 'Sonucu gör'),
            ),
          ],
        ],
      ),
    );
  }
}
