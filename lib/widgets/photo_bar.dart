import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../app_state.dart';
import '../screens/entry_screen.dart' show showImage;

/// İstenen her yere konabilen "Resim ekle" düğmesi. Resimler [slot] anahtarına bağlanır.
/// Kaynaklar: galeri (çoklu), kamera, klavye (Gboard resim/çıkartma) ve pano.
class PhotoBar extends StatelessWidget {
  final String slot;
  final String label;
  const PhotoBar({super.key, required this.slot, this.label = 'Resim ekle'});

  Future<void> _gallery(BuildContext context) async {
    try {
      final files = await ImagePicker().pickMultiImage(imageQuality: 85, maxWidth: 2000);
      for (final f in files) {
        store.attachImage(slot, await store.importImage(f.path));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Resim alınamadı: $e')));
    }
  }

  Future<void> _camera(BuildContext context) async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2000);
      if (f != null) store.attachImage(slot, await store.importImage(f.path));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kamera açılamadı: $e')));
    }
  }

  Future<void> _keyboard(BuildContext context) async {
    await showDialog<void>(context: context, builder: (_) => _KeyboardImageDialog(slot: slot));
  }

  void _menu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.photo_library), title: const Text('Telefondan seç (galeri)'), onTap: () { Navigator.pop(c); _gallery(context); }),
          ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Kamerayla çek'), onTap: () { Navigator.pop(c); _camera(context); }),
          ListTile(leading: const Icon(Icons.keyboard), title: const Text('Klavyeden ekle (resim / çıkartma / pano)'), onTap: () { Navigator.pop(c); _keyboard(context); }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final imgs = store.attach[slot] ?? const <String>[];
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (imgs.isNotEmpty)
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: imgs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (c, i) => GestureDetector(
                    onTap: () => showImage(context, Image.file(store.imageFile(imgs[i]))),
                    onLongPress: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (d) => AlertDialog(
                          title: const Text('Resim silinsin mi?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Vazgeç')),
                            TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Sil')),
                          ],
                        ),
                      );
                      if (ok == true) store.detachImage(slot, imgs[i]);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(store.imageFile(imgs[i]), height: 84, width: 84, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(width: 60, child: Icon(Icons.broken_image))),
                    ),
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: () => _menu(context),
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
              label: Text(imgs.isEmpty ? label : '$label (${imgs.length})'),
            ),
          ]);
        },
      );
}

/// Klavyedeki resim/çıkartma/GIF düğmesinden veya panodan gelen resmi alır.
class _KeyboardImageDialog extends StatefulWidget {
  final String slot;
  const _KeyboardImageDialog({required this.slot});

  @override
  State<_KeyboardImageDialog> createState() => _KeyboardImageDialogState();
}

class _KeyboardImageDialogState extends State<_KeyboardImageDialog> {
  int _count = 0;
  String? _err;

  Future<void> _got(KeyboardInsertedContent c) async {
    final bytes = c.data;
    if (bytes == null || bytes.isEmpty) {
      setState(() => _err = 'Klavye resmin içeriğini vermedi; galeriden seçmeyi dene.');
      return;
    }
    final ext = c.mimeType.contains('gif') ? '.gif' : c.mimeType.contains('jpeg') ? '.jpg' : '.png';
    store.attachImage(widget.slot, await store.importBytes(bytes, ext));
    if (mounted) setState(() { _count++; _err = null; });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Klavyeden resim ekle'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Aşağıdaki kutuya dokun, klavyenin resim / çıkartma / GIF düğmesinden istediğini seç. '
              'Panoya kopyaladığın resmi de kutuya basılı tutup "Yapıştır" ile ekleyebilirsin.', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 10),
          TextField(
            autofocus: true,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Resmi buraya gönder…'),
            contentInsertionConfiguration: ContentInsertionConfiguration(
              allowedMimeTypes: const ['image/png', 'image/jpeg', 'image/gif', 'image/webp'],
              onContentInserted: _got,
            ),
          ),
          if (_count > 0) Padding(padding: const EdgeInsets.only(top: 8), child: Text('$_count resim eklendi.', style: const TextStyle(fontWeight: FontWeight.w700))),
          if (_err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_err!, style: const TextStyle(color: Colors.red, fontSize: 12))),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bitti'))],
      );
}
