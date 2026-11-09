import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehber_mbsts/app_state.dart';
import 'package:rehber_mbsts/content.dart';
import 'package:rehber_mbsts/screens/home_screen.dart';
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
}
