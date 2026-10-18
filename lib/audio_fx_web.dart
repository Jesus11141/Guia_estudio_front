import 'dart:js_interop' as js;

@js.JS('playAppAudio')
external void _playAppAudio(js.JSString soundType);

void playWebAudio(String soundType) {
  try {
    _playAppAudio(soundType.toJS);
  } catch (_) {}
}
