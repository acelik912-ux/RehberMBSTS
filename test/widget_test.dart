import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehber_mbsts/app_state.dart';
import 'package:rehber_mbsts/content.dart';
import 'package:rehber_mbsts/screens/area_screen.dart';
import 'package:rehber_mbsts/screens/cards_screen.dart';
import 'package:rehber_mbsts/screens/entry_screen.dart';
import 'package:rehber_mbsts/screens/home_screen.dart';
import 'package:rehber_mbsts/screens/notebook_screen.dart';
import 'package:rehber_mbsts/screens/quiz_screen.dart';
import 'package:rehber_mbsts/tts.dart';
import 'package:rehber_mbsts/widgets/rich_body.dart';

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
    final v = speechText(c.entries['ng-hadis-usulu-4']!);
    expect(v.contains('http'), isFalse);
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
    expect(find.text('Bildim'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
