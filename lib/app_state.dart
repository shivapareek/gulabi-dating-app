import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/repo.dart';
import 'models.dart';

/// App-wide state: the signed-in profile, filters, theme and daily limits.
class AppState extends ChangeNotifier {
  UserProfile? me;
  Filters filters = Filters();
  ThemeMode themeMode = ThemeMode.system;
  int likesToday = 0;
  int superLikesToday = 0;
  static const freeDailyLikes = 25;
  static const freeDailySuperLikes = 1;
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    themeMode = ThemeMode.values[_prefs!.getInt('theme') ?? 0];
    final day = _prefs!.getString('day');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (day == today) {
      likesToday = _prefs!.getInt('likes') ?? 0;
      superLikesToday = _prefs!.getInt('supers') ?? 0;
    } else {
      await _prefs!.setString('day', today);
    }
    filters
      ..minAge = _prefs!.getInt('minAge') ?? 18
      ..maxAge = _prefs!.getInt('maxAge') ?? 45
      ..maxKm = _prefs!.getDouble('maxKm') ?? 30
      ..verifiedOnly = _prefs!.getBool('verifiedOnly') ?? false;
  }

  bool get premium => me?.premium ?? false;
  bool get canLike => premium || likesToday < freeDailyLikes;
  bool get canSuperLike =>
      superLikesToday < (premium ? 5 : freeDailySuperLikes);

  void countSwipe(SwipeType t) {
    if (t == SwipeType.like) likesToday++;
    if (t == SwipeType.superLike) superLikesToday++;
    _prefs?.setInt('likes', likesToday);
    _prefs?.setInt('supers', superLikesToday);
    notifyListeners();
  }

  void setTheme(ThemeMode m) {
    themeMode = m;
    _prefs?.setInt('theme', m.index);
    notifyListeners();
  }

  void saveFilters() {
    _prefs?.setInt('minAge', filters.minAge);
    _prefs?.setInt('maxAge', filters.maxAge);
    _prefs?.setDouble('maxKm', filters.maxKm);
    _prefs?.setBool('verifiedOnly', filters.verifiedOnly);
    notifyListeners();
  }

  Future<void> loadMe() async {
    me = await Repo.instance.loadMe();
    notifyListeners();
  }

  Future<void> saveMe(UserProfile p) async {
    await Repo.instance.saveMe(p);
    me = p;
    notifyListeners();
  }
}

final app = AppState();
