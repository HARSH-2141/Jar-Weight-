import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/jar_model.dart';

class JarStorage {
  static const String key = "jar_list";

  /// ================= SAVE FULL LIST =================
  static Future<void> saveJars(List<JarModel> jars) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> jarJsonList =
    jars.map((jar) => jsonEncode(jar.toMap())).toList();

    await prefs.setStringList(key, jarJsonList);

    print("✅ Jars Saved Successfully");
  }

  /// ================= GET ALL JARS =================
  static Future<List<JarModel>> getJars() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jarJsonList = prefs.getStringList(key);

    if (jarJsonList == null) {
      print("⚠ No jars found");
      return [];
    }


    List<JarModel> jars = jarJsonList
        .map((jarJson) =>
        JarModel.fromMap(jsonDecode(jarJson)))
        .toList();

    print("📦 Loaded ${jars.length} jars");
    return jars;
  }

  /// ================= ADD SINGLE JAR =================
  static Future<void> addJar(JarModel newJar) async {
    List<JarModel> jars = await getJars();
    jars.add(newJar);
    await saveJars(jars);
  }

  /// ================= DELETE SINGLE JAR =================
  static Future<void> deleteJar(String id) async {
    List<JarModel> jars = await getJars();
    jars.removeWhere((jar) => jar.id == id);
    await saveJars(jars);

    print("🗑 Jar deleted");
  }

  /// ================= CLEAR ALL DATA =================
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);

    print("🔥 All jars cleared");
  }
}
