import 'package:flutter/material.dart';

import '../app_state.dart';
import '../content.dart';
import '../widgets/player_bar.dart';
import 'entry_editor.dart';
import 'quiz_screen.dart';

class AreaScreen extends StatelessWidget {
  final Area area;
  const AreaScreen({super.key, required this.area});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final entries = store.allEntries(content).where((e) => e.area == area.id).toList();
        final groups = <String, List<Entry>>{};
        for (final e in entries) {
          groups.putIfAbsent(e.group, () => []).add(e);
        }
        final hasQuiz = content.questions.any((q) => q.area == area.id);
        return Scaffold(
          appBar: AppBar(
            backgroundColor: area.color,
            foregroundColor: Colors.white,
            title: Text(area.name),
            actions: [
              if (entries.isNotEmpty) ListenButton(ids: [for (final e in entries) e.id], tooltip: 'Bu alanı baştan sona dinle'),
              if (hasQuiz)
                IconButton(
                  tooltip: 'Bu alandan test',
                  icon: const Icon(Icons.quiz),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(area: area.id))),
                ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'cards') {
                    store.addCards(entries.map((e) => e.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${entries.length} madde tekrar kartlarına eklendi.')),
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'cards', child: Text('Hepsini tekrar kartlarına ekle')),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: area.color,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Madde ekle'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EntryEditor(areaId: area.id))),
          ),
          body: entries.isEmpty
              ? const Center(child: Text('Bu alanda henüz madde yok. Sağ alttan ekleyebilirsin.'))
              : ListView(
                  padding: const EdgeInsets.only(bottom: 90),
                  children: [
                    for (final g in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(g.key.toUpperCase(),
                            style: TextStyle(fontSize: 12, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: area.color)),
                      ),
                      for (final e in g.value) _EntryTile(e: e, color: area.color),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _EntryTile extends StatelessWidget {
  final Entry e;
  final Color color;
  const _EntryTile({required this.e, required this.color});

  @override
  Widget build(BuildContext context) {
    final read = store.read.contains(e.id);
    final notes = store.notesFor(e.id).length;
    return ListTile(
      onTap: () => openEntry(context, e.id),
      leading: Icon(read ? Icons.check_circle : Icons.circle_outlined, color: read ? color : Colors.grey),
      title: Row(children: [
        Flexible(child: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700))),
        if (e.custom) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.person, size: 16)),
        if (store.favorites.contains(e.id)) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.star, size: 16, color: Colors.amber)),
        if (notes > 0)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.sticky_note_2, size: 15), Text('$notes', style: const TextStyle(fontSize: 12))]),
          ),
      ]),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (e.summary.isNotEmpty) Text(e.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
        if (e.years.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: yearBadges(e.years, size: 10)),
      ]),
    );
  }
}
