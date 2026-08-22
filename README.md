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

현재 데이터는 `MockAppRepository`의 메모리에 저장됩니다. 앱을 재실행하면
초기 데이터로 돌아갑니다. 서버 API가 준비되면 `AppRepository`를 구현하는
네트워크 Repository로 교체할 수 있습니다.

사진 업로드, 실제 푸시 알림, 영구 저장, 로그인 사용자 간 실시간 채팅은
서버·스토리지 API 연결 단계의 범위입니다. 현재 UI에서는 서버 없이 확인할
수 있는 핵심 사용자 흐름을 로컬 상태로 완성했습니다.

## 실행 방법

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## 아키텍처

프로젝트는 기능 단위(feature-first) MVVM 구조를 사용합니다.

```text
lib/
├── app/                 # 앱 시작점과 5개 탭 셸
├── core/                # 테마, 공통 위젯, 날짜 유틸리티
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
    └── profile/
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

## 서버 연동 시 교체 지점

`lib/domain/repositories/app_repository.dart`의 규칙을 구현하는
`RemoteAppRepository`를 추가하고, `MotiveApp`에서 `MockAppRepository` 대신
주입하면 됩니다. 인증 토큰 저장, 파일 업로드, 실시간 채팅, 푸시 알림은
서버 API가 준비될 때 이 계층에 연결합니다.
