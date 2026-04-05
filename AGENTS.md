# Repository Guidelines

## Project Structure & Module Organization
`lib/` contains application code. Keep UI in `lib/screens/`, navigation in `lib/router/`, state in `lib/providers/`, integrations in `lib/services/`, and shared styling in `lib/theme/`. Entry points stay in `lib/main.dart` and `lib/app.dart`.  
`assets/` stores map styles, logos, and generated glyph PBFs used by MapLibre. Custom fragment shaders live in `shaders/`. Platform shells are under `android/`, `ios/`, and `web/`. Use `tools/` for glyph-generation utilities only; avoid mixing app runtime code into that directory.

## Build, Test, and Development Commands
- `flutter pub get`: install Dart and Flutter dependencies.
- `flutter run`: launch the app on the default device.
- `flutter run -d chrome`: quick web iteration when mobile hardware is not needed.
- `dart format .`: apply standard Dart formatting before review.
- `flutter analyze`: run static analysis with `flutter_lints`.
- `flutter test`: run the Flutter test suite in `test/`.
- `npm install --prefix tools` then `node tools/generate_glyphs.js`: regenerate MapLibre glyph PBFs after font changes.

## Coding Style & Naming Conventions
Use 2-space indentation and keep code compatible with the rules from `analysis_options.yaml`. Follow Dart naming conventions: `snake_case.dart` for files, `PascalCase` for types and widgets, and `camelCase` for members. Keep widgets small and move reusable logic into providers or services instead of growing `main.dart` or screen files. Prefer descriptive names such as `map_screen.dart`, `supabase_service.dart`, and `router.dart`.

## Testing Guidelines
Use `flutter_test` for unit and widget tests. Name test files `*_test.dart` and mirror the feature under test when possible. The current suite is minimal, so new behavior should add targeted tests for routing, providers, and screen-level UI state. Run `flutter test` locally before opening a PR.

## Commit & Pull Request Guidelines
Recent history uses Conventional Commit prefixes such as `feat:`; continue with `feat:`, `fix:`, `refactor:`, or `docs:` followed by a short summary. Pull requests should describe the change, list the commands you ran, link any related issue, and include screenshots or recordings for visible UI updates such as splash, theme, or map changes.

## Configuration & Assets
Do not commit secrets or Supabase credentials outside approved config paths. When editing `pubspec.yaml`, keep asset declarations in sync with files added under `assets/` or `shaders/`. Avoid manual edits in `build/` or dependency folders such as `node_modules/`.
