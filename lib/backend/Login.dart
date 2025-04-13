import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'DBHelper.dart';

class LoginManager {
  final DBHelper _dbHelper = DBHelper();

  // Méthode pour hacher le mot de passe
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Insérer un utilisateur (email, mot de passe en clair, nom d'utilisateur)
  Future<void> insertUser(String email, String password, {String? username}) async {
    final db = await _dbHelper.database;

    final hashedPassword = _hashPassword(password);

    await db.insert(
      'users',
      {
        'email': email,
        'password': hashedPassword,
        'username': username ?? '',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Vérifier les identifiants
  Future<bool> checkLogin(String email, String password) async {
    final db = await _dbHelper.database;

    final hashedPassword = _hashPassword(password);

    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashedPassword],
    );

    return result.isNotEmpty;
  }

  // Récupérer l'utilisateur (optionnel)
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }
}
