import 'package:flutter/material.dart';

import '../app_state.dart';
import '../content.dart';
import '../reminder.dart';
import '../tts.dart';
import '../widgets/read_bar.dart';
import 'area_screen.dart';
import 'cards_screen.dart';
import 'dil_screen.dart';
import 'kapali_sema_screen.dart';
import 'saray_screen.dart';
import 'notebook_screen.dart';
import 'quiz_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Readable(
        label: store.dueCards().any(entryExists) ? 'bugünün tekrar kartları' : 'rastgele 10 madde',
        items: () => (store.dueCards().where(entryExists).isNotEmpty ? store.dueCards().where(entryExists).toList() : (store.allEntries(content).map((e) => e.id).toList()..shuffle()).take(10).toList()).map(entryItem).whereType<ReadItem>().toList(),
        child: _page(context),
      );

  Widget _page(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final due = store.dueCards().length;
        final all = store.allEntries(content);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Rehber MBSTS', style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                tooltip: 'Ayarlar ve yedek',
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              // Arama kutusu
              InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Row(children: [
                    Icon(Icons.search),
                    SizedBox(width: 10),
                    Text('Terim ara: mihne, mürsel, istihsan…'),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              _Countdown(days: daysToExam()),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: _Action(
                    icon: Icons.style,
                    label: 'Tekrar',
                    sub: due == 0 ? '${store.cards.length} kart' : '$due kart bekliyor',
                    color: const Color(0xFFB9862F),
                    badge: due,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CardsScreen())),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Action(
                    icon: Icons.quiz,
                    label: 'Test',
                    sub: '${content.questions.length} soru',
                    color: const Color(0xFFA8402F),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizMenuScreen())),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Action(
                    icon: Icons.edit_note,
                    label: 'Defterim',
                    sub: '${store.notes.length} not',
                    color: const Color(0xFF0F5C63),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotebookScreen())),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: _Action(
                    icon: Icons.visibility_off,
                    label: 'Kapalı şema',
                    sub: 'terimi kapat, hatırla',
                    color: const Color(0xFF7A4E9A),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KapaliSemaListScreen())),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Action(
                    icon: Icons.mosque,
                    label: 'Cami sarayı',
                    sub: '10 durak, hep aynı rota',
                    color: const Color(0xFF2B4C7E),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SarayScreen())),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              _Action(
                icon: Icons.translate,
                label: 'Dil bölümü',
                sub: '1100+ satır: cümle, kalıp, 900+ kelime · tanı testi · tekrar',
                color: const Color(0xFFB8860B),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DilScreen())),
              ),
              const SizedBox(height: 18),
              Text('Alanlar', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final a in areas) _AreaTile(area: a, entries: all.where((e) => e.area == a.id).toList()),
              if (store.history.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Son baktıkların', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final id in store.history.take(12))
                    if (entryExists(id))
                      ActionChip(
                        label: Text(store.resolve(content, id)!.title),
                        onPressed: () => openEntry(context, id),
                      ),
                ]),
              ],
              const SizedBox(height: 20),
              const Text(
                'Sınav: 4 Nisan 2027 · Başvuru: 9–17 Şubat 2027\n60 soru · 90 dakika · yanlış doğruyu götürmez',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final int badge;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.label, required this.sub, required this.color, required this.onTap, this.badge = 0});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(children: [
            Badge(isLabelVisible: badge > 0, label: Text('$badge'), child: Icon(icon, color: Colors.white, size: 28)),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

class _AreaTile extends StatelessWidget {
  final Area area;
  final List<Entry> entries;
  const _AreaTile({required this.area, required this.entries});

  @override
  Widget build(BuildContext context) {
    final read = entries.where((e) => store.read.contains(e.id)).length;
    final p = entries.isEmpty ? 0.0 : read / entries.length;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AreaScreen(area: area))),
        child: Row(children: [
          Container(width: 8, height: 74, color: area.color),
          const SizedBox(width: 12),
          CircleAvatar(backgroundColor: area.color.withValues(alpha: 0.15), child: Icon(area.icon, color: area.color)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(area.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 2),
              Text('${area.questions} soru · ${entries.length} madde · $read okundu', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: p, minHeight: 5, color: area.color, backgroundColor: area.color.withValues(alpha: 0.12)),
              ),
            ]),
          ),
          const Icon(Icons.chevron_right),
          const SizedBox(width: 6),
        ]),
      ),
    );
  }
}

class _Countdown extends StatelessWidget {
  final int days;
  const _Countdown({required this.days});

  @override
  Widget build(BuildContext context) {
    final last = store.denemeler.isEmpty ? null : store.denemeler.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFF2E5A93).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const Icon(Icons.event, color: Color(0xFF2E5A93)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            days > 0 ? 'Sınava $days gün kaldı' : (days == 0 ? 'Sınav bugün, başarılar!' : 'Sınav tamamlandı'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        if (last != null) Flexible(child: Text('Son deneme: ${last.right}/${last.total}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
