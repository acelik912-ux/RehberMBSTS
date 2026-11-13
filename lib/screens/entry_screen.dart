import 'package:flutter/material.dart';

import '../app_state.dart';
import '../content.dart';
import '../store.dart';
import '../widgets/entry_icon.dart';
import '../widgets/player_bar.dart';
import '../widgets/rich_body.dart';
import 'entry_editor.dart';
import 'note_editor.dart';

class EntryScreen extends StatefulWidget {
  final String id;
  const EntryScreen({super.key, required this.id});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  @override
  void initState() {
    super.initState();
    store.visit(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final e = store.resolve(content, widget.id);
        if (e == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Madde silinmiş.')));
        }
        final area = areaById(e.area);
        final notes = store.notesFor(e.id);
        final back = backlinks(e.id);
        final edited = store.overrides.containsKey(e.id);
        return Scaffold(
          appBar: AppBar(
            backgroundColor: area.color,
            foregroundColor: Colors.white,
            title: Text(e.title),
            actions: [
              ListenButton(ids: [e.id]),
              IconButton(
                tooltip: 'Favori',
                icon: Icon(store.favorites.contains(e.id) ? Icons.star : Icons.star_border),
                onPressed: () => store.toggleFav(e.id),
              ),
              IconButton(
                tooltip: store.inCards(e.id) ? 'Tekrar kartlarından çıkar' : 'Tekrar kartlarına ekle',
                icon: Icon(store.inCards(e.id) ? Icons.style : Icons.style_outlined),
                onPressed: () {
                  final had = store.inCards(e.id);
                  had ? store.removeCard(e.id) : store.addCard(e.id);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(had ? 'Tekrar kartlarından çıkarıldı.' : 'Tekrar kartlarına eklendi.'),
                    duration: const Duration(seconds: 1),
                  ));
                },
              ),
              PopupMenuButton<String>(
                onSelected: (v) => _menu(v, e),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Metni düzenle')),
                  if (edited) const PopupMenuItem(value: 'reset', child: Text('Orijinal metne dön')),
                  if (e.custom) const PopupMenuItem(value: 'delete', child: Text('Bu maddeyi sil')),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: area.color,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Not / görsel ekle'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditor(entryId: e.id))),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
            children: [
              Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Chip(
                  label: Text(area.name),
                  backgroundColor: area.color.withValues(alpha: 0.12),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
                Text(e.group, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                if (e.years.isNotEmpty) ...[
                  const Text('Sınavda çıktı:', style: TextStyle(fontSize: 12)),
                  yearBadges(e.years),
                ],
                if (edited) const Chip(label: Text('düzenlendi'), visualDensity: VisualDensity.compact),
                if (e.custom) const Chip(label: Text('benim maddem'), visualDensity: VisualDensity.compact),
              ]),
              if (e.aliases.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Diğer adları: ${e.aliases.join(', ')}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(children: [
                  EntryIcon(entry: e, size: 64),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(e.hint.isEmpty ? e.title : e.hint,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: area.color, height: 1.3)),
                  ),
                ]),
              ),
              if (e.summary.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: area.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RichBody(
                    text: e.summary,
                    exists: entryExists,
                    onLink: (id) => openEntry(context, id),
                    fontSize: 16.5,
                  ),
                ),
              // Kullanıcının çağrışım görseli en üstte
              if (notes.any((n) => n.images.isNotEmpty)) _CueStrip(notes: notes),
              const SizedBox(height: 4),
              RichBody(text: e.body, exists: entryExists, onLink: (id) => openEntry(context, id)),
              for (final img in e.images) _AssetImage(path: img),
              const SizedBox(height: 18),
              _SectionTitle(icon: Icons.sticky_note_2, text: 'Notlarım (${notes.length})', color: area.color),
              if (notes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text('Bu sayfaya kendi açıklamanı, hocanın örneğini veya sana çağrışım yapan bir resmi ekleyebilirsin. '
                      'Eklediğin ilk resim, tekrar kartında terimin ipucu olarak görünür.'),
                ),
              for (final n in notes) _NoteCard(note: n, entryId: e.id),
              if (back.isNotEmpty) ...[
                const SizedBox(height: 14),
                _SectionTitle(icon: Icons.link, text: 'Bu terim nerelerde geçiyor? (${back.length})', color: area.color),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final b in back)
                    ActionChip(
                      avatar: CircleAvatar(backgroundColor: areaById(b.area).color, radius: 6),
                      label: Text(b.title),
                      onPressed: () => openEntry(context, b.id),
                    ),
                ]),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _menu(String v, Entry e) async {
    if (v == 'edit') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => EntryEditor(existing: e)));
    } else if (v == 'reset') {
      await store.setOverride(e.id, null);
    } else if (v == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Silinsin mi?'),
          content: Text('"${e.title}" maddesi silinecek. Bağlı notların kalır.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sil')),
          ],
        ),
      );
      if (ok == true) {
        await store.deleteCustom(e.id);
        if (mounted) Navigator.pop(context);
      }
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _SectionTitle({required this.icon, required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
        ]),
      );
}

class _CueStrip extends StatelessWidget {
  final List<Note> notes;
  const _CueStrip({required this.notes});
  @override
  Widget build(BuildContext context) {
    final imgs = [for (final n in notes) ...n.images];
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imgs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (c, i) => GestureDetector(
          onTap: () => showImage(context, Image.file(store.imageFile(imgs[i]))),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(store.imageFile(imgs[i]), height: 120, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(width: 80, child: Icon(Icons.broken_image))),
          ),
        ),
      ),
    );
  }
}

class _AssetImage extends StatelessWidget {
  final String path;
  const _AssetImage({required this.path});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: GestureDetector(
          onTap: () => showImage(context, Image.asset(path)),
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(10)),
            clipBehavior: Clip.antiAlias,
            child: Stack(children: [
              Image.asset(path, fit: BoxFit.fitWidth, width: double.infinity),
              const Positioned(right: 6, bottom: 6, child: Icon(Icons.zoom_in, color: Colors.black54)),
            ]),
          ),
        ),
      );
}

void showImage(BuildContext context, Image img) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: InteractiveViewer(maxScale: 6, child: Center(child: img)),
      ),
    ),
  );
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final String entryId;
  const _NoteCard({required this.note, required this.entryId});
  @override
  Widget build(BuildContext context) {
    final d = DateTime.fromMillisecondsSinceEpoch(note.created);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditor(entryId: entryId, note: note))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (note.text.isNotEmpty)
              RichBody(text: note.text, exists: entryExists, onLink: (id) => openEntry(context, id), fontSize: 15),
            if (note.images.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final i in note.images)
                  GestureDetector(
                    onTap: () => showImage(context, Image.file(store.imageFile(i))),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(store.imageFile(i), width: 96, height: 96, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(width: 96, height: 96, child: Icon(Icons.broken_image))),
                    ),
                  ),
              ]),
            ],
            const SizedBox(height: 4),
            Text('${d.day}.${d.month}.${d.year} · düzenlemek için dokun', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ),
      ),
    );
  }
}
