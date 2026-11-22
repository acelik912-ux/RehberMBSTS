import 'package:flutter/material.dart';

import '../app_state.dart';
import '../content.dart';
import '../tts.dart';
import '../widgets/entry_icon.dart';
import '../widgets/player_bar.dart';
import '../widgets/read_bar.dart';
import 'entry_editor.dart';
import 'note_editor.dart';

/// Defterim: bütün notların, eklediğin maddeler ve favoriler.
class NotebookScreen extends StatelessWidget {
  const NotebookScreen({super.key});

  @override
  Widget build(BuildContext context) => Readable(
        label: 'notlarım ve favorilerim',
        items: () => [for (final n in store.notes) if (n.text.trim().isNotEmpty) ReadItem(store.resolve(content, n.entryId)?.title ?? 'Serbest not', '${store.resolve(content, n.entryId)?.title ?? 'Serbest not'}. Notum: ${clean(n.text)}.', entryId: entryExists(n.entryId) ? n.entryId : null, area: store.resolve(content, n.entryId)?.area ?? 'hadis'), ...store.favorites.map(entryItem).whereType<ReadItem>()],
        child: _page(context),
      );

  Widget _page(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final notes = [...store.notes]..sort((a, b) => b.created.compareTo(a.created));
          final mine = store.custom.values.toList()..sort((a, b) => a.title.compareTo(b.title));
          final favs = store.favorites.where(entryExists).map((id) => store.resolve(content, id)!).toList();
          return Scaffold(
            appBar: AppBar(
              title: const Text('Defterim'),
              actions: [if (favs.isNotEmpty) ListenButton(ids: [for (final f in favs) f.id], tooltip: 'Favorileri sırayla dinle')],
              bottom: TabBar(tabs: [
                Tab(text: 'Notlar (${notes.length})'),
                Tab(text: 'Maddelerim (${mine.length})'),
                Tab(text: 'Favoriler (${favs.length})'),
              ]),
            ),
            floatingActionButton: FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Yeni'),
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (c) => SafeArea(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    ListTile(
                      leading: const Icon(Icons.note_add),
                      title: const Text('Serbest not (bir maddeye bağlı değil)'),
                      onTap: () {
                        Navigator.pop(c);
                        Navigator.push(context, MaterialPageRoute(settings: RouteSettings(name: 'not-yeni'), builder: (_) => const NoteEditor(entryId: '')));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.post_add),
                      title: const Text('Yeni madde (kendi konu sayfam)'),
                      onTap: () {
                        Navigator.pop(c);
                        Navigator.push(context, MaterialPageRoute(settings: RouteSettings(name: 'madde-yeni'), builder: (_) => const EntryEditor()));
                      },
                    ),
                  ]),
                ),
              ),
            ),
            body: TabBarView(children: [
              notes.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Henüz not yok. Bir madde sayfasında "Not / görsel ekle"ye dokun.')))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 90),
                      itemCount: notes.length,
                      itemBuilder: (c, i) {
                        final n = notes[i];
                        final e = n.entryId.isEmpty ? null : store.resolve(content, n.entryId);
                        return ListTile(
                          leading: n.images.isEmpty
                              ? const CircleAvatar(child: Icon(Icons.sticky_note_2))
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(store.imageFile(n.images.first), width: 52, height: 52, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                                ),
                          title: Text(e?.title ?? 'Serbest not', style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(n.text.isEmpty ? '${n.images.length} görsel' : n.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                          onTap: () => e != null
                              ? openEntry(context, e.id)
                              : Navigator.push(context, MaterialPageRoute(settings: RouteSettings(name: 'not-duzenle'), builder: (_) => NoteEditor(entryId: n.entryId, note: n))),
                        );
                      },
                    ),
              mine.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Kendi maddeni eklemek için alttaki "Yeni" düğmesine dokun.')))
                  : _list(context, mine),
              favs.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Madde sayfasındaki yıldıza dokunarak favori ekleyebilirsin.')))
                  : _list(context, favs),
            ]),
          );
        },
      ),
    );
  }

  Widget _list(BuildContext context, List<Entry> l) => ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          for (final e in l)
            ListTile(
              leading: EntryIcon(entry: e, size: 38),
              title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(e.summary, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => openEntry(context, e.id),
            ),
        ],
      );
}
