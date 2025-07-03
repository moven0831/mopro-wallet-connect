import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:reown_appkit/reown_appkit.dart';

class DeepLinkHandler {
  static const _eventChannel = EventChannel('com.moprowallet/events');
  static late ReownAppKitModal _appKitModal;

  static void init(ReownAppKitModal appKitModal) {
    if (kIsWeb) return;

    try {
      _appKitModal = appKitModal;
      _eventChannel.receiveBroadcastStream().listen(_onLink, onError: _onError);
    } catch (e) {
      debugPrint('[MoproWallet] checkInitialLink $e');
    }
  }

  static void _onLink(dynamic link) async {
    try {
      debugPrint('[MoproWallet] Received deep link: $link');
      await _appKitModal.dispatchEnvelope(link);
    } catch (e) {
      debugPrint('[MoproWallet] Error dispatching envelope: $e');
    }
  }

  static void _onError(dynamic error) {
    debugPrint('[MoproWallet] Deep link error: $error');
  }
} 