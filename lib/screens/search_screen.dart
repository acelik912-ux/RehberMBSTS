import 'package:flutter/material.dart';

import '../app_state.dart';
import '../content.dart';
import '../widgets/entry_icon.dart';

/// Tüm maddelerde ve notlarda arama. pick=true ise seçilen maddenin id'sini geri döndürür.
class SearchScreen extends StatefulWidget {
  final bool pick;
  const SearchScreen({super.key, this.pick = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _q = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<(Entry, int)> _results() {
    final q = norm(_query.trim());
    if (q.isEmpty) return [];
    final out = <(Entry, int)>[];
    for (final e in store.allEntries(content)) {
      var score = 0;
      final t = norm(e.title);
      if (t == q) {
        score = 100;
      } else if (t.startsWith(q)) {
        score = 80;
      } else if (t.contains(q)) {
        score = 60;
      } else if (e.aliases.any((a) => norm(a).contains(q))) {
        score = 55;
      } else if (norm(e.summary).contains(q)) {
        score = 30;
      } else if (norm(e.body).contains(q)) {
        score = 15;
      } else if (store.notesFor(e.id).any((n) => norm(n.text).contains(q))) {
        score = 10;
      }
      if (score > 0) out.add((e, score));
    }
    out.sort((a, b) => b.$2 != a.$2 ? b.$2.compareTo(a.$2) : a.$1.title.compareTo(b.$1.title));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final res = _results();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _q,
          autofocus: true,
          decoration: InputDecoration(
            hintText: widget.pick ? 'Bağlanacak maddeyi ara' : 'Terim, kişi, eser ara…',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() {
                _q.clear();
                _query = '';
              }),
            ),
        ],
      ),
      body: _query.trim().isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Başlıklar, diğer adlar, metinler ve kendi notların içinde arar. Şapkalı harf ve kesme işareti önemli değil: '
                  '"mutezile" yazınca "Mu\'tezile" de bulunur.'),
            )
          : res.isEmpty
              ? const Center(child: Text('Sonuç yok.'))
              : ListView.builder(
                  itemCount: res.length,
                  itemBuilder: (c, i) {
                    final e = res[i].$1;
                    final a = areaById(e.area);
                    return ListTile(
                      leading: EntryIcon(entry: e, size: 38),
                      title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${a.name} · ${e.hint.isNotEmpty ? e.hint : e.summary}', maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () => widget.pick ? Navigator.pop(context, e.id) : openEntry(context, e.id),
                    );
                  },
                ),
    );
  }
}
