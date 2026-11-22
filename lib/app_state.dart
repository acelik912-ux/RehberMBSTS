import 'package:flutter/material.dart';

import 'content.dart';
import 'store.dart';
import 'screens/entry_screen.dart';

late Content content;
final store = Store();

bool entryExists(String id) => store.custom.containsKey(id) || content.entries.containsKey(id);

void openEntry(BuildContext context, String id) {
  if (!entryExists(id)) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu madde bulunamadı.')));
    return;
  }
  Navigator.of(context).push(MaterialPageRoute(settings: RouteSettings(name: 'e:$id'), builder: (_) => EntryScreen(id: id)));
}

/// Bir maddeye bağlantı veren diğer maddeler.
List<Entry> backlinks(String id) {
  final out = <Entry>[];
  for (final e in store.allEntries(content)) {
    if (e.id != id && linksIn(e.body).contains(id)) out.add(e);
  }
  out.sort((a, b) => a.title.compareTo(b.title));
  return out;
}

String newId(String title) {
  final base = norm(title).replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  var id = 'k-${base.isEmpty ? 'madde' : base}';
  var i = 2;
  while (entryExists(id)) {
    id = 'k-$base-$i';
    i++;
  }
  return id;
}

Widget yearBadges(List<int> years, {double size = 11}) => Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final y in years)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFA8402F), borderRadius: BorderRadius.circular(20)),
            child: Text('$y', style: TextStyle(color: Colors.white, fontSize: size, fontWeight: FontWeight.w700)),
          ),
      ],
    );
