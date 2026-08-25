# Motive Flutter 앱 아키텍처

마지막 실제 코드 대조일: **2026-08-25**

제품 전체 범위와 구현 우선순위는 [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md), Mac·Windows의
공통 설치·실행 방법은 [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md)를 먼저 봅니다.

## 1. 기술 기준

- Flutter 팀 기준 `3.47.1 stable`, 프로젝트 최소 `>=3.44.0`
- Dart 팀 기준 `3.13.1`, 프로젝트 제약 `^3.12.0`
- 앱 버전 `1.0.0+1`
- 상태 관리: Flutter `ChangeNotifier`/`Listenable`
- 의존성 주입: 생성자 직접 주입
- HTTP: `http 1.6.0`
- JWT 저장: `flutter_secure_storage 11.0.0`
- 사진 선택: `image_picker 1.2.3`
- lint: `flutter_lints 6.0.0`

라우팅/DI 프레임워크, Firebase, WebSocket, SQLite 같은 별도 패키지는 아직 없습니다.

## 2. 디렉터리 구조

```text
lib/
├─ main.dart
├─ app/
│  ├─ motive_app.dart             # 인증 게이트와 앱 최상위 조립
│  ├─ motive_shell.dart           # 5개 탭과 로컬 실패 검사 생명주기
│  └─ app_content_session.dart    # 로그인 사용자별 콘텐츠 상태 수명
├─ core/
│  ├─ config/                     # API 주소 등 실행 환경
│  ├─ network/                    # 공통 HTTP/오류
│  ├─ theme/                      # 색상, 타이포, 테마
│  ├─ utils/                      # 날짜 등 공통 로직
│  ├─ view_models/                # RepositoryViewModel 기반
│  └─ widgets/                    # 여러 기능이 실제 재사용하는 UI
├─ domain/
│  ├─ models/                     # 콘텐츠 순수 모델
│  ├─ repositories/               # 콘텐츠 데이터 계약
│  └─ services/                   # 독설 생성 같은 도메인 규칙
├─ data/repositories/
│  └─ mock_app_repository.dart    # 현재 콘텐츠 전체의 메모리 구현
└─ features/
   ├─ auth/{data,domain,presentation,view_models}
   ├─ feed/{presentation,view_models}
   ├─ explore/{presentation,view_models}
   ├─ planner/{presentation,view_models}
   ├─ chat/{presentation,view_models}
   └─ profile/{presentation,view_models}
```

현재 `lib/theme`, `lib/widgets` 같은 옛 빈 폴더가 남아 있을 수 있지만 새 공통 코드는
`lib/core` 아래에 둡니다.

## 3. 앱 시작과 세션 흐름

```text
main.dart
  -> MotiveApp
      -> AuthSessionViewModel.restoreSession()
          ├─ checking        -> AuthSplashPage
          ├─ unauthenticated -> AuthPage
          └─ authenticated   -> AppContentSession -> MotiveShell
```

`AppContentSession`은 로그인 사용자 ID와 콘텐츠 repository 하나를 소유하고, 같은
repository를 피드·탐색·계획·채팅·프로필 ViewModel에 주입합니다. 로그아웃하거나 다른
사용자가 로그인하면 이전 세션과 ViewModel을 모두 dispose하고 새 세션을 만듭니다. 이로써
Mock 데이터라도 계정 A의 상태가 계정 B 화면에 그대로 보이지 않게 합니다.

## 4. 계층 책임

```text
사용자 입력
  -> Page / Sheet / Widget
  -> ViewModel
  -> Repository contract
  -> Mock 또는 Remote data source
  -> 상태 변경/응답
  -> ViewModel 알림
  -> UI 재빌드
```

| 계층 | 책임 | 하면 안 되는 일 |
| --- | --- | --- |
| presentation | 화면, 입력, 접근성, 로딩/오류 표시 | 직접 HTTP/DB 호출, 업무 규칙 복제 |
| view_models | 화면 상태, 사용자 명령, repository 호출 | BuildContext 장기 보관, 네트워크 JSON 직접 파싱 |
| domain | 모델, repository 계약, 순수 업무 규칙 | Flutter 화면 위젯 의존 |
| data | API DTO, HTTP/저장소 구현, 모델 매핑 | 화면 표시 결정 |
| core | 여러 기능이 공유하는 인프라·UI | 특정 기능만 쓰는 코드를 성급히 이동 |

## 5. 인증: 현재 실제 원격 기능

인증 흐름은 다음과 같습니다.

```text
AuthPage
  -> AuthSessionViewModel
  -> AuthRepositoryImpl
  -> AuthApiClient
  -> Spring /api/auth/*
  -> SecureAuthTokenStore
```

- `POST /api/auth/signup`
- `POST /api/auth/login`
- `GET /api/auth/me`
- 요청 제한 시간 기본 10초
- 보안 저장 키 `auth_access_token`
- 앱 시작 시 저장 토큰으로 `/me` 확인
- 401이면 저장 토큰 삭제, 일시적 네트워크/5xx면 토큰 보존
- 회원가입 성공 후 자동 로그인하며, 자동 로그인만 실패한 경우 로그인 화면으로 안내

화면 입력 기준은 이메일 형식과 100자 이하, 비밀번호 8자 이상, 회원가입 닉네임 2~20자입니다.

## 6. 콘텐츠: 현재 Mock 기능

`AppRepository` 하나가 사용자, 환경설정, 게시물, 탐색, 계획, 채팅 목록과 변경 명령을
제공합니다. 실제 구현은 `MockAppRepository`입니다.

### 주요 모델

| 모델 | 핵심 내용 |
| --- | --- |
| `AppUser` | Mock 문자열 ID, 프로필, 레벨, 팔로워/팔로잉 |
| `PlanItem` | 상태, 카테고리, 반복, 공개 범위, 시작/마감, 인증, XP |
| `FeedPost` | 성공/실패, 사진 bytes, 계획 연결, 좋아요·댓글·저장 |
| `ChatRoom/ChatMessage` | direct/group/system 방과 메시지 |
| `AppPreferences` | 푸시, 실패 공개, 단체방 알림, 독설 강도 |

### 로컬 실패 판정

앱 실행 직후, 1분마다, 앱이 foreground로 돌아올 때, 계획 탭을 선택할 때 기한 지난 계획을
검사합니다. 이는 데모 UX이고 운영 서버 배치나 OS 푸시가 아닙니다.

- 마감 전 시작/완료 인증 가능
- 사진 필수 계획 또는 성공 글 공유에는 사진 필수
- 성공 공유를 선택했을 때만 성공 Mock 게시물 생성
- 공개 도전 + 실패 공개 허용일 때만 실패 Mock 게시물 생성
- 공개 도전 + 단체방 알림 허용일 때만 그룹 실패 메시지 생성
- 실패 시 개인 시스템 독설 메시지 생성

Mock 반복 일정은 60일 범위를 만들고 남은 범위가 30일 이내일 때 연장합니다.

## 7. 서버 연결 시 바꿔야 할 점

현재 콘텐츠 계약은 메모리 변경을 가정해 대부분 `void` 동기 메서드입니다. HTTP는 실패와
대기가 있으므로 단순히 `MockAppRepository`의 내부만 HTTP로 바꾸면 로딩·오류·재시도 상태를
표현하기 어렵습니다.

권장 단계는 다음과 같습니다.

1. 기능별 async repository 계약을 만듭니다. 예: `PlanRepository`.
2. API request/response DTO와 앱 domain 모델을 분리합니다.
3. `core/network`의 인증 헤더·오류 매핑을 공통으로 사용합니다.
4. ViewModel이 `loading/data/error`와 중복 제출 방지를 소유합니다.
5. UI는 ViewModel 상태만 그립니다.
6. 해당 기능 테스트가 통과하면 그 기능만 Mock에서 원격으로 전환합니다.

중요한 모델 차이도 먼저 해결합니다.

- 서버 사용자 ID는 `long/int`, 콘텐츠 Mock 사용자 ID는 문자열 `'me'`입니다.
- Mock 인증사진은 `Uint8List`, 서버는 현재 `mediaUrl` 문자열만 저장합니다.
- 서버 날짜는 offset 포함 ISO-8601이고 DB에는 UTC instant로 저장합니다.
- 서버의 반복/공개/상태 enum 철자와 Dart enum을 명시적으로 매핑해야 합니다.

## 8. API 주소

API 주소는 `AppEnvironment`가 결정합니다.

| 실행 대상 | 기본/권장 주소 |
| --- | --- |
| Android Emulator | `http://10.0.2.2:8080` |
| macOS 앱 | `http://127.0.0.1:8080` |
| iOS Simulator | `http://127.0.0.1:8080` |
| Chrome/web | `http://127.0.0.1:8080` |
| 실제 휴대폰 | `http://개발PC_LAN_IP:8080` |

다른 주소는 실행 시 주입합니다.

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

개발자의 LAN IP나 사용자 폴더 절대경로를 Dart 소스에 넣지 않습니다.

## 9. 플랫폼 기준

### Android

- application/namespace `com.gymin.pathetic_people`
- compile SDK 37, target SDK 36, min SDK 24
- Java/Kotlin JVM target 17
- Gradle 8.14, AGP 8.11.1, Kotlin 2.2.20
- debug/profile만 로컬 HTTP 허용
- release는 현재 debug signing key이므로 배포 전 반드시 운영 서명 구성

### iOS

- bundle ID `com.gymin.patheticPeople`
- deployment target 13.0
- 카메라, 사진, 로컬 네트워크 설명과 keychain entitlement 있음

### macOS

- bundle ID `com.gymin.patheticPeople`
- 저장소 deployment target 10.15
- sandbox와 network client entitlement 있음

핵심 개발 대상은 Android이며 macOS 실행도 지원합니다. web/Windows/Linux scaffold가 있지만
해당 플랫폼의 제품 완성도를 의미하지 않습니다.

## 10. UI/코딩 규칙

- feature-first MVVM 계층을 유지합니다.
- 파일은 `snake_case`, 타입은 `PascalCase`, 변수/함수는 `camelCase`입니다.
- 한 라이브러리 내부 구현은 `_privateName`으로 숨깁니다.
- 불변 값에 `const`와 `final`, 불변 모델 변경에 `copyWith`를 사용합니다.
- import는 `directives_ordering`을 따르고 문자열은 single quote를 우선합니다.
- 생성자 주입을 사용하고 소유한 resource는 `dispose`합니다.
- 360 logical pixel, 키보드, 큰 글자에서도 overflow가 없게 확인합니다.
- 접근성 label, 입력 오류, 제출 중 중복 터치 방지, 서버 오류 복구를 포함합니다.
- content-first 디자인을 유지하고 성공/실패 색 외 장식색 사용을 절제합니다.

`analysis_options.yaml`은 네이티브 플랫폼 폴더를 analyzer 대상에서 제외합니다. 따라서
`flutter analyze` 통과만으로 Manifest, Gradle, plist, entitlement가 유효하다고 판단하지
않습니다.

## 11. 테스트

현재 테스트 소스에는 73개 테스트가 있으며 인증, 환경, HTTP, repository, 사용자 세션,
360px UI와 앱 shell을 다룹니다.

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

플랫폼 설정을 바꾸면 관련 빌드도 실행합니다.

```bash
flutter build apk --debug
```

테스트 개수는 새 테스트가 추가되면 달라지므로 문서보다 현재 실행 결과를 우선합니다.

## 12. Git에 공유할 것과 공유하지 않을 것

공유합니다.

- `lib`, `test`, 플랫폼 프로젝트 설정
- `pubspec.yaml`, `pubspec.lock`
- `AGENTS.md`, `README.md`, `docs`

공유하지 않습니다.

- `android/local.properties`의 SDK 절대경로
- `.dart_tool`, `build`, IDE 개인 설정
- access token, DB/JWT/OAuth secret
- Android keystore와 `key.properties`
- 사용자 데이터가 들어 있는 DB dump
