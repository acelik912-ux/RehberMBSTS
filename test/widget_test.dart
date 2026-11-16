import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehber_mbsts/app_state.dart';
import 'package:rehber_mbsts/content.dart';
import 'package:rehber_mbsts/reminder.dart';
import 'package:rehber_mbsts/screens/area_screen.dart';
import 'package:rehber_mbsts/screens/cards_screen.dart';
import 'package:rehber_mbsts/screens/deneme_screen.dart';
import 'package:rehber_mbsts/screens/entry_screen.dart';
import 'package:rehber_mbsts/hafiza.dart';
import 'package:rehber_mbsts/screens/home_screen.dart';
import 'package:rehber_mbsts/screens/kapali_sema_screen.dart';
import 'package:rehber_mbsts/screens/saray_screen.dart';
import 'package:rehber_mbsts/screens/notebook_screen.dart';
import 'package:rehber_mbsts/screens/quiz_screen.dart';
import 'package:rehber_mbsts/screens/settings_screen.dart';
import 'package:rehber_mbsts/store.dart';
import 'package:rehber_mbsts/tts.dart';
import 'package:rehber_mbsts/widgets/player_bar.dart';
import 'package:rehber_mbsts/widgets/read_bar.dart';
import 'package:rehber_mbsts/widgets/rich_body.dart';
import 'package:rehber_mbsts/screens/note_editor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('içerik yüklenir, bütün bağlantılar ve soru konuları var olan maddelere gider', () async {
    final c = await Content.load();
    expect(c.entries.length, greaterThan(50));
    final broken = <String>[];
    for (final e in c.entries.values) {
      expect(areas.any((a) => a.id == e.area), isTrue, reason: '${e.id} alanı geçersiz');
      for (final l in linksIn(e.body + e.summary)) {
        if (!c.entries.containsKey(l)) broken.add('${e.id} -> $l');
      }
    }
    expect(broken, isEmpty, reason: broken.join('\n'));
    final noIcon = c.entries.values.where((e) => e.icon.isEmpty || e.hint.isEmpty).map((e) => e.id).toList();
    expect(noIcon, isEmpty, reason: 'görseli olmayan maddeler: $noIcon');
    for (final q in c.questions) {
      expect(q.answer, inInclusiveRange(0, q.options.length - 1));
      if (q.entryId.isNotEmpty) expect(c.entries.containsKey(q.entryId), isTrue, reason: q.text);
    }
  });

  test('sesli okuma metni temizlenir', () async {
    final c = await Content.load();
    expect(clean('Me\'mûn 218/833\'te [[mihne|mihneyi]] başlattı'), "Me'mûn hicri 218, miladi 833'te mihneyi başlattı");
    expect(clean('Koca 1/2, karı 1/4'), 'Koca ikide bir, karı dörtte bir');
    final t = speechText(c.entries['mihne']!);
    expect(t.contains('[['), isFalse);
    expect(t.contains('**'), isFalse);
    expect(chunks(t).every((x) => x.length < 3000), isTrue);
    expect(clean('bkz. https://youtu.be/x ve [[https://a.b|site]]').contains('http'), isFalse);
  });

  test('arama anahtarı şapka ve kesmeden bağımsız', () {
    expect(norm("Mu'tezile"), norm('mutezile'));
    expect(norm('İstishâb'), 'istishab');
  });

  testWidgets('ana sayfa ve bağlantılı metin çizilir', (tester) async {
    content = (await tester.runAsync(() => Content.load()))!;
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();
    expect(find.text('Rehber MBSTS'), findsOneWidget);
    expect(find.text('Hadis'), findsWidgets);

    String? tapped;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RichBody(text: '## Başlık\nMutezile **adl** ilkesi [[mihne|mihne]]ye götürdü.\n> ipucu\n!! tuzak\n%% kod\n- madde', exists: (_) => true, onLink: (id) => tapped = id),
      ),
    ));
    expect(find.textContaining('Başlık'), findsOneWidget);
    expect(tapped, isNull);
  });

  testWidgets('madde, alan, kart, test ve defter ekranları hatasız açılır', (tester) async {
    content = (await tester.runAsync(() => Content.load()))!;
    final tmp = Directory.systemTemp.createTempSync('rehber');
    store.dir = tmp;
    store.imgDir = Directory('${tmp.path}/gorseller')..createSync();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    for (final w in <Widget>[
      const EntryScreen(id: 'mutezile'),
      const EntryScreen(id: 'mihne'),
      const EntryScreen(id: 'hadis'),
      AreaScreen(area: areas.first),
      AreaScreen(area: areas[1]),
      const QuizScreen(area: 'kelam'),
      const NotebookScreen(),
    ]) {
      await tester.pumpWidget(MaterialApp(home: w));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    }
    store.addCards(['adl', 'mihne']);
    await tester.pumpWidget(const MaterialApp(home: CardsScreen()));
    await tester.pump();
    expect(find.text('Kartı çevir'), findsOneWidget);
    await tester.tap(find.text('Kartı çevir'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Bildim'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Bildim'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('deneme gerçek dağılımla 60 soru üretir', () async {
    content = await Content.load();
    final qs = buildDeneme();
    expect(qs.length, 60);
    for (final a in areas.where((a) => a.questions > 0)) {
      expect(qs.where((q) => q.area == a.id).length, a.questions, reason: a.id);
    }
    expect(qs.map((q) => q.text).toSet().length, 60);
  });

  test('eski veri dosyası yeni alanlar olmadan okunur, deneme kaydı gidip gelir', () {
    final s = Store();
    s.replaceAllSync({'v': 1, 'notes': [], 'fav': ['adl']});
    expect(s.denemeler, isEmpty);
    expect(s.remindOn, isFalse);
    expect(s.favorites.contains('adl'), isTrue);
    final d = DenemeResult(1, 3000, {'fikih': [15, 3, 2], 'hadis': [5, 2, 0]});
    final back = DenemeResult.fromJson(Map<String, dynamic>.from(d.toJson()));
    expect(back.right, 20);
    expect(back.wrong, 5);
    expect(back.empty, 2);
    expect(back.total, 27);
    expect(daysToExam(DateTime(2027, 4, 3, 23)), 1);
  });

  testWidgets('deneme, sonuç, test menüsü ve ayarlar ekranları açılır', (tester) async {
    content = (await tester.runAsync(() => Content.load()))!;
    final tmp = Directory.systemTemp.createTempSync('rehber2');
    store.dir = tmp;
    store.imgDir = Directory('${tmp.path}/gorseller')..createSync();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: DenemeScreen()));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Soru 1 / 60'), findsOneWidget);
    await tester.tap(find.text('Sonraki'));
    await tester.pump();
    expect(find.text('Soru 2 / 60'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final qs = buildDeneme();
    final ans = List<int?>.generate(qs.length, (i) => i.isEven ? qs[i].answer : null);
    final res = DenemeResult(DateTime.now().millisecondsSinceEpoch, 4000, {'fikih': [10, 5, 5]});
    for (final w in <Widget>[
      DenemeResultScreen(result: res, questions: qs, answers: ans),
      const QuizMenuScreen(),
      const SettingsScreen(),
      const DenemeHistoryScreen(),
    ]) {
      await tester.pumpWidget(MaterialApp(home: w));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    }
  });

  test('soru sesli okuma metni şıkları ve cevabı içerir', () async {
    content = await Content.load();
    final q = content.questions.first;
    final t = questionItem(q, no: 3, withAnswer: true, chosen: 0).text;
    expect(t.startsWith('3. soru'), isTrue);
    expect(t.contains('A şıkkı'), isTrue);
    expect(t.contains('Doğru cevap'), isTrue);
    expect(questionItem(q).text.contains('Doğru cevap'), isFalse);
  });

  testWidgets('her sayfanın altında Sesli oku çubuğu ve not ekranında mikrofon düğmesi var', (tester) async {
    content = (await tester.runAsync(() => Content.load()))!;
    final tmp = Directory.systemTemp.createTempSync('rehber3');
    store.dir = tmp;
    store.imgDir = Directory('${tmp.path}/gorseller')..createSync();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    Widget app(Widget home) => MaterialApp(
          navigatorObservers: [readRegistry],
          builder: (c, child) => AppFrame(player: const PlayerBar(), child: child!),
          home: home,
        );
    await tester.pumpWidget(app(const EntryScreen(id: 'mihne')));
    await tester.pump();
    await tester.pump();
    expect(find.text('Sesli oku: bu madde'), findsOneWidget);
    await tester.pumpWidget(app(const NoteEditor(entryId: 'mihne')));
    await tester.pump();
    await tester.pump();
    expect(find.text('Sesle not al'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('görsel hafıza içeriği tutarlı, eski veri yeni alan olmadan okunur', () async {
    final c = await Content.load();
    final h = await Hafiza.load();
    expect(h.duraklar.length, 10);
    expect(h.semalar, isNotEmpty);
    for (final t in h.turlar) {
      expect(c.entries.containsKey(t.entryId), isTrue, reason: t.id);
      expect(t.items, isNotEmpty);
      for (final o in t.items) {
        expect(o.stop, inInclusiveRange(1, 10));
        expect(c.entries.containsKey(o.entryId), isTrue, reason: '${t.id} ${o.info}');
      }
    }
    for (final s in h.semalar) {
      expect(s.boxes, isNotEmpty, reason: s.id);
      for (final b in s.boxes) {
        expect(b.rects, isNotEmpty, reason: '${s.id} ${b.text}');
        if (b.entryId.isNotEmpty) expect(c.entries.containsKey(b.entryId), isTrue, reason: '${s.id} ${b.entryId}');
      }
    }
    final st = Store();
    st.replaceAllSync({'v': 1, 'notes': []});
    expect(st.visual, isEmpty);
    st.replaceAllSync({'v': 1, 'vk': {'a|0': true, 'b|1': false}});
    expect(st.visual['a|0'], isTrue);
    expect(st.toJson()['vk'], {'a|0': true, 'b|1': false});
  });

  testWidgets('kapalı şema ve cami sarayı ekranları açılır, bilemedim kart ekler', (tester) async {
    content = (await tester.runAsync(() => Content.load()))!;
    final h = (await tester.runAsync(() => Hafiza.load()))!;
    final tmp = Directory.systemTemp.createTempSync('rehber3');
    store.dir = tmp;
    store.imgDir = Directory('${tmp.path}/gorseller')..createSync();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    for (final w in <Widget>[
      const KapaliSemaListScreen(),
      KapaliSemaScreen(sema: h.semalar.first),
      const SarayScreen(),
      SarayTurScreen(tur: h.turlar.first, duraklar: h.duraklar),
    ]) {
      await tester.pumpWidget(MaterialApp(home: w));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
    }
    // Sına: bilemedim dersen maddenin kartı eklenir.
    await tester.pumpWidget(MaterialApp(home: SarayTurScreen(tur: h.turlar.first, duraklar: h.duraklar)));
    await tester.tap(find.text('Sına'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Bilemedim'), 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Bilemedim'));
    await tester.pump();
    expect(store.cards.containsKey(h.turlar.first.items.first.entryId), isTrue);
  });
}
