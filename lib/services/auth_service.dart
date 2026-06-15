import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import '../models/user_model.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign In with Google
  Future<UserModel?> signInWithGoogle({String role = 'user'}) async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? '412649761434-0cigdf631olndnevkgd154uk94o31j2d.apps.googleusercontent.com' : null,
    );
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null; // User cancelled flow

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential cred = await _auth.signInWithCredential(credential);
    if (cred.user == null) return null;

    // Check if user already exists in Firestore
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    } else {
      // Create new user in Firestore with selected/default role
      final user = UserModel(
        uid: cred.user!.uid,
        name: cred.user!.displayName ?? googleUser.displayName ?? 'Google User',
        email: cred.user!.email ?? googleUser.email,
        role: role,
        createdAt: DateTime.now(),
      );
      await _db.collection('users').doc(user.uid).set(user.toMap());
      return user;
    }
  }

  // Sign Up
  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String password,
    String role = 'user',
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = UserModel(
      uid: cred.user!.uid,
      name: name,
      email: email,
      role: role,
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(user.uid).set(user.toMap());
    await cred.user!.updateDisplayName(name);
    return user;
  }

  // Sign In
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);
    return null;
  }

  // Sign Out
  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await NotificationService().removeTokenFromUser(uid);
      } catch (e) {
        if (kDebugMode) debugPrint('Error removing token on signout: $e');
      }
    }
    await _auth.signOut();
  }

  // Get user role
  Future<String> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) return doc.data()?['role'] ?? 'user';
    return 'user';
  }

  // Get current user model
  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);
    return null;
  }

  // Update Name
  Future<void> updateProfileName(String uid, String newName) async {
    await _db.collection('users').doc(uid).update({'name': newName});
    await _auth.currentUser?.updateDisplayName(newName);
  }

  // Update Password
  Future<void> updateAccountPassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
