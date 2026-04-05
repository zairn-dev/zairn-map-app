import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zairn_sdk/zairn_sdk.dart';

import '../../../core/providers/sdk_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(sdkProvider));
});

class AuthService {
  final ZairnSdk _sdk;

  const AuthService(this._sdk);

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _sdk.signIn(email, password);
  }

  Future<void> signUpWithPassword({
    required String email,
    required String password,
  }) {
    return _sdk.signUp(email, password);
  }

  Future<void> signOut() {
    return _sdk.signOut();
  }

  String? get currentUserId => _sdk.currentUserId;
}
