import 'package:flutter/material.dart';

import '../app_state.dart';
import '../reminder.dart';
import '../tts.dart';
import '../widgets/read_bar.dart';
import 'backup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  String get _time => '${store.remindH.toString().padLeft(2, '0')}:${store.remindM.toString().padLeft(2, '0')}';

  Future<void> _apply(bool on) async {
    setState(() => _busy = true);
    var ok = true;
    try {
      if (on) {
        ok = await reminder.schedule(store.remindH, store.remindM);
      } else {
        await reminder.cancel();
      }
    } catch (e) {
      ok = false;
    }
    store.remindOn = on && ok;
    await store.save();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(!on
          ? 'Hatırlatma kapatıldı.'
          : ok
              ? 'Her gün $_time\'da hatırlatılacak.'
              : 'Bildirim izni verilmedi. Ayarlar > Uygulamalar > Rehber MBSTS > Bildirimler\'den açabilirsin.'),
    ));
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: store.remindH, minute: store.remindM));
    if (t == null) return;
    store.remindH = t.hour;
    store.remindM = t.minute;
    await _apply(true);
  }

  @override
  Widget build(BuildContext context) => Readable(
        label: 'sınav bilgileri',
        items: () => [ReadItem('Sınav bilgileri', 'Sınava ${daysToExam()} gün kaldı. Sınav 4 Nisan 2027 Pazar günü. Başvurular 9 ile 17 Şubat 2027 arasında, geç başvuru 25 Şubat. Sonuçlar 21 Nisan 2027 de açıklanacak. Altmış soru, doksan dakika. Dağılım: fıkıh yirmi, Kuran bilgisi yedi, tefsir yedi, kelam yedi, hadis yedi, siyer ve İslam tarihi yedi, mezhepler üç, dinler tarihi iki soru. Yanlış doğruyu götürmez.')],
        child: _page(context),
      );

  Widget _page(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active),
            title: const Text('Günlük hatırlatma'),
            subtitle: Text(store.remindOn ? 'Her gün $_time' : 'Kapalı'),
            value: store.remindOn,
            onChanged: _busy ? null : _apply,
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Hatırlatma saati'),
            subtitle: Text(_time),
            enabled: !_busy,
            onTap: _pickTime,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.save_alt),
            title: const Text('Yedekle / geri yükle'),
            subtitle: const Text('Notlar, görseller, kartlar ve deneme sonuçları'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen())),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Sınava ${daysToExam()} gün kaldı (4 Nisan 2027).\nBaşvuru: 9–17 Şubat 2027 · Geç başvuru: 25 Şubat 2027 · Sonuç: 21 Nisan 2027',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
