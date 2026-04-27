# AI Coding Agent Guidelines for CodeClub

Welcome to the CodeClub project! This document provides essential guidelines for AI coding agents to be productive in this codebase. CodeClub is a Flutter-based application designed to help students find their perfect hackathon team. Below are the key aspects of the project architecture, workflows, and conventions.

## Project Overview

CodeClub consists of the following major components:

- **UI Layer**: Located in `lib/ui/`, this layer contains screens and widgets for the user interface. Example: `profile_screen.dart` for user profile management.
- **Data Layer**: Located in `lib/data/`, this layer handles data services and models. Example: `chat_service.dart` for managing chat-related operations.
- **Core Layer**: Located in `lib/core/`, this layer contains shared utilities and constants.
- **Firebase Integration**: Firebase services like Firestore, Authentication, and Storage are used for backend operations. Configuration files include `google-services.json` and `firebase.json`.

## Developer Workflows

### Building and Running the App

1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Run the app:
   ```bash
   flutter run
   ```

### Testing

- Widget tests are located in the `test/` directory. Example: `widget_test.dart`.
- Run tests using:
  ```bash
  flutter test
  ```

### Firebase Setup

- Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are correctly placed.
- Update Firestore rules in `firestore.rules` as needed.

### Debugging

- Use `flutter run --debug` for debugging.
- Logs can be viewed in the terminal or IDE console.

## Project-Specific Conventions

- **State Management**: Follow the provider pattern for managing state.
- **File Naming**: Use snake_case for file names (e.g., `profile_screen.dart`).
- **Folder Structure**: Organize files by feature (e.g., `ui/screens/profile/` for profile-related screens).
- **Code Style**: Follow Dart's official style guide. Use `dart format` to format code.

## Integration Points

- **Chat Service**: Located in `lib/data/services/chat_service.dart`, this service handles chat-related operations.
- **Team Management**: Firestore collections like `teams` and `users` are used for managing teams and user profiles.
- **Hackathon Management**: Firestore collection `hackathons` stores hackathon details.

## Examples

### Firestore Rules

```firestore
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
match /teams/{teamId} {
  allow read, write: if request.auth != null && request.auth.uid in resource.data.memberIds;
}
```

### Widget Test

Example test in `test/widget_test.dart`:

```dart
testWidgets('Profile screen loads', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  expect(find.text('Profile'), findsOneWidget);
});
```

---

For further details, refer to the [README.md](../README.md) file.