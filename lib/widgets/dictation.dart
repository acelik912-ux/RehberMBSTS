import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../tts.dart';

/// Mikrofonla konuşarak yazdırma: söylenenleri Türkçe yazıya çevirip metin kutusuna ekler.
/// Durdur'a basılana kadar dinlemeye devam eder (kısa sessizliklerde kendini yeniden başlatır).
class DictationPanel extends StatefulWidget {
  final TextEditingController controller;
  const DictationPanel({super.key, required this.controller});

  @override
  State<DictationPanel> createState() => _DictationPanelState();
}

class _DictationPanelState extends State<DictationPanel> {
  final SpeechToText _stt = SpeechToText();
  bool _ready = false;
  bool _want = false; // kullanıcı dinlemeyi açık tutmak istiyor
  bool _listening = false;
  String _partial = '';
  String? _locale;
  String? _error;

  @override
  void dispose() {
    _want = false;
    _stt.cancel();
    super.dispose();
  }

  Future<bool> _init() async {
    if (_ready) return true;
    try {
      _ready = await _stt.initialize(onStatus: _onStatus, onError: _onError);
      if (_ready) {
        final locales = await _stt.locales();
        final tr = locales.where((l) => l.localeId.toLowerCase().startsWith('tr'));
        _locale = tr.isNotEmpty ? tr.first.localeId : 'tr_TR';
      }
    } catch (e) {
      _ready = false;
      _error = '$e';
    }
    return _ready;
  }

  void _onStatus(String s) {
    final listening = s == SpeechToText.listeningStatus;
    if (mounted) setState(() => _listening = listening);
    if ((s == SpeechToText.doneStatus || s == SpeechToText.notListeningStatus) && _want) {
      // Sessizlik yüzünden durduysa kaldığı yerden devam et.
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (_want && mounted && !_stt.isListening) _listen();
      });
    }
  }

  void _onError(SpeechRecognitionError e) {
    // "eşleşme yok" ve "zaman aşımı" sessizlikte normaldir; dinlemeye devam edilir.
    if (e.errorMsg == 'error_no_match' || e.errorMsg == 'error_speech_timeout') return;
    if (e.errorMsg == 'error_busy') return;
    if (mounted) {
      setState(() {
        _error = _message(e.errorMsg);
        if (e.permanent) _want = false;
      });
    }
  }

  String _message(String code) => switch (code) {
        'error_permission' || 'error_insufficient_permissions' => 'Mikrofon izni verilmedi. Ayarlar > Uygulamalar > Rehber MBSTS > İzinler.',
        'error_network' || 'error_network_timeout' || 'error_server' => 'Ses tanıma için internet gerekiyor olabilir.',
        'error_language_not_supported' || 'error_language_unavailable' => 'Türkçe ses tanıma paketi yok. Google uygulamasında Türkçe dil paketini indir.',
        _ => 'Ses tanıma hatası: $code',
      };

  Future<void> _listen() async {
    await _stt.listen(
      onResult: _onResult,
      localeId: _locale,
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 6),
      listenOptions: SpeechListenOptions(partialResults: true, listenMode: ListenMode.dictation, cancelOnError: false),
    );
  }

  void _onResult(SpeechRecognitionResult r) {
    if (!mounted) return;
    if (r.finalResult) {
      _insert(r.recognizedWords);
      setState(() => _partial = '');
    } else {
      setState(() => _partial = r.recognizedWords);
    }
  }

  void _insert(String words) {
    final w = words.trim();
    if (w.isEmpty) return;
    final c = widget.controller;
    final t = c.text;
    final sel = c.selection;
    final pos = sel.isValid ? sel.end : t.length;
    final before = t.substring(0, pos);
    final needSpace = before.isNotEmpty && !before.endsWith(' ') && !before.endsWith('\n');
    var piece = (needSpace ? ' ' : '') + w;
    if (before.isEmpty || before.trimRight().endsWith('.') || before.endsWith('\n')) {
      piece = (needSpace ? ' ' : '') + w[0].toUpperCase() + w.substring(1);
    }
    c.value = TextEditingValue(text: t.replaceRange(pos, pos, piece), selection: TextSelection.collapsed(offset: pos + piece.length));
  }

  Future<void> _toggle() async {
    if (_want) {
      setState(() => _want = false);
      await _stt.stop();
      return;
    }
    setState(() => _error = null);
    if (reader.playing) await reader.stop();
    if (!await _init()) {
      setState(() => _error ??= 'Bu telefonda ses tanıma kullanılamıyor ya da mikrofon izni verilmedi.');
      return;
    }
    setState(() => _want = true);
    await _listen();
  }

  void _punct(String p) {
    final c = widget.controller;
    final t = c.text.trimRight();
    c.value = TextEditingValue(text: '$t$p', selection: TextSelection.collapsed(offset: t.length + p.length));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = _want;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: on ? const Color(0xFFFBECEA) : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: on ? const Color(0xFFA8402F) : Colors.transparent, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          FilledButton.icon(
            style: on ? FilledButton.styleFrom(backgroundColor: const Color(0xFFA8402F)) : null,
            onPressed: _toggle,
            icon: Icon(on ? Icons.stop : Icons.mic),
            label: Text(on ? 'Durdur' : 'Sesle not al'),
          ),
          const SizedBox(width: 8),
          if (on)
            Expanded(
              child: Row(children: [
                Icon(Icons.graphic_eq, color: _listening ? const Color(0xFFA8402F) : Colors.grey),
                const SizedBox(width: 4),
                Flexible(child: Text(_listening ? 'Dinliyorum… konuş' : 'Hazırlanıyor…', style: const TextStyle(fontWeight: FontWeight.w700))),
              ]),
            )
          else
            const Expanded(child: Text('Konuş, yazıya dönüşsün', style: TextStyle(fontSize: 12, color: Colors.grey))),
        ]),
        if (on && _partial.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_partial, style: const TextStyle(fontStyle: FontStyle.italic)),
          ),
        if (on)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(spacing: 6, children: [
              ActionChip(label: const Text('Nokta .'), onPressed: () => _punct('. ')),
              ActionChip(label: const Text('Virgül ,'), onPressed: () => _punct(', ')),
              ActionChip(label: const Text('Yeni satır'), onPressed: () => _punct('\n')),
            ]),
          ),
        if (_error != null)
          Padding(padding: const EdgeInsets.only(top: 6), child: Text(_error!, style: const TextStyle(color: Color(0xFFA8402F)))),
      ]),
    );
  }
}
