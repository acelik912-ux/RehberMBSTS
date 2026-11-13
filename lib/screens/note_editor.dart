import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_state.dart';
import '../store.dart';
import '../tts.dart';
import '../widgets/dictation.dart';
import '../widgets/read_bar.dart';
import 'search_screen.dart';

/// Bir maddeye (ya da serbest olarak) yazı + görsel notu ekler/düzenler.
class NoteEditor extends StatefulWidget {
  final String entryId;
  final Note? note;
  const NoteEditor({super.key, required this.entryId, this.note});

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late final TextEditingController _text = TextEditingController(text: widget.note?.text ?? '');
  late final List<String> _images = [...?widget.note?.images];
  final List<String> _added = [];
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource src) async {
    try {
      final picker = ImagePicker();
      final files = <XFile>[];
      if (src == ImageSource.gallery) {
        files.addAll(await picker.pickMultiImage(imageQuality: 85, maxWidth: 2000));
      } else {
        final f = await picker.pickImage(source: src, imageQuality: 85, maxWidth: 2000);
        if (f != null) files.add(f);
      }
      setState(() => _busy = true);
      for (final f in files) {
        final name = await store.importImage(f.path);
        _images.add(name);
        _added.add(name);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Görsel alınamadı: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _insertLink() async {
    final id = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const SearchScreen(pick: true)));
    if (id == null) return;
    final e = store.resolve(content, id);
    final tag = '[[$id|${e?.title ?? id}]]';
    final sel = _text.selection;
    final t = _text.text;
    final pos = sel.isValid ? sel.start : t.length;
    final end = sel.isValid ? sel.end : t.length;
    _text.value = TextEditingValue(
      text: t.replaceRange(pos, end, tag),
      selection: TextSelection.collapsed(offset: pos + tag.length),
    );
  }

  Future<void> _save() async {
    if (_text.text.trim().isEmpty && _images.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final n = widget.note ??
        Note(id: 'n${DateTime.now().microsecondsSinceEpoch}', entryId: widget.entryId, text: '', images: [], created: DateTime.now().millisecondsSinceEpoch);
    n.text = _text.text.trim();
    n.images = _images;
    await store.upsertNote(n);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final n = widget.note;
    if (n == null) return;
    await store.deleteNote(n);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Readable(
        label: 'yazdığım not',
        items: () => _text.text.trim().isEmpty ? <ReadItem>[] : [ReadItem('Notum', clean(_text.text))],
        child: _page(context),
      );

  Widget _page(BuildContext context) {
    final e = store.resolve(content, widget.entryId);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        // Kaydedilmeden çıkılırsa yeni eklenen görsel dosyalarını temizle.
        if (didPop && widget.note == null) {
          for (final i in _added) {
            if (!store.notes.any((n) => n.images.contains(i))) {
              final f = store.imageFile(i);
              if (f.existsSync()) f.deleteSync();
            }
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(e == null ? 'Serbest not' : 'Not: ${e.title}'),
          actions: [
            if (widget.note != null) IconButton(tooltip: 'Notu sil', icon: const Icon(Icons.delete_outline), onPressed: _delete),
            IconButton(tooltip: 'Kaydet', icon: const Icon(Icons.check), onPressed: _save),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DictationPanel(controller: _text),
            const SizedBox(height: 10),
            TextField(
              controller: _text,
              maxLines: null,
              minLines: 6,
              autofocus: widget.note == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Kendi cümlenle açıklama, hocanın örneği, aklında tutmak için bir kod…\n\n'
                    'İpucu: **kalın** yazmak için iki yıldız kullan; başka maddeye bağlantı için aşağıdaki düğmeye bas.',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(onPressed: _insertLink, icon: const Icon(Icons.link), label: const Text('Maddeye bağlantı')),
              OutlinedButton.icon(onPressed: () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('Galeriden')),
              OutlinedButton.icon(onPressed: () => _pick(ImageSource.camera), icon: const Icon(Icons.photo_camera), label: const Text('Kamera')),
            ]),
            if (_busy) const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final i in _images)
                Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(store.imageFile(i), width: 110, height: 110, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton.filledTonal(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _images.remove(i)),
                    ),
                  ),
                ]),
            ]),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: _save, icon: const Icon(Icons.check), label: const Text('Kaydet')),
          ],
        ),
      ),
    );
  }
}
