import 'package:flutter/material.dart';

import '../content.dart';

/// Madde için küçük görsel: renkli kutu içinde emoji.
/// Emoji yoksa alanın simgesi gösterilir.
class EntryIcon extends StatelessWidget {
  final Entry entry;
  final double size;
  const EntryIcon({super.key, required this.entry, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final a = areaById(entry.area);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: a.color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: a.color.withValues(alpha: 0.35)),
      ),
      child: entry.icon.isEmpty
          ? Icon(a.icon, color: a.color, size: size * 0.55)
          : Text(entry.icon, style: TextStyle(fontSize: size * 0.55, height: 1.1)),
    );
  }
}

/// Bir grubun maddelerini resimli kartlar hâlinde gösteren ızgara (görsel özet).
class VisualGrid extends StatelessWidget {
  final List<Entry> entries;
  final void Function(Entry e) onTap;
  const VisualGrid({super.key, required this.entries, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - 8) / 2;
      return Wrap(spacing: 8, runSpacing: 8, children: [
        for (final e in entries) SizedBox(width: w, child: _VisualTile(e: e, onTap: () => onTap(e))),
      ]);
    });
  }
}

class _VisualTile extends StatelessWidget {
  final Entry e;
  final VoidCallback onTap;
  const _VisualTile({required this.e, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = areaById(e.area);
    return Material(
      color: a.color.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: a.color.withValues(alpha: 0.4))),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              EntryIcon(entry: e, size: 44),
              const SizedBox(width: 8),
              Expanded(
                child: Text(e.title,
                    maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, color: a.color, fontSize: 14.5)),
              ),
            ]),
            if (e.hint.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(e.hint, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            if (e.summary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(e.summary.replaceAllMapped(linkRe, (m) => m.group(2) ?? m.group(1)!).replaceAll('**', ''),
                    maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ),
          ]),
        ),
      ),
    );
  }
}
