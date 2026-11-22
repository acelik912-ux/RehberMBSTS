import 'package:flutter/material.dart';

import '../app_state.dart';
import '../content.dart';
import '../tts.dart';
import '../widgets/dictation.dart';
import '../widgets/read_bar.dart';
import 'search_screen.dart';

/// Yeni madde oluşturur ya da var olan maddenin metnini düzenler.
/// Hazır maddelerde değişiklik ayrı saklanır; "Orijinal metne dön" ile geri alınabilir.
class EntryEditor extends StatefulWidget {
  final Entry? existing;
  final String? areaId;
  const EntryEditor({super.key, this.existing, this.areaId});

  @override
  State<EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends State<EntryEditor> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _group = TextEditingController(text: widget.existing?.group ?? 'Benim maddelerim');
  late final _summary = TextEditingController(text: widget.existing?.summary ?? '');
  late final _body = TextEditingController(text: widget.existing?.body ?? '');
  late final _icon = TextEditingController(text: widget.existing?.icon ?? '');
  late final _hint = TextEditingController(text: widget.existing?.hint ?? '');
  late String _area = widget.existing?.area ?? widget.areaId ?? 'hadis';

  bool get _isBuiltIn => widget.existing != null && !widget.existing!.custom;

  @override
  void dispose() {
    _title.dispose();
    _group.dispose();
    _summary.dispose();
    _body.dispose();
    _icon.dispose();
    _hint.dispose();
    super.dispose();
  }

  void _wrap(String prefix) {
    final sel = _body.selection;
    final t = _body.text;
    final pos = sel.isValid ? sel.start : t.length;
    final lineStart = pos == 0 ? 0 : t.lastIndexOf('\n', pos - 1) + 1;
    _body.value = TextEditingValue(
      text: t.replaceRange(lineStart, lineStart, prefix),
      selection: TextSelection.collapsed(offset: pos + prefix.length),
    );
  }

  Future<void> _link() async {
    final id = await Navigator.push<String>(context, MaterialPageRoute(settings: RouteSettings(name: 'ara-sec'), builder: (_) => const SearchScreen(pick: true)));
    if (id == null) return;
    final e = store.resolve(content, id);
    final tag = '[[$id|${e?.title ?? id}]]';
    final sel = _body.selection;
    final t = _body.text;
    final s = sel.isValid ? sel.start : t.length;
    final en = sel.isValid ? sel.end : t.length;
    _body.value = TextEditingValue(text: t.replaceRange(s, en, tag), selection: TextSelection.collapsed(offset: s + tag.length));
  }

  Future<void> _save() async {
    if (_isBuiltIn) {
      final orig = content.entries[widget.existing!.id]!.body;
      await store.setOverride(widget.existing!.id, _body.text == orig ? null : _body.text);
    } else {
      final t = _title.text.trim();
      if (t.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Başlık yaz.')));
        return;
      }
      final id = widget.existing?.id ?? newId(t);
      await store.saveCustom(Entry(
        id: id,
        title: t,
        area: _area,
        group: _group.text.trim().isEmpty ? 'Benim maddelerim' : _group.text.trim(),
        summary: _summary.text.trim(),
        body: _body.text,
        custom: true,
        icon: _icon.text.trim(),
        hint: _hint.text.trim(),
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Readable(
        label: 'yazdığım metin',
        items: () => _body.text.trim().isEmpty ? <ReadItem>[] : [ReadItem(_title.text.isEmpty ? 'Metin' : _title.text, '${_title.text}. ${clean(_summary.text)}. ${clean(_body.text)}')],
        child: _page(context),
      );

  Widget _page(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isBuiltIn ? 'Metni düzenle' : (widget.existing == null ? 'Yeni madde' : 'Maddemi düzenle')),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isBuiltIn)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text('Hazır metni değiştiriyorsun. İstediğin zaman sayfadaki menüden "Orijinal metne dön" diyebilirsin.'),
            )
          else ...[
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Başlık (terim)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _area,
              decoration: const InputDecoration(labelText: 'Alan', border: OutlineInputBorder()),
              items: [for (final a in areas) DropdownMenuItem(value: a.id, child: Text(a.name))],
              onChanged: (v) => setState(() => _area = v ?? _area),
            ),
            const SizedBox(height: 10),
            TextField(controller: _group, decoration: const InputDecoration(labelText: 'Grup (ör. Kelam ekolleri)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Row(children: [
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _icon,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24),
                  decoration: const InputDecoration(labelText: 'Simge', hintText: '🙂', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _hint,
                  decoration: const InputDecoration(labelText: 'Görsel ipucu (kısa)', border: OutlineInputBorder()),
                ),
              ),
            ]),
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 10),
              child: Text('Simge için klavyenin emoji tuşunu kullan.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            TextField(
              controller: _summary,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Tek cümlelik özet (tekrar kartının arka yüzü)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
          ],
          Wrap(spacing: 6, runSpacing: 6, children: [
            ActionChip(avatar: const Icon(Icons.link, size: 18), label: const Text('Bağlantı'), onPressed: _link),
            ActionChip(label: const Text('## Başlık'), onPressed: () => _wrap('## ')),
            ActionChip(label: const Text('- Madde'), onPressed: () => _wrap('- ')),
            ActionChip(label: const Text('İpucu kutusu'), onPressed: () => _wrap('> ')),
            ActionChip(label: const Text('Tuzak kutusu'), onPressed: () => _wrap('!! ')),
            ActionChip(label: const Text('Akılda tut'), onPressed: () => _wrap('%% ')),
          ]),
          const SizedBox(height: 8),
          DictationPanel(controller: _body),
          const SizedBox(height: 8),
          TextField(
            controller: _body,
            maxLines: null,
            minLines: 14,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 15, height: 1.4),
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Açıklama metni…'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.check), label: const Text('Kaydet')),
        ],
      ),
    );
  }
}
