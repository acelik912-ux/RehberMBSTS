import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../app_state.dart';
import '../screens/entry_screen.dart' show showImage;
import '../store.dart';
import 'player_bar.dart' show navKey;

/// Açık sayfaları izler: baloncuklar sayfa adına (RouteSettings.name) bağlanır ve sayfayla birlikte kayar.
class NotRegistry extends NavigatorObserver with ChangeNotifier {
  final List<Route<dynamic>> _stack = [];
  final Map<Route<dynamic>, double> offsets = {};

  void poke() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      scheduleMicrotask(notifyListeners);
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  Route<dynamic>? get top => _stack.isEmpty ? null : _stack.last;

  /// En üstteki rota bir sayfaysa adı; iletişim kutusu/alt sayfa açıksa null (baloncuklar gizlenir).
  String? get pageKey {
    final r = top;
    if (r is! PageRoute) return null;
    final n = r.settings.name;
    if (n == '/') return 'home';
    return n;
  }

  double get offset => offsets[top] ?? 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    poke();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    offsets.remove(route);
    poke();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    offsets.remove(route);
    poke();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (oldRoute != null) offsets.remove(oldRoute);
    if (i >= 0 && newRoute != null) {
      _stack[i] = newRoute;
    } else if (newRoute != null) {
      _stack.add(newRoute);
    }
    poke();
  }
}

final notRegistry = NotRegistry();

/// Her ekranda, herhangi bir yere basılı tutunca yazılı/resimli baloncuk not eklemeyi sağlar.
class NotKatman extends StatelessWidget {
  final Widget child;
  const NotKatman({super.key, required this.child});

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    if (n is! ScrollUpdateNotification && n is! ScrollEndNotification) return false;
    final ctx = n.context;
    final route = ctx == null ? null : ModalRoute.of(ctx);
    if (route == null) return false;
    final old = notRegistry.offsets[route];
    final now = n.metrics.pixels;
    if (old != now) {
      notRegistry.offsets[route] = now;
      notRegistry.poke();
    }
    return false;
  }

  Future<void> _yeni(Offset local, double width) async {
    final page = notRegistry.pageKey;
    if (page == null) return;
    final ctx = navKey.currentState?.overlay?.context;
    if (ctx == null) return;
    HapticFeedback.mediumImpact();
    final b = Bubble(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      x: (local.dx / width).clamp(0.0, 1.0),
      y: local.dy + notRegistry.offset,
    );
    final res = await showBubbleEditor(ctx, b, isNew: true);
    if (res == BubbleResult.save && (b.text.trim().isNotEmpty || b.images.isNotEmpty)) store.addBubble(page, b);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      return ListenableBuilder(
        listenable: Listenable.merge([notRegistry, store]),
        builder: (context, _) {
          final page = notRegistry.pageKey;
          final off = notRegistry.offset;
          final list = page == null ? const <Bubble>[] : (store.bubbles[page] ?? const <Bubble>[]);
          return Stack(children: [
            NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onLongPressStart: (d) => _yeni(d.localPosition, box.maxWidth),
                child: child,
              ),
            ),
            for (final b in list)
              if (b.y - off > -400 && b.y - off < box.maxHeight + 40)
                Positioned(
                  key: ValueKey(b.id),
                  left: 0,
                  right: 0,
                  top: b.y - off,
                  child: FractionalTranslation(
                    translation: const Offset(0, -1),
                    child: Align(
                      alignment: Alignment(b.x * 2 - 1, 0),
                      child: _BubbleView(page: page!, b: b, width: box.maxWidth),
                    ),
                  ),
                ),
          ]);
        },
      );
    });
  }
}

class _BubbleView extends StatefulWidget {
  final String page;
  final Bubble b;
  final double width;
  const _BubbleView({required this.page, required this.b, required this.width});

  @override
  State<_BubbleView> createState() => _BubbleViewState();
}

class _BubbleViewState extends State<_BubbleView> {
  @override
  Widget build(BuildContext context) {
    final b = widget.b;
    final maxW = (widget.width * 0.72).clamp(120.0, 300.0);
    return GestureDetector(
      onTap: () async {
        final ctx = navKey.currentState?.overlay?.context;
        if (ctx == null) return;
        final res = await showBubbleEditor(ctx, b);
        if (res == BubbleResult.delete) {
          store.removeBubble(widget.page, b);
        } else if (res == BubbleResult.save) {
          if (b.text.trim().isEmpty && b.images.isEmpty) {
            store.removeBubble(widget.page, b);
          } else {
            unawaited(store.save());
          }
        }
      },
      onPanUpdate: (d) => setState(() {
        b.x = (b.x + d.delta.dx / widget.width).clamp(0.0, 1.0);
        b.y += d.delta.dy;
      }),
      onPanEnd: (_) => unawaited(store.save()),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3B0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2C04F)),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (b.images.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: b.text.isEmpty ? 0 : 6),
                  child: Wrap(spacing: 4, runSpacing: 4, children: [
                    for (final m in b.images)
                      GestureDetector(
                        onTap: () {
                          final ctx = navKey.currentState?.overlay?.context;
                          if (ctx != null) showImage(ctx, Image.file(store.imageFile(m)));
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(store.imageFile(m),
                              height: b.images.length == 1 ? 110 : 64,
                              width: b.images.length == 1 ? null : 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(width: 40, height: 40, child: Icon(Icons.broken_image))),
                        ),
                      ),
                  ]),
                ),
              if (b.text.isNotEmpty)
                Text(b.text, style: const TextStyle(fontSize: 14, height: 1.3, color: Color(0xDD000000))),
            ]),
          ),
          CustomPaint(size: const Size(16, 9), painter: _TailPainter()),
        ]),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFF3B0));
    canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(size.width, 0),
        Paint()
          ..color = const Color(0xFFE2C04F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum BubbleResult { save, delete, cancel }

/// Baloncuğu yazı + resimle düzenleme penceresi. Resim kaynakları: galeri, kamera, klavye (çıkartma/GIF/pano).
Future<BubbleResult?> showBubbleEditor(BuildContext context, Bubble b, {bool isNew = false}) {
  return showDialog<BubbleResult>(context: context, builder: (_) => _BubbleEditor(b: b, isNew: isNew));
}

class _BubbleEditor extends StatefulWidget {
  final Bubble b;
  final bool isNew;
  const _BubbleEditor({required this.b, required this.isNew});

  @override
  State<_BubbleEditor> createState() => _BubbleEditorState();
}

class _BubbleEditorState extends State<_BubbleEditor> {
  late final TextEditingController _text = TextEditingController(text: widget.b.text);
  late final List<String> _imgs = List<String>.from(widget.b.images);
  String? _err;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _gallery() async {
    try {
      final files = await ImagePicker().pickMultiImage(imageQuality: 85, maxWidth: 2000);
      for (final f in files) {
        final n = await store.importImage(f.path);
        if (mounted) setState(() => _imgs.add(n));
      }
    } catch (e) {
      if (mounted) setState(() => _err = 'Resim alınamadı: $e');
    }
  }

  Future<void> _camera() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2000);
      if (f != null) {
        final n = await store.importImage(f.path);
        if (mounted) setState(() => _imgs.add(n));
      }
    } catch (e) {
      if (mounted) setState(() => _err = 'Kamera açılamadı: $e');
    }
  }

  Future<void> _fromKeyboard(KeyboardInsertedContent c) async {
    final bytes = c.data;
    if (bytes == null || bytes.isEmpty) {
      setState(() => _err = 'Klavye resmin içeriğini vermedi; galeriden seçmeyi dene.');
      return;
    }
    final ext = c.mimeType.contains('gif') ? '.gif' : c.mimeType.contains('jpeg') ? '.jpg' : '.png';
    final n = await store.importBytes(bytes, ext);
    if (mounted) setState(() { _imgs.add(n); _err = null; });
  }

  void _save() {
    widget.b.text = _text.text.trim();
    widget.b.images
      ..clear()
      ..addAll(_imgs);
    Navigator.pop(context, BubbleResult.save);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.isNew ? 'Baloncuk not' : 'Baloncuğu düzenle'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(
              controller: _text,
              autofocus: true,
              minLines: 2,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Notunu yaz… (klavyeden resim/çıkartma da gönderebilirsin)'),
              contentInsertionConfiguration: ContentInsertionConfiguration(
                allowedMimeTypes: const ['image/png', 'image/jpeg', 'image/gif', 'image/webp'],
                onContentInserted: _fromKeyboard,
              ),
            ),
            const SizedBox(height: 8),
            if (_imgs.isNotEmpty)
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final m in _imgs)
                  Stack(clipBehavior: Clip.none, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(store.imageFile(m), width: 64, height: 64, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(width: 64, height: 64, child: Icon(Icons.broken_image))),
                    ),
                    Positioned(
                      right: -6,
                      top: -6,
                      child: GestureDetector(
                        onTap: () => setState(() => _imgs.remove(m)),
                        child: const CircleAvatar(radius: 10, backgroundColor: Colors.black87, child: Icon(Icons.close, size: 13, color: Colors.white)),
                      ),
                    ),
                  ]),
              ]),
            Wrap(spacing: 6, children: [
              TextButton.icon(onPressed: _gallery, icon: const Icon(Icons.photo_library, size: 18), label: const Text('Galeri')),
              TextButton.icon(onPressed: _camera, icon: const Icon(Icons.photo_camera, size: 18), label: const Text('Kamera')),
            ]),
            if (_err != null) Text(_err!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ]),
        ),
        actions: [
          if (!widget.isNew)
            TextButton(onPressed: () => Navigator.pop(context, BubbleResult.delete), child: const Text('Sil', style: TextStyle(color: Colors.red))),
          TextButton(onPressed: () => Navigator.pop(context, BubbleResult.cancel), child: const Text('Vazgeç')),
          FilledButton(onPressed: _save, child: const Text('Kaydet')),
        ],
      );
}
