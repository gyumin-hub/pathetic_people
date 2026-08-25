# Motive 프로젝트 기준 문서

마지막 실제 코드 대조일: **2026-08-25**

이 문서는 앱·서버를 함께 개발할 때 사용하는 제품 및 저장소 전체의 기준 문서입니다.
기능 범위나 기술 버전이 바뀌면 코드와 같은 커밋에서 이 문서도 갱신합니다.

## 1. Git 프로젝트 범위의 Codex 지침

Codex 계정 전체에 공통 지침을 저장하지 않습니다. 대신 앱과 서버 **각 저장소 루트**의
`AGENTS.md`와 상세 `docs/`를 Git에 커밋합니다.

```text
GitHub
├─ pathetic_people/AGENTS.md             # 앱 저장소 작업에만 적용
├─ pathetic_people/docs/                 # 제품·앱·개발환경 상세 문서
├─ pathetic_people_server/AGENTS.md      # 서버 저장소 작업에만 적용
└─ pathetic_people_server/docs/          # 서버·DB 상세 문서
```

Codex는 작업을 시작할 때 현재 프로젝트 트리의 `AGENTS.md`를 읽습니다. 따라서 이 저장소를
clone/pull하고 그 루트를 Codex에서 열면 규칙을 참고하지만, 같은 계정의 다른 프로젝트에는
이 지침이 적용되지 않습니다. 계정/홈 디렉터리의 전역 지침에는 이 프로젝트 내용을 넣지
않습니다. 자세한 탐색 방식은
[OpenAI의 AGENTS.md 공식 문서](https://learn.chatgpt.com/docs/agent-configuration/agents-md)를
참고합니다.

다른 PC에서 사용하는 순서는 다음과 같습니다.

1. 앱과 서버 저장소를 같은 상위 폴더에 clone합니다.
2. 두 저장소 모두 작업 브랜치를 `git pull --ff-only`로 최신화합니다.
3. Codex에서 수정할 저장소의 **루트 폴더**를 엽니다.
4. 새 작업을 시작합니다. 그 저장소의 `AGENTS.md`가 프로젝트 규칙으로 적용됩니다.
5. 문서를 방금 수정했는데 기존 작업이 예전 내용을 계속 따르면 새 Codex 작업을
   시작합니다.

프로젝트 상태는 PC 메모장이나 Codex 전역 기억이 아니라 이 Git 문서에 기록합니다.
비밀번호와 토큰은 예외이며 Git에 절대 기록하지 않습니다.

## 2. 제품 한 문장

**motive는 사용자가 자기계발 계획을 세우고 시작·완료를 인증하며, 실패하면 선택한
수위의 매운 멘토 피드백을 받고, 공유하기로 한 성공·실패 기록을 다른 사용자와 즐기는
콘텐츠 중심 자기계발 SNS입니다.**

저장소·Dart 패키지 이름은 `pathetic_people`, 화면에 표시되는 제품 이름은 `motive`입니다.

## 3. 핵심 제품 원칙

### 계획과 게시물은 같은 것이 아니다

- 계획 생성만으로 피드 게시물이 생기지 않습니다.
- 계획은 기본적으로 `PRIVATE`입니다.
- 사용자가 `PUBLIC_CHALLENGE`로 정하고 시작 인증을 공유하면 피드 상단의 `도전 중`
  콘텐츠가 될 수 있습니다.
- 완료 인증에서 공유를 선택하면 성공 게시물이 됩니다.
- 실패 게시물은 공개 도전이면서 사용자가 실패 공개를 허용한 경우에만 생성합니다.

### 시간 용어

- `scheduledAt`: 계획을 시작하기로 한 시각입니다.
- `verificationDueAt`: 완료 인증을 끝내야 하는 마감 시각입니다.
- 유효한 인증 구간은 현재 서버 기준 `scheduledAt <= now < verificationDueAt`입니다.
- 마감까지 완료 인증이 없으면 회차가 `FAILED`가 됩니다.

### 독설과 안전

- 앱 페르소나는 버릇없지만 사실을 짚는 `독설가 멘토`입니다.
- 수위는 `MILD`, `SPICY`, `EXTREME` 중 사용자가 선택합니다.
- 실패 공개와 단체방 알림도 사용자가 직접 켜고 끌 수 있어야 합니다.
- 보호 특성 비하, 혐오, 위협, 성적 모욕, 자해 조장 같은 문구는 사용하지 않습니다.
- 공개 범위를 사용자의 명시적 선택보다 넓히지 않습니다.

## 4. 핵심 사용자 흐름

```text
회원가입/로그인
  -> 계획 생성(시작 시각, 인증 마감, 반복, 공개 범위, 사진 필수 여부)
  -> 선택: 시작 인증 + 공개 도전 공유
  -> 마감 전 완료 인증
       ├─ 공유함  -> 성공 게시물
       └─ 공유 안 함 -> 개인 기록만 저장
  -> 마감까지 미완료
       ├─ 개인 독설 알림 저장
       └─ 공개 도전 + 실패 공개 허용 -> 실패 게시물
```

## 5. 화면 구조

하단 탭은 다섯 개입니다.

| 탭 | 목표 |
| --- | --- |
| 피드 | 팔로잉/추천 게시물, 공개 도전, 좋아요·댓글·공유·저장 |
| 탐색 | 사용자/콘텐츠 검색, 카테고리, 하이라이트 3열 그리드 |
| 계획·달력 | 계획 생성·수정·삭제, 시작/완료 인증, 날짜별 성공·실패 |
| 채팅 | 1:1/그룹 대화와 선택적 실패 시스템 메시지 |
| 프로필 | 프로필, 게시물, 계획 통계, XP/레벨, 설정과 알림 |

디자인은 Instagram처럼 콘텐츠가 주인공인 무채색 content-first UI와 Toss처럼 간결한
정보 구조를 지향합니다. 장식 색은 절제하고 성공/실패 상태를 구분하는 데 우선 사용합니다.

## 6. 두 저장소와 책임

두 저장소는 같은 상위 폴더에 나란히 둡니다.

```text
IdeaProjects 또는 C:\dev
├─ pathetic_people          # Flutter 앱
└─ pathetic_people_server   # Spring Boot API + Flyway + MySQL 접근
```

| 저장소 | 원격 | 책임 |
| --- | --- | --- |
| Flutter | `gyumin-hub/pathetic_people` | Android/iOS/macOS/web UI, 상태, API 호출, 보안 토큰 저장 |
| Spring | `gyumin-hub/pathetic_people_server` | 인증, 업무 규칙, MyBatis SQL, 스케줄러, DB 마이그레이션 |

앱은 MySQL에 직접 접속하지 않습니다.

```text
Flutter -> HTTP/JSON + JWT -> Spring Boot -> MyBatis -> MySQL
```

## 7. 공유 기술 기준

`요구/고정`과 `2026-08-25 Mac 확인값`을 구분합니다. 다른 PC가 Mac의 JDK 26을 그대로
설치할 필요는 없지만, 팀 기준 Flutter 버전은 맞추는 편이 재현성이 좋습니다.

| 항목 | 프로젝트 기준 | 현재 Mac 확인값/설명 |
| --- | --- | --- |
| Flutter | 팀 기준 3.47.1, 선언 최소 3.44.0 | 3.47.1 stable |
| Dart | 팀 기준 3.13.1, 선언 `^3.12.0` | 3.13.1 |
| DevTools | SDK에 포함 | 2.60.0 |
| 앱 버전 | `1.0.0+1` | `pubspec.yaml` |
| Java 언어 타깃 | 17 | 터미널 JDK 26.0.2도 `--release 17`로 사용 가능 |
| Spring Boot | 4.0.6 | Gradle에 고정 |
| Gradle | 앱 8.14 / 서버 9.4.1 | 각 wrapper에 고정 |
| AGP / Kotlin | 8.11.1 / 2.2.20 | 앱 Android 설정에 고정 |
| Android SDK | compile 37 / target 36 / min 24 | API 37 설치 확인 |
| MySQL | 8.0과 8.4 호환 SQL | Mac 8.4.11, Windows 기존 8.0 사용 |
| DB 이름/포트 | `pathetic_people` / 3306 | 각 PC의 로컬 DB |
| Spring 포트 | 8080 | `application.properties` |

정확한 앱 패키지는 `pubspec.lock`, 서버 라이브러리는 Gradle dependency resolution이
결정합니다. 큰 버전 변경은 두 PC에서 테스트한 뒤 문서를 같이 갱신합니다.

## 8. 현재 실제 구현 상태

### 실제 서버와 연결됨

- 이메일 회원가입과 로그인
- BCrypt 비밀번호 해시
- 24시간 JWT 액세스 토큰
- 운영체제 보안 저장소의 토큰 보관
- 앱 재실행 시 `/api/auth/me` 자동 로그인 확인
- 로그아웃과 로그인 사용자별 Mock 콘텐츠 세션 격리

### Flutter UI에서는 동작하지만 메모리 Mock임

- 피드, 탐색, 계획, 시작/완료 인증, 로컬 실패 판정
- 좋아요, 댓글, 저장, 팔로우
- 1:1/그룹 채팅
- 프로필, 통계, XP/레벨, 독설/공개 설정

이 데이터는 앱을 종료하거나 콘텐츠 세션이 새로 만들어지면 초기 seed로 돌아가고 다른
사용자에게 전달되지 않습니다.

### 서버에는 있으나 Flutter가 아직 호출하지 않음

- 계획과 최대 60일 반복 회차 생성/조회
- 시작/완료 인증 메타데이터 저장
- 선택적 성공 게시물
- 60초 간격의 실패 판정과 독설 알림 행
- 선택적 실패 게시물
- 글로벌 피드와 공개 `도전 중` 조회

### 아직 없음

- 실제 사진 업로드와 파일 스토리지
- FCM/APNs 푸시 발송, 기기 토큰, 알림 조회/읽음
- 팔로우 관계 기반 서버 피드
- 서버 좋아요·댓글·저장·공유
- 서버 사용자 검색·차단·신고
- 실제 1:1/그룹/WebSocket 채팅
- refresh token, 비밀번호 재설정, 이메일 인증
- Flutter용 Google/Kakao 모바일 OAuth 완성
- 운영 배포 주소, HTTPS, release 서명

## 9. 구현 우선순위

한 번에 모든 DB/API를 만드는 대신 실제로 실행되는 세로 흐름을 하나씩 완성합니다.

1. Flutter 계획 화면을 기존 Spring 계획 조회·생성 API에 연결합니다.
2. 시작/완료 인증을 서버 API에 연결하고 재시도·오류 UX를 만듭니다.
3. 사진 업로드 스토리지와 업로드 API를 추가합니다.
4. Flutter 피드를 서버 공개 도전/게시물 API에 연결합니다.
5. 실패 알림 worker, 기기 토큰, 실제 푸시를 추가합니다.
6. follow, like/save, comment 순으로 소셜 DB와 API를 추가합니다.
7. 채팅을 마지막 별도 세로 흐름으로 추가합니다.

다음 작업의 기본 시작점은 **1번 계획 API 연결**입니다.

## 10. 문서별 책임

| 파일 | 기준으로 삼는 내용 |
| --- | --- |
| `AGENTS.md` | 앱 저장소에서 Codex가 자동으로 적용할 프로젝트 규칙 |
| `docs/PROJECT_CONTEXT.md` | 제품, 저장소 경계, 버전, 현재 상태와 로드맵 |
| `docs/APP_ARCHITECTURE.md` | Flutter 구조, 상태·데이터 흐름, 코딩 규칙 |
| `docs/DEVELOPMENT_SETUP.md` | Mac/Windows 설치, 실행, 주소, Git workflow |
| 서버 `AGENTS.md` | 서버 저장소의 자동 적용 프로젝트 규칙 |
| 서버 `docs/SERVER_ARCHITECTURE.md` | API, 보안, 트랜잭션, 패키지 구조 |
| 서버 `docs/DATABASE_SCHEMA.md` | Flyway와 전체 DB 구조 |

다음이 바뀌면 문서를 같은 커밋에서 갱신합니다.

- API 경로, JSON 필드, 상태 enum, 인증 방식
- DB migration, 테이블 관계, MySQL 지원 버전
- Flutter/Java/Spring/Android 주요 버전
- 실제 서버 연결과 Mock의 경계
- 제품 공개 규칙, 독설 수위와 안전 정책
- 구현 우선순위 또는 중요한 아키텍처 결정

## 11. 비밀정보 원칙

공유 문서에는 키의 **이름과 설정 위치만** 적습니다. 실제 값은 적지 않습니다.

- 서버 로컬 비밀값: Git 제외 파일 `application-secret.properties` 또는 환경변수
- Flutter 로컬 SDK 경로: Git 제외 파일 `android/local.properties`
- 금지: DB 비밀번호, JWT/OAuth secret, 액세스 토큰, keystore, 운영 인증서, 실제 사용자
  데이터가 든 DB dump

Git은 코드와 DB **구조**를 동기화하지만 로컬 DB의 회원·계획 같은 **행 데이터**를
동기화하지 않습니다.
