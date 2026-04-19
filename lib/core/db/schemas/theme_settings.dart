import 'package:isar/isar.dart';

part 'theme_settings.g.dart';

@Collection()
class ThemeSettings {
  Id id = 0; // Fixed ID for single settings row

  int backgroundColor = 0xFF010000;
  int surfaceColor = 0xFF030000;
  int cardColor = 0xFF050505;
  int accentColor = 0xFFFF0055;
  int textPrimaryColor = 0xFFFFFFFF;
  int textSecondaryColor = 0xB3FFFFFF; // 70% opacity white
  int borderColor = 0x26FF0055; // 15% opacity accent
}
