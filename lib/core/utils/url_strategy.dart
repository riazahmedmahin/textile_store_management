import 'package:flutter_web_plugins/url_strategy.dart';

/// Configures the URL strategy for Flutter web.
/// Removes the '#' hash from URLs (uses PathUrlStrategy instead of HashUrlStrategy).
void configureUrl() {
  usePathUrlStrategy();
}
