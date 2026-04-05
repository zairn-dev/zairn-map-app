# Zairn Map

Privacy-first location sharing app built with Flutter.

Part of the [Zairn](https://github.com/zairn-dev/Zairn) ecosystem.

## Features

- **MapLibre GL** vector tile map with custom style
- **Real-time location sharing** with friends via Supabase Realtime
- **Background GPS tracking** with privacy processing
- **Feed** with location-anchored posts (text, images)
- **Friend system** with requests, intimacy scores, blocking
- **Ghost mode** to temporarily hide your location
- **Profile & settings** management

## Architecture

```
lib/
  core/           # App config, router, navigation shell, shared widgets
  features/       # Feature modules (auth, map, feed, friends, profile, settings)
  services/       # Supabase client, glyph server
  theme/          # Material Design 3 theme system
```

Each feature follows `data/` (models + service) / `presentation/` (screens) / `providers/` (Riverpod state).

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | Flutter, Material Design 3, Liquid Glass |
| Map | MapLibre GL, OpenFreeMap tiles, custom SDF fonts |
| State | Riverpod |
| Routing | GoRouter (StatefulShellRoute) |
| Backend | Supabase (Auth, Realtime, Storage, PostgreSQL) |
| SDK | [zairn-flutter](https://github.com/zairn-dev/zairn-flutter) |
| GPS | Geolocator (background tracking) |

## Setup

```bash
# Clone
git clone https://github.com/zairn-dev/zairn-map-app.git
cd zairn-map-app

# Clone SDK (sibling directory)
git clone https://github.com/zairn-dev/zairn-flutter.git ../zairn-flutter

# Install dependencies
flutter pub get

# Run
flutter run
```

### Requirements

- Flutter 3.32+
- Android SDK 36 / Xcode 15+
- Supabase project with [Zairn schema](https://github.com/zairn-dev/Zairn/tree/main/database)

## Brand

| Color | Hex | Role |
|-------|-----|------|
| Teal | `#009688` | Primary (light) |
| Cyan | `#00E5CC` | Primary (dark), map accents |
| Orange | `#FF9800` | Secondary |
| Amber | `#FFAB00` | Secondary (dark) |
| Pink | `#FF2D78` | Tertiary, alerts |

Logo: cairn (stacked stones) with gradient from pink/orange to cyan/amber.

## License

MIT
