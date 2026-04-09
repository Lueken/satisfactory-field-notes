import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

const _webClientId =
    '361744710738-o407ujuace2vcef2lh0nvbqu9rq6n2jv.apps.googleusercontent.com';

class AuthService {
  final _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: _webClientId,
  );

  GoogleSignInAccount? _user;
  String? _idToken;

  GoogleSignInAccount? get user => _user;
  String? get idToken => _idToken;
  bool get isSignedIn => _user != null && _idToken != null;

  Future<bool> signIn() async {
    try {
      _user = await _googleSignIn.signIn();
      if (_user == null) return false;
      final auth = await _user!.authentication;
      _idToken = auth.idToken;
      return _idToken != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signInSilently() async {
    try {
      _user = await _googleSignIn.signInSilently();
      if (_user == null) return false;
      final auth = await _user!.authentication;
      _idToken = auth.idToken;
      return _idToken != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _user = null;
    _idToken = null;
  }

  /// Refresh the token if expired
  Future<String?> getFreshToken() async {
    if (_user == null) return null;
    final auth = await _user!.authentication;
    _idToken = auth.idToken;
    return _idToken;
  }
}

final authServiceProvider = Provider((_) => AuthService());
