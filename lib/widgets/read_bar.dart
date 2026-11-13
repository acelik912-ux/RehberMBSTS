import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../content.dart';
import '../tts.dart';

/// Her sayfanın "ne okunacak" bilgisini tutar; en üstteki sayfanınki altta düğme olarak gösterilir.
class ReadRegistry extends NavigatorObserver with ChangeNotifier {
  final List<_ReadableState> _pages = [];

  void _changed() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      scheduleMicrotask(notifyListeners);
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  void _add(_ReadableState s) {
    if (!_pages.contains(s)) _pages.add(s);
    _changed();
  }

  void _remove(_ReadableState s) {
    _pages.remove(s);
    _changed();
  }

  /// Şu an ekranda en üstte olan sayfanın okuma bilgisi.
  Readable? get current {
    for (final s in _pages.reversed) {
      final r = s.route;
      if (s.mounted && r != null && r.isCurrent) return s.widget;
    }
    return null;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _changed();
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _changed();
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _changed();
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _changed();
}

final readRegistry = ReadRegistry();

/// Sayfayı sarar; alttaki "Sesli oku" düğmesi bu sayfanın içeriğini okur.
class Readable extends StatefulWidget {
  final String label;
  final List<ReadItem> Function() items;
  final Widget child;
  const Readable({super.key, required this.label, required this.items, required this.child});

  @override
  State<Readable> createState() => _ReadableState();
}

class _ReadableState extends State<Readable> {
  ModalRoute<dynamic>? route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    route = ModalRoute.of(context);
    readRegistry._add(this);
  }

  @override
  void didUpdateWidget(covariant Readable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label != widget.label) readRegistry._changed();
  }

  @override
  void dispose() {
    readRegistry._remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Boştayken altta duran "Sesli oku" çubuğu.
class ReadBar extends StatelessWidget {
  final Readable page;
  const ReadBar({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: () async {
            final items = page.items();
            if (items.isEmpty) {
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Bu sayfada okunacak bir şey yok.')));
              return;
            }
            reader.playItems(items);
            await Future<void>.delayed(const Duration(milliseconds: 600));
            if (reader.turkishMissing && context.mounted) {
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
                duration: Duration(seconds: 6),
                content: Text('Telefonda Türkçe ses paketi bulunamadı. Ayarlar > Genel yönetim > Metin okuma bölümünden Türkçe sesi indir.'),
              ));
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(children: [
              Icon(Icons.volume_up, color: scheme.onSecondaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Sesli oku: ${page.label}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSecondaryContainer)),
              ),
              Icon(Icons.play_circle_fill, color: scheme.onSecondaryContainer, size: 28),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Uygulamanın çerçevesi: sayfa + altta okuma çubuğu (çalıyorsa oynatıcı, boştaysa "Sesli oku").
class AppFrame extends StatelessWidget {
  final Widget child;
  final Widget player;
  const AppFrame({super.key, required this.child, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([reader, readRegistry]),
      builder: (context, _) {
        final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
        final page = readRegistry.current;
        final Widget? bar = reader.playing ? player : (page != null && !keyboard ? ReadBar(page: page) : null);
        if (bar == null) return child;
        return Column(children: [
          Expanded(child: MediaQuery.removePadding(context: context, removeBottom: true, child: child)),
          bar,
        ]);
      },
    );
  }
}

/// Alan rengi (okuma çubuğunda kullanılır).
Color itemColor(ReadItem? i) => areaById(i?.area ?? 'hadis').color;
