# Rabbit Stream

Rabbit Stream is a Flutter music streaming app powered by YouTube Music data.

## Features

- Ad-free music playback
- Search for songs, artists, albums, and playlists
- Full player with queue management
- Lyrics view
- Favorites and listening history
- Downloads for offline playback
- Equalizer and loudness controls
- Backup and restore
- Theme and appearance controls

## Tech Stack

- Flutter
- Dart
- go_router
- flutter_bloc
- Hive
- just_audio

## Getting Started

### Prerequisites

- Flutter SDK (recommended to use FVM)
- Android SDK / Android Studio (for Android builds)

### Setup

```bash
git clone <your-repo-url>
cd MusicPlayer
flutter pub get
flutter run
```

## Build

### Debug APK

```bash
flutter build apk --debug
```

### Release APK (beta flavor)

```bash
flutter build apk --flavor beta --release
```

### Release APK (production flavor)

```bash
flutter build apk --flavor production --release
```

## Android Signing

For release signing, add `android/key.properties` with your keystore values:

```properties
storeFile=path/to/your.jks
storePassword=...
keyAlias=...
keyPassword=...
```

If `key.properties` is missing, local release builds may fall back to debug signing.

## Project Structure

- `lib/screens` - app screens
- `lib/services` - playback, downloads, settings, integrations
- `lib/core` - shared widgets/utilities
- `lib/utils` - helper functions and modal flows

## License

This project is licensed under GPL-3.0. See `LICENSE`.
