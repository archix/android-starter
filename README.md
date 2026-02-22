# Android Starter

An opinionated Android project template built with **Kotlin**, **Jetpack Compose**, and **Clean Architecture (MVVM + UDF)**.

## What's Included

- **Jetpack Compose** with Material 3 and a ready-to-use design system
- **Clean Architecture** layers: `data/`, `domain/`, `feature/`
- **Hilt** for dependency injection
- **Retrofit + OkHttp** for networking with Kotlinx Serialization
- **Room** for local storage
- **Coil 3** for image loading
- **Type-safe Compose Navigation**
- **JUnit 6 + MockK + Turbine** for testing
- **CI/CD** with GitHub Actions (PR checks + Firebase App Distribution)
- **ktlint** with pre-commit hook
- **Gradle Version Catalog** (`libs.versions.toml`)

## Quick Start

1. **Clone the template:**
   ```bash
   git clone git@github.com:archix/android-starter.git my-app
   cd my-app
   ```

2. **Run the bootstrap script:**
   ```bash
   ./bootstrap.sh com.company.appname MyApp
   ```
   This will:
   - Replace all package name references (`com.starter.app` → your package)
   - Replace all app name references (`Starter` → your app name)
   - Rename source directories and the Application class
   - Update `settings.gradle.kts` and theme names
   - Remove the old `google-services.json`
   - Reinitialize git history with a clean first commit

3. **Complete the manual setup** (printed by the script):
   - Add your `google-services.json` from Firebase console to `app/`
   - Create GitHub repository secrets: `FIREBASE_APP_ID`, `FIREBASE_SERVICE_ACCOUNT_JSON`, `NVD_API_KEY`
   - Run `./scripts/install-hooks.sh` to set up the pre-commit hook
   - Create a `designers` tester group in Firebase App Distribution

## Developer Setup

Install the Git pre-commit hook:

```bash
./scripts/install-hooks.sh
```

This runs `ktlintCheck` before each commit to catch style issues early.
If the hook fails, run `./gradlew ktlintFormat` to auto-fix and then re-commit.

## Project Structure

```
app/src/main/java/com/starter/app/
├── core/
│   ├── designsystem/      # Design tokens, themes, shared UI atoms
│   ├── extensions/         # Kotlin extension functions
│   ├── navigation/         # Routes and NavGraph
│   └── utils/              # Pure utility classes
├── data/
│   ├── local/              # Room DAOs, entities, database
│   ├── remote/             # Retrofit APIs, DTOs
│   └── repository/         # Repository implementations
├── domain/
│   ├── model/              # Domain models (pure Kotlin)
│   ├── repository/         # Repository interfaces
│   └── usecase/            # Use cases
└── feature/
    └── [feature_name]/
        ├── ui/             # Composables
        └── viewmodel/      # ViewModel, UiState, Events
```

See [CLAUDE.md](CLAUDE.md) for the full architecture guide, coding conventions, and component patterns.
