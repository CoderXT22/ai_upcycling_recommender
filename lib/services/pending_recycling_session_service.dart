import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pending_recycling_session.dart';

class PendingRecyclingSessionService {
  const PendingRecyclingSessionService();

  static const _storageKey = 'pending_recycling_session';

  Future<void> save(PendingRecyclingSession session) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(session.toMap()));
  }

  Future<PendingRecyclingSession?> readActive() async {
    final preferences = await SharedPreferences.getInstance();
    final rawValue = preferences.getString(_storageKey);
    if (rawValue == null || rawValue.isEmpty) return null;

    final Object? decoded;
    try {
      decoded = jsonDecode(rawValue);
    } on FormatException {
      await clear();
      return null;
    }

    if (decoded is! Map<String, dynamic>) {
      await clear();
      return null;
    }

    final session = PendingRecyclingSession.fromMap(decoded);
    if (session.isExpired) {
      await clear();
      return null;
    }

    return session;
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }
}
