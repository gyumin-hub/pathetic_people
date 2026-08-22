# motive

계획을 지키면 성장 기록을 남기고, 실패하면 매운맛 멘토 피드백을 받는
콘텐츠 중심 자기계발 SNS Flutter 앱입니다.

## 현재 구현 범위

- 팔로잉/추천 피드, 스토리, 좋아요, 댓글, 저장, 채팅 공유
- 사용자·콘텐츠 검색, 팔로우, 카테고리 필터, 3열 콘텐츠 탐색
- 날짜별 계획 조회, 추가, 수정, 삭제, 완료 및 반복 일정 처리
- 1분 주기·앱 복귀 시 미달성 판정, 독설 피드와 채팅 자동 생성
- 1:1/그룹 채팅 생성, 검색/필터, 읽음 처리, 메시지 전송
- 프로필 편집, 실제 계획 기반 통계·XP·레벨·연속 기록
- 실패 공개, 단체방 알림, 독설 강도 설정의 로컬 정책 반영
- 실제 서버 회원가입·로그인, JWT 보안 저장, 자동 로그인과 로그아웃

회원가입과 로그인 사용자 정보는 Spring 서버를 거쳐 MySQL에 저장됩니다. 로그인
토큰은 운영체제 보안 저장소에 보관하며 앱을 다시 실행할 때 서버에서 유효성을
확인합니다. 피드·계획·채팅·프로필 콘텐츠는 아직 `MockAppRepository`의 메모리에
저장되므로 앱을 재실행하면 초기 데이터로 돌아갑니다.

다음 서버 연결 범위는 계획 생성·조회이며, 이후 사진 업로드, 실제 푸시 알림,
로그인 사용자 간 소셜 피드와 실시간 채팅을 순서대로 연결합니다.

## 개발환경 준비

Flutter 앱과 Spring Boot 서버는 별도 저장소입니다. Mac·Windows에서 두 저장소를
받는 방법, MySQL 준비, 비밀 설정, Flyway 규칙, 에뮬레이터별 API 주소는
[Mac·Windows 개발환경 준비](docs/DEVELOPMENT_SETUP.md)에 정리되어 있습니다.

실제 DB 비밀번호나 JWT 키는 README나 일반 메모장에 적지 않고, Git에서 제외되는 서버의
`application-secret.properties`에만 저장합니다.

## 앱 실행하기

현재 앱은 로그인에 성공해야 피드·계획·채팅·프로필 화면으로 들어갈 수 있는 인증 게이트
구조입니다. MySQL과 Spring 서버가 꺼진 상태에서도 앱 자체는 실행되지만 로그인·회원가입
화면까지만 확인할 수 있고, 로그인 요청과 자동 로그인은 실패합니다. 기존 로컬 기능이 있는
5개 탭까지 확인하려면 MySQL과 Spring 서버를 먼저 실행한 뒤 로그인해야 합니다.

기본 Flutter 확인 명령은 다음과 같습니다.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Android 에뮬레이터에서 로컬 서버에 연결하는 명시적 실행 예시는 다음과 같습니다.

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

## 아키텍처

프로젝트는 기능 단위(feature-first) MVVM 구조를 사용합니다.

```text
lib/
├── app/                 # 앱 시작점과 5개 탭 셸
├── core/                # 환경 설정, HTTP, 테마, 공통 위젯, 날짜 유틸리티
├── data/repositories/   # 로컬 목 데이터 구현체
├── domain/
│   ├── models/          # 앱이 사용하는 순수 데이터 모델
│   ├── services/        # 독설 메시지 같은 도메인 규칙
│   └── repositories/    # 데이터 접근 규칙(interface)
└── features/
    ├── feed/
    ├── explore/
    ├── planner/
    ├── chat/
    ├── profile/
    └── auth/            # 실제 로그인 세션과 인증 화면
```

데이터 변경 흐름은 다음과 같습니다.

```text
사용자 입력 → Page → ViewModel → AppRepository
           → 데이터 변경 → ViewModel 알림 → Page 갱신
```

### 계층별 규칙

- `presentation`: 화면 표시와 사용자 입력만 담당합니다.
- `view_models`: 화면 상태와 명령을 담당합니다.
- `domain`: Flutter 화면에 의존하지 않는 데이터 규칙입니다.
- `data`: 실제 저장 위치를 담당합니다.
- 기능 폴더끼리 서로 직접 참조하지 않습니다.
- 공통 UI는 `core/widgets`로만 올립니다.

## 다음 서버 연동 지점

`lib/domain/repositories/app_repository.dart`의 규칙을 구현하는
`RemoteAppRepository`를 추가하고, `MotiveApp`에서 `MockAppRepository` 대신
주입하면 됩니다. 인증은 별도 `AuthRepository`를 통해 이미 서버와 연결되어
있으며, 계획부터 `Future` 기반의 네트워크 Repository로 순차 교체합니다.
