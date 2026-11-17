# PULSE AI

Standalone Android-first Flutter assistant. Independent from JAARVIS, SAARTHI and Agent_Crew.

## Features implemented in source
- Animated orb, chat bubbles, three-tab navigation, responsive Material 3 UI.
- Persistent local SQLite message history and user-approved memory CRUD.
- OpenAI-compatible chat completions integration via the OpenAI API.
- API key saved using `flutter_secure_storage`, not checked into source.
- Configurable model ID, history deletion, and visible network errors.
- Unit/widget tests (not executed in the provided environment).

## Build and test on a machine with Flutter SDK and Android SDK

```bash
flutter create --platforms=android .
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The `flutter create` command generates standard Android project scaffolding. The repository intentionally contains application source rather than generated build files.

## Setup
1. Install the APK or run `flutter run` on an Android device.
2. Open Settings and enter your own OpenAI API key (requires a separately billed API account).
3. Confirm a model available to your account; default is `gpt-4o-mini`.
4. Ask a question. Chat and explicitly saved memories persist locally.

## Security and current limitations
- This is a **bring-your-own-key development build**. For production distribution, replace direct mobile-to-provider access with an authenticated proxy. Secure storage reduces exposure at rest but cannot fully protect API credentials from a compromised device.
- Messages and saved memories are sent to OpenAI when an AI response is requested. No background sync is implemented.
- No automatic memory extraction, voice I/O, agentic tool execution, embeddings, or offline language model yet.
- No SDK or Android toolchain was available in the authoring environment, so Flutter compile, Android execution, and tests are **not verified**.
- No app analytics or telemetry is implemented.

## Web preview deployment (GitHub Pages)

The `.github/workflows/flutter_web_pages.yml` workflow creates Flutter platform scaffolding, runs `flutter analyze` and `flutter test`, builds a real Flutter Web bundle, then deploys it to GitHub Pages. Create a **new dedicated repository**, upload this project's contents at its root, and enable **Settings → Pages → Build and deployment → GitHub Actions**. The URL is `https://<github-user>.github.io/<repo-name>/` after a successful workflow.

**Security limitation:** Web preview supports browser-local chat history and explicit memory management. Cloud chat is deliberately disabled on the public web build. A server-side proxy with authentication and abuse controls is required before enabling AI replies. Never publish an OpenAI API key in browser code. Browser data is not SQLite and can be cleared by the browser. Android retains SQLite and secure key storage.

This package has not been compiled in this environment. The GitHub workflow is the build/test gate; inspect its results before calling the release verified.
