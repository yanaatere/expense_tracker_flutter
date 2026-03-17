# Monex Finance — Flutter Migration

## Project Goal
Migrate the Vue 3 PWA (`expense-tracker-pwa`) to Flutter targeting Android + iOS,
preserving all screens, design system, and API integration.

## Key Details
- **App name**: Monex Finance / monex
- **Primary color**: `#635AFF`
- **API**: REST via `--dart-define=API_BASE_URL=...`, JWT Bearer auth
- **Org**: `com.monex`
- **Source PWA**: `/Users/retere/IdeaProjects/personal/expense-tracker-pwa`

---

## Implementation Progress

### ✅ Done

| File | Status |
|------|--------|
| Flutter project scaffolded (`flutter create --org com.monex --platforms android,ios`) | ✅ |
| `assets/images/background.webp` copied from PWA | ✅ |
| `pubspec.yaml` — dependencies + assets configured | ✅ |
| `lib/core/constants/app_colors.dart` | ✅ |
| `lib/core/constants/app_text_styles.dart` | ✅ |
| `lib/core/storage/local_storage.dart` | ✅ |
| `lib/core/services/api_client.dart` | ✅ |
| `lib/core/services/auth_service.dart` | ✅ |
| `lib/features/welcome/welcome_screen.dart` | ✅ |
| `lib/features/auth/sign_in_screen.dart` | ✅ |
| `lib/features/auth/create_account_screen.dart` | ✅ |
| `lib/features/home/home_screen.dart` | ✅ |
| `lib/shared/widgets/primary_button.dart` | ✅ |
| `lib/shared/widgets/rounded_text_field.dart` | ✅ |
| `lib/shared/widgets/social_login_buttons.dart` | ✅ |

| `lib/main.dart` | ✅ |
| `lib/app.dart` — MaterialApp + GoRouter (4 routes + auth redirect) | ✅ |
| `flutter pub get` | ✅ |
| `flutter analyze` — 0 issues | ✅ |

### ⏳ Still To Do

| Task | Notes |
|------|-------|
| Run on Android emulator | Verify all 4 screens + login/register flow |
| Run on iOS simulator | Same verification |
| Set real `API_BASE_URL` via `--dart-define` | Use ngrok endpoint from PWA `.env` |

---

## Dependencies (`pubspec.yaml`)
```yaml
dio: ^5.7.0
shared_preferences: ^2.3.0
go_router: ^14.0.0
flutter_secure_storage: ^9.0.0
google_fonts: ^6.2.1
```

## Routes
| Route | Screen |
|-------|--------|
| `/` | WelcomeScreen |
| `/signin` | SignInScreen |
| `/create-account` | CreateAccountScreen |
| `/home` | HomeScreen |

Redirect rule: if token exists → `/` redirects to `/home`

## API Contracts (from PWA)
- `POST /auth/register` body `{username, email, password}` → `{id, username, email, token}` (201)
- `POST /auth/login` body `{email, password}` → `{token, username}` (200)

## Design Notes
- Background image fills screen on all screens
- Auth screens (sign in / create account): white bottom sheet card with `BorderRadius.vertical(top: Radius.circular(40))`, slides up on entry
- Inputs: `BorderRadius.circular(40)`, fill `#F8F9FB`, height 54px
- Primary button: `#635AFF` fill, `BorderRadius.circular(40)`, height 52px
- Logo: Inter black 60px, color `#2121D3`, lowercase

## Skills Available
- `skills/flutter-mobile-dev.skill` — Flutter architecture, BLoC, Dio, notifications
- `skills/flutter-build.skill` — Android/iOS build, signing, Fastlane, CI/CD
