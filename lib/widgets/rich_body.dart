import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Madde metnini çizer.
/// Satır biçimleri:  "## Başlık", "- madde", "> ipucu kutusu", "!! tuzak kutusu", "%% akılda tut kutusu", "&& emoji | sahne kutusu".
/// Satır içi: **kalın**, [[madde-id]] veya [[madde-id|görünen yazı]] (dokununca o maddeye gider).
class RichBody extends StatefulWidget {
  final String text;
  final bool Function(String id) exists;
  final void Function(String id) onLink;
  final double fontSize;
  const RichBody({super.key, required this.text, required this.exists, required this.onLink, this.fontSize = 16});

  @override
  State<RichBody> createState() => _RichBodyState();
}

class _RichBodyState extends State<RichBody> {
  final List<TapGestureRecognizer> _recs = [];

  void _clear() {
    for (final r in _recs) {
      r.dispose();
    }
    _recs.clear();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  static final _inline = RegExp(r'\*\*(.+?)\*\*|\[\[([^\]|]+)(?:\|([^\]]+))?\]\]|(https?://[^\s)\]]+)');

  static Future<void> openUrl(String u) async {
    try {
      await launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  TextSpan _urlSpan(String url, String label, Color linkColor) {
    final r = TapGestureRecognizer()..onTap = () => openUrl(url);
    _recs.add(r);
    return TextSpan(
      text: '▶ $label',
      recognizer: r,
      style: TextStyle(color: const Color(0xFFC4302B), fontWeight: FontWeight.w700, decoration: TextDecoration.underline, decorationColor: linkColor),
    );
  }

  static final _mezhep = RegExp(r'(Hanef[iî]|M[âa]lik[iî]|[ŞS][âa]fi[iî]|Hanbel[iî])[^\s,.;:()]*');

  /// Mezhep adları renk koduyla gösterilir: Hanefî mavi, Mâlikî yeşil, Şâfiî sarı, Hanbelî kırmızı.
  List<InlineSpan> _plain(String t) {
    final out = <InlineSpan>[];
    var i = 0;
    for (final m in _mezhep.allMatches(t)) {
      if (m.start > i) out.add(TextSpan(text: t.substring(i, m.start)));
      final k = m.group(1)!.toLowerCase();
      final (dot, col) = k.startsWith('hanef')
          ? ('🔵', const Color(0xFF2B5FA8))
          : k.startsWith('m')
              ? ('🟢', const Color(0xFF3F7A3A))
              : k.startsWith('hanb')
                  ? ('🔴', const Color(0xFFB3402F))
                  : ('🟡', const Color(0xFFB8860B));
      out.add(TextSpan(text: '$dot${m.group(0)}', style: TextStyle(color: col, fontWeight: FontWeight.w700)));
      i = m.end;
    }
    if (i < t.length) out.add(TextSpan(text: t.substring(i)));
    return out;
  }

  List<InlineSpan> _spans(String s, TextStyle base, Color linkColor) {
    final out = <InlineSpan>[];
    var i = 0;
    for (final m in _inline.allMatches(s)) {
      if (m.start > i) out.addAll(_plain(s.substring(i, m.start)));
      if (m.group(4) != null) {
        out.add(_urlSpan(m.group(4)!, m.group(4)!.length > 40 ? 'bağlantıyı aç' : m.group(4)!, linkColor));
      } else if (m.group(2) != null && m.group(2)!.trim().startsWith('http')) {
        out.add(_urlSpan(m.group(2)!.trim(), (m.group(3) ?? 'bağlantıyı aç').trim(), linkColor));
      } else if (m.group(1) != null) {
        out.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w700)));
      } else {
        final id = m.group(2)!.trim();
        final label = (m.group(3) ?? m.group(2))!.trim();
        if (widget.exists(id)) {
          final r = TapGestureRecognizer()..onTap = () => widget.onLink(id);
          _recs.add(r);
          out.add(TextSpan(
            text: label,
            recognizer: r,
            style: TextStyle(
              color: linkColor,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: linkColor.withValues(alpha: 0.5),
            ),
          ));
        } else {
          out.add(TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.w600)));
        }
      }
      i = m.end;
    }
    if (i < s.length) out.addAll(_plain(s.substring(i)));
    return out;
  }

  Widget _rich(String s, TextStyle style, Color link) =>
      Text.rich(TextSpan(style: style, children: _spans(s, style, link)));

  Widget _box(String s, Color bg, Color edge, String label, TextStyle style, Color link) => Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
          border: Border(left: BorderSide(color: edge, width: 4)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: edge)),
          const SizedBox(height: 3),
          _rich(s, style, link),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    _clear();
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final base = TextStyle(fontSize: widget.fontSize, height: 1.5, color: theme.colorScheme.onSurface);
    final link = dark ? const Color(0xFF7FC8CF) : const Color(0xFF0F5C63);
    final kids = <Widget>[];
    for (final raw in widget.text.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        kids.add(const SizedBox(height: 6));
      } else if (line.startsWith('## ')) {
        kids.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: _rich(line.substring(3), base.copyWith(fontSize: widget.fontSize + 3, fontWeight: FontWeight.w800, fontFamily: 'serif'), link),
        ));
      } else if (line.startsWith('- ')) {
        kids.add(Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 9, right: 8), child: Icon(Icons.circle, size: 6, color: link)),
            Expanded(child: _rich(line.substring(2), base, link)),
          ]),
        ));
      } else if (line.startsWith('> ')) {
        kids.add(_box(line.substring(2), dark ? const Color(0xFF16363A) : const Color(0xFFE3F0F0), const Color(0xFF0F7C86), 'İPUCU', base, link));
      } else if (line.startsWith('!! ')) {
        kids.add(_box(line.substring(3), dark ? const Color(0xFF3A1F1B) : const Color(0xFFF8E6E2), const Color(0xFFC0503C), 'DİKKAT / TUZAK', base, link));
      } else if (line.startsWith('%% ')) {
        kids.add(_box(line.substring(3), dark ? const Color(0xFF3A2F17) : const Color(0xFFF7EEDB), const Color(0xFFB9862F), 'AKILDA TUT', base, link));
      } else if (line.startsWith('&& ')) {
        final parts = line.substring(3).split(' | ');
        final strip = parts.length > 1 ? parts.first.trim() : '';
        final text = parts.length > 1 ? parts.sublist(1).join(' | ') : parts.first;
        kids.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF2A2140) : const Color(0xFFF1EBFA),
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
            border: const Border(left: BorderSide(color: Color(0xFF7A4E9A), width: 4)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🎬 SAHNE', style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: Color(0xFF7A4E9A))),
            if (strip.isNotEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(strip, style: const TextStyle(fontSize: 28, height: 1.25))),
            _rich(text, base, link),
          ]),
        ));
      } else {
        kids.add(Padding(padding: const EdgeInsets.only(bottom: 4), child: _rich(line, base, link)));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: kids);
  }
}
