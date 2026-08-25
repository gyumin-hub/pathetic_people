# Motive Flutter project instructions

## Project identity

- The product name shown to users is `motive`; the Dart package and repository are
  `pathetic_people`.
- This is a content-first social self-improvement app. A user schedules a plan,
  optionally records a start proof, and records a completion proof before the
  verification deadline. A missed deadline triggers an opt-in spicy mentor message.
- Plans are private by default. A plan is never posted merely because it was created.
  Only explicitly shared start/completion proofs or an explicitly allowed public
  failure may become feed content.
- The tone is cheeky and fact-based, not hateful. Respect the user's mentor intensity
  and public-failure settings. Never target protected traits, threaten the user, or
  encourage self-harm.

## Repositories and source-of-truth documents

- Flutter repository: `https://github.com/gyumin-hub/pathetic_people.git`
- Sibling Spring repository: `https://github.com/gyumin-hub/pathetic_people_server.git`
- Keep both repositories next to each other on each development computer.
- This repository-root `AGENTS.md` is project-scoped and should be committed. It applies
  when Codex works in this repository; it is not an account-wide or global instruction.
- Read [docs/PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md) before changing product
  behavior or cross-repository contracts.
- Read [docs/APP_ARCHITECTURE.md](docs/APP_ARCHITECTURE.md) before changing Flutter
  structure or state flow.
- Read [docs/DEVELOPMENT_SETUP.md](docs/DEVELOPMENT_SETUP.md) for Mac/Windows, MySQL,
  API-address, and Git setup.
- Server API and DB details live in the sibling repository at
  `../pathetic_people_server/docs/SERVER_ARCHITECTURE.md` and
  `../pathetic_people_server/docs/DATABASE_SCHEMA.md`.

## Verified baseline (2026-08-25)

- Team Flutter baseline: `3.47.1 stable`; declared minimum: `>=3.44.0`.
- Team Dart baseline: `3.13.1`; declared constraint: `^3.12.0`.
- App version: `1.0.0+1`.
- Android: compile SDK 37, target SDK 36, min SDK 24, Java bytecode 17,
  Gradle 8.14, AGP 8.11.1, Kotlin 2.2.20.
- Direct packages are locked in `pubspec.lock`; do not hand-edit the lockfile.
- Server baseline: Java 17 target, Spring Boot 4.0.6, MySQL 8.0/8.4.

When versions change, update this file, `docs/PROJECT_CONTEXT.md`, and the relevant
setup/architecture document in the same commit.

## Current implementation boundary

- Real server-backed features: signup, login, `/me`, JWT restore, secure token storage,
  logout, and per-authenticated-user content-session isolation.
- Still in-memory through `MockAppRepository`: feed, explore, plans, proofs, profile,
  preferences, follow state, comments, likes, saves, and chat.
- The Spring server already exposes plan/proof/feed/failure APIs, but this Flutter app
  does not call them yet.
- There is no real media upload, OS push delivery, social graph, realtime chat, or
  production OAuth flow yet. Do not describe placeholders as completed features.
- The next integration slice is planner create/read/start-proof/completion-proof,
  followed by media upload, server feed, push, social actions, and chat.

## Architecture and coding rules

- Keep feature-first MVVM: `presentation -> view_model -> repository -> data source`.
- Widgets/pages render state and collect input; they must not call HTTP or persistence
  APIs directly.
- Put framework-independent models/contracts/rules under `domain`; put implementations
  and DTO mapping under `data`; put reusable infrastructure under `core`.
- Keep feature folders independent. Move a widget to `core/widgets` only when multiple
  features genuinely reuse it.
- Use constructor injection. Do not introduce a service locator or a state-management
  package without an explicit architecture decision and documentation update.
- Existing content state uses `ChangeNotifier` and `Listenable`; dispose repositories,
  clients, view models, controllers, and subscriptions that own resources.
- Use `snake_case` files, `PascalCase` types, `camelCase` members, leading `_` for
  library-private members, single quotes, `const`/`final` where possible, and immutable
  models with `copyWith` where appropriate.
- Preserve the five bottom tabs: feed, explore, planner/calendar, chat, profile.
- Keep layouts usable at 360 logical pixels and with keyboard/text scaling.

## Server-integration rules

- The app never connects directly to MySQL. The only valid path is
  `Flutter -> Spring HTTP API -> MySQL`.
- API base URL comes from `--dart-define=API_BASE_URL=...`; do not hardcode a developer
  machine address in Dart source.
- Android emulator localhost is `http://10.0.2.2:8080`; macOS/iOS simulator/web use
  `http://127.0.0.1:8080`; a physical phone uses the development computer's LAN IP.
- Keep API DTOs separate from domain/UI models and map explicitly.
- Do not reuse the current synchronous `void` content contract for network mutations
  without deciding how loading, retry, failure, and optimistic state are represented.
- Coordinate endpoint, enum, time, and migration changes with the sibling server in the
  same task. Dates crossing the API must include an offset; store server instants in UTC.
- Never commit tokens, DB passwords, OAuth secrets, keystores, signing files, `.env`,
  `android/local.properties`, or machine-specific absolute SDK paths.

## DB and Git rules relevant to Flutter work

- DB structure is owned by server Flyway migrations, never by Flutter code.
- Mac and Windows local DB rows do not sync; only schema migrations sync through Git.
- Do not edit already-applied `V1`/`V2`; add the next migration in the server repository.
- Before work: pull both repositories and inspect `git status` in both.
- Preserve unrelated user changes. Do not modify generated platform/plugin files unless
  the requested platform change requires it.
- If an API contract, implementation status, tool version, or architectural decision
  changes, update the relevant project docs in the same commit.

## Verification

Run proportionate checks after Flutter changes:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

For Android/platform changes, also run an appropriate build or device smoke test. An
analyzer pass does not validate excluded native project files. Report exactly what was
run and what was not run.

## Communication

- Explain code and setup decisions in beginner-friendly Korean.
- Lead with the outcome, then explain data flow, why the change belongs in that layer,
  and how to verify it.
- Define unfamiliar terms the first time, especially API, migration, transaction,
  repository, and deadline/verification window.
