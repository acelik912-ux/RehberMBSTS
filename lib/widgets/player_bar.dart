import 'package:flutter/material.dart';

import '../content.dart';
import '../screens/entry_screen.dart';
import '../tts.dart';

final navKey = GlobalKey<NavigatorState>();

/// Ekranın altında duran sesli okuma çubuğu (bütün sayfalarda görünür).
class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: reader,
      builder: (context, _) {
        final item = reader.current;
        if (item == null) return const SizedBox.shrink();
        final id = item.entryId;
        final color = areaById(item.area).color;
        return Material(
          color: color,
          elevation: 8,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
              child: Row(children: [
                const Icon(Icons.headphones, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: id == null ? null : () => navKey.currentState?.push(MaterialPageRoute(settings: RouteSettings(name: 'e:$id'), builder: (_) => EntryScreen(id: id))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      Text('${reader.index + 1} / ${reader.queue.length} · dinleniyor',
                          style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ]),
                  ),
                ),
                if (reader.queue.length > 1)
                  IconButton(onPressed: reader.previous, icon: const Icon(Icons.skip_previous, color: Colors.white), tooltip: 'Önceki'),
                IconButton(onPressed: reader.stop, icon: const Icon(Icons.stop_circle, color: Colors.white, size: 30), tooltip: 'Durdur'),
                if (reader.queue.length > 1)
                  IconButton(onPressed: reader.next, icon: const Icon(Icons.skip_next, color: Colors.white), tooltip: 'Sonraki'),
                TextButton(
                  onPressed: reader.cycleRate,
                  child: Text('${(reader.rate / 0.5).toStringAsFixed(1)}x', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

/// Madde sayfasındaki "Dinle" düğmesi.
class ListenButton extends StatelessWidget {
  final List<String> ids;
  final String tooltip;
  const ListenButton({super.key, required this.ids, this.tooltip = 'Sesli dinle'});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: reader,
      builder: (context, _) {
        final active = reader.playing && reader.queue.isNotEmpty && reader.queue.first.entryId == ids.first && reader.queue.length == ids.length;
        return IconButton(
          tooltip: active ? 'Durdur' : tooltip,
          icon: Icon(active ? Icons.stop_circle : Icons.headphones),
          onPressed: () async {
            if (active) {
              await reader.stop();
              return;
            }
            reader.playList(ids);
            await Future<void>.delayed(const Duration(milliseconds: 600));
            if (reader.turkishMissing && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                duration: Duration(seconds: 6),
                content: Text('Telefonda Türkçe ses paketi bulunamadı. Ayarlar > Genel yönetim > Metin okuma bölümünden '
                    'Google veya Samsung motorunda Türkçe sesi indir.'),
              ));
            }
          },
        );
      },
    );
  }
}
