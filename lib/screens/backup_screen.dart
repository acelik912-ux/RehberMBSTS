import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state.dart';

/// Notlar, görseller, eklenen maddeler ve kart durumlarını tek bir .zip dosyasına yedekler.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;

  void _msg(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final arc = Archive();
      final data = utf8.encode(jsonEncode(store.toJson()));
      arc.addFile(ArchiveFile('rehber_veri.json', data.length, data));
      for (final f in store.imgDir.listSync().whereType<File>()) {
        final b = f.readAsBytesSync();
        arc.addFile(ArchiveFile('gorseller/${f.uri.pathSegments.last}', b.length, b));
      }
      final zip = ZipEncoder().encode(arc)!;
      final tmp = await getTemporaryDirectory();
      final d = DateTime.now();
      final out = File('${tmp.path}/rehber-mbsts-yedek-${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}.zip');
      await out.writeAsBytes(zip);
      await Share.shareXFiles([XFile(out.path)], text: 'Rehber MBSTS yedeği');
    } catch (e) {
      _msg('Yedek alınamadı: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = r?.files.single.path;
    if (path == null) return;
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Yedek geri yüklensin mi?'),
        content: const Text('Şu anki notların, maddelerin ve kart durumların yedektekilerle DEĞİŞTİRİLECEK.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Geri yükle')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final arc = ZipDecoder().decodeBytes(File(path).readAsBytesSync());
      Map<String, dynamic>? data;
      for (final f in arc.files) {
        if (!f.isFile) continue;
        final bytes = f.content as List<int>;
        if (f.name == 'rehber_veri.json') {
          data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        } else if (f.name.startsWith('gorseller/')) {
          await store.imageFile(f.name.substring('gorseller/'.length)).writeAsBytes(bytes);
        }
      }
      if (data == null) {
        _msg('Bu dosya bir Rehber MBSTS yedeği değil.');
      } else {
        await store.replaceAll(data);
        _msg('Yedek geri yüklendi.');
      }
    } catch (e) {
      _msg('Geri yüklenemedi: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yedekle / geri yükle')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Notların ve görsellerin yalnızca bu telefonda durur. Telefon değiştirmeden ya da uygulamayı silmeden önce yedek al: '
            'yedek dosyasını kendine e-postayla gönderebilir veya Google Drive\'a kaydedebilirsin.',
          ),
          const SizedBox(height: 16),
          Text('${store.notes.length} not · ${store.custom.length} madde · ${store.cards.length} kart · ${store.overrides.length} düzenleme'),
          const SizedBox(height: 16),
          if (_busy) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: _busy ? null : _export, icon: const Icon(Icons.upload_file), label: const Text('Yedek al ve paylaş')),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: _busy ? null : _import, icon: const Icon(Icons.download), label: const Text('Yedekten geri yükle')),
        ],
      ),
    );
  }
}
