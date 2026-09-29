# Mac·Windows 개발환경 준비

관련 기준 문서:

- [제품·저장소 전체 기준](PROJECT_CONTEXT.md)
- [Flutter 앱 아키텍처](APP_ARCHITECTURE.md)
- 서버 저장소의 `docs/SERVER_ARCHITECTURE.md`
- 서버 저장소의 `docs/DATABASE_SCHEMA.md`

이 프로젝트는 Flutter 앱과 Spring Boot 서버를 **서로 다른 Git 저장소**로 관리합니다.
두 저장소를 같은 상위 폴더 아래에 나란히 두면 경로를 찾기 쉽습니다.

```text
IdeaProjects 또는 C:\dev
├── pathetic_people          # Flutter 앱
└── pathetic_people_server   # Spring Boot 서버 + Flyway SQL
```

Mac과 Windows는 같은 Supabase PostgreSQL 프로젝트에 접속하므로 회원·계획 같은 실제
데이터를 공유합니다. DB 구조는 서버 저장소의 Flyway SQL로 관리합니다.

## 1. Codex 프로젝트 지침도 Git으로 받기

각 저장소 루트의 `AGENTS.md`는 그 저장소를 Codex에서 열었을 때만 적용되는 프로젝트
지침입니다. Codex 계정 전체 설정이나 홈 디렉터리의 전역 지침에는 이 프로젝트 내용을
넣지 않습니다.

다른 PC에서는 별도 복사 없이 다음 순서로 사용합니다.

1. 앱과 서버 저장소를 clone 또는 pull합니다.
2. Codex에서 수정할 **저장소 루트**를 엽니다.
3. 새 Codex 작업을 시작합니다.
4. Codex가 해당 저장소의 `AGENTS.md`와 연결된 `docs`를 참고합니다.

따라서 같은 Codex 계정을 쓰더라도 이 Git 저장소를 열지 않은 다른 프로젝트에는 이 규칙이
적용되지 않습니다. 프로젝트 규칙을 바꾸면 코드처럼 commit/push 해야 다른 PC가 pull할 수
있습니다. 비밀번호·토큰·SDK 절대경로는 `AGENTS.md`나 `docs`에 넣지 않습니다.

## 2. 필요한 프로그램

- Git
- Flutter 팀 기준 `3.47.1`과 Dart `3.13.1`
  - 저장소가 허용하는 최소값은 Flutter `3.44.0`, Dart `3.12.0`입니다.
  - 두 PC에서 팀 기준 버전을 맞추면 빌드 차이를 줄일 수 있습니다.
- Java Development Kit(JDK) 17 이상
  - 앱과 서버의 컴파일 언어 수준은 Java 17입니다.
  - 현재 Mac 터미널 JDK는 26.0.2지만 Windows가 이를 똑같이 설치할 필요는 없습니다.
- Android Studio와 Android 에뮬레이터
- Supabase 계정과 프로젝트
  - 두 PC에서 같은 프로젝트의 Session pooler 접속 정보를 사용합니다.
  - 로컬 PostgreSQL 설치는 필수가 아닙니다.

설치 후 터미널 또는 PowerShell에서 확인합니다.

```bash
git --version
java -version
flutter --version
flutter doctor -v
```

`flutter doctor -v`의 빨간색 `X` 항목 중 실제 사용할 플랫폼의 문제를 먼저 해결합니다.
Android 라이선스가 남았다면 다음 명령도 실행합니다.

```bash
flutter doctor --android-licenses
```

Windows 데스크톱 앱을 만들지 않는다면 Visual Studio 관련 경고는 Android 실행에 영향을
주지 않습니다. iOS 앱 빌드와 iOS Simulator 실행은 Mac과 Xcode가 필요합니다.

2026-08-25 기준 앱 Android 설정은 compile SDK 37, target SDK 36, min SDK 24입니다.
Flutter 앱의 Gradle은 8.14, 서버 Gradle은 9.4.1입니다.

## 3. 두 저장소 받기와 업데이트하기

처음 한 번만 두 저장소를 clone(원격 저장소를 내 컴퓨터로 복사)합니다.

### Mac

```bash
cd ~/IdeaProjects
git clone https://github.com/gyumin-hub/pathetic_people.git
git clone https://github.com/gyumin-hub/pathetic_people_server.git
```

### Windows PowerShell

```powershell
New-Item -ItemType Directory -Force C:\dev
Set-Location C:\dev
git clone https://github.com/gyumin-hub/pathetic_people.git
git clone https://github.com/gyumin-hub/pathetic_people_server.git
```

현재 Mac의 개발 브랜치는 두 저장소 모두 `mac`입니다. PC에서 이 브랜치를 받으려면
먼저 Mac의 변경사항을 GitHub에 push한 다음, 각 저장소에서 다음 명령을 실행합니다.

```bash
git switch mac
git pull --ff-only
```

`git switch mac`이 브랜치를 찾지 못하면 아직 해당 저장소의 `mac` 브랜치가 GitHub에
push되지 않은 상태입니다. Mac에서 먼저 `git push -u origin mac`을 실행해야 합니다.

이미 clone한 뒤에는 **앱과 서버 두 폴더에서 각각** 업데이트합니다.

```bash
cd /path/to/pathetic_people
git status
git pull --ff-only

cd /path/to/pathetic_people_server
git status
git pull --ff-only
```

`git status`에 내가 수정한 파일이 나온다면 바로 pull하지 말고 먼저 커밋하거나 안전하게
보관합니다. 앱만 pull하고 서버를 빼먹으면 API 형식이나 DB 구조가 맞지 않을 수 있습니다.

## 4. Supabase PostgreSQL 준비

1. Supabase에서 프로젝트 하나를 생성합니다.
2. Dashboard 상단의 `Connect`를 엽니다.
3. 일반적인 IPv4 개발 환경에서는 `Session pooler`를 선택합니다.
4. 표시된 host, port, database, username을 복사합니다.
5. DB 비밀번호는 비밀 설정 파일에만 입력합니다.

Supabase 프로젝트의 기본 DB 이름은 보통 `postgres`, Session pooler 포트는 `5432`입니다.
호스트와 username에는 프로젝트별 값이 들어가므로 문서 예시를 조합하지 말고 Dashboard 값을
그대로 사용합니다. 서버가 처음 연결되면 Flyway가 비공개 `motive` 스키마를 만듭니다.

Mac과 Windows가 같은 접속값을 사용하므로 두 PC에서 만든 회원·계획 데이터가 공유됩니다.
Flutter는 DB에 직접 연결하지 않고 항상 Spring API를 거칩니다.

## 5. 서버 비밀 설정 만들기

서버는 DB 비밀번호와 JWT(JSON Web Token, 로그인 토큰) 서명 키를 별도 로컬 파일에서
읽습니다. 예시 파일을 복사해 실제 설정 파일을 만듭니다.

### Mac

```bash
cd /Users/pjh/IdeaProjects/pathetic_people_server
cp -n src/main/resources/application-secret.properties.example \
  src/main/resources/application-secret.properties
```

### Windows PowerShell

```powershell
Set-Location C:\dev\pathetic_people_server
if (-not (Test-Path .\src\main\resources\application-secret.properties)) {
  Copy-Item .\src\main\resources\application-secret.properties.example `
    .\src\main\resources\application-secret.properties
}
```

`-n`과 `Test-Path` 확인은 이미 있는 실제 설정을 실수로 덮어쓰지 않기 위한 장치입니다.
현재 Mac에는 설정 파일이 이미 있으므로 다시 복사하지 않습니다. 새로 만든
`application-secret.properties` 안의 자리표시자만 해당 컴퓨터의 값으로 바꿉니다.

```properties
spring.datasource.url=jdbc:postgresql://YOUR_POOLER_HOST:5432/postgres?sslmode=require
spring.datasource.username=postgres.YOUR_PROJECT_REF
spring.datasource.password=YOUR_SUPABASE_DATABASE_PASSWORD
jwt.secret=YOUR_32_BYTE_OR_LONGER_RANDOM_SECRET
supabase.storage.url=https://YOUR_PROJECT_REF.supabase.co
supabase.storage.secret-key=YOUR_SB_SECRET_KEY
supabase.storage.bucket=motive-plan-proofs
```

다음 보안 규칙은 반드시 지킵니다.

- 실제 DB 비밀번호, JWT 키, Supabase `sb_secret_...` 키는 이 로컬
  `application-secret.properties`에만 입력합니다.
- 실제 값은 README, 개발 문서, 일반 메모장 `.txt`, 채팅, 코드 주석에 적지 않습니다.
- Mac의 실제 secret 파일을 PC로 복사하지 않습니다. 각 컴퓨터에서 예시 파일을 새로 복사합니다.
- `application-secret.properties.example`에는 자리표시자만 두며 실제 값을 넣지 않습니다.
- `application-secret.properties`는 `.gitignore` 대상이므로 절대 강제로 Git에 추가하지 않습니다.

즉, 실행 방법 같은 공통 정보는 이 문서에 기록하고, 비밀번호 자체만 Git에서 제외된 로컬
secret 파일에 둡니다.

## 6. Flyway로 DB 구조 맞추기

Flyway는 서버가 시작될 때 버전 순서대로 SQL 파일을 한 번씩 실행해 DB 구조를 맞추는
도구입니다. 파일 위치는 서버 저장소의 다음 경로입니다.

```text
src/main/resources/db/migration-postgresql/
├── V1__legacy_schema.sql          # users 등 기존 기본 테이블
├── V2__motive_core.sql            # plans, proofs, posts, notifications 등 핵심 테이블
└── V3__normalize_user_emails.sql  # 이메일 소문자 정규화와 unique 보강
```

현재 새 DB에는 V1부터 V3까지 자동 적용됩니다. 다음 DB 구조 변경부터 아래처럼 V4를
새로 추가합니다.

```text
V4__create_example_table.sql
V5__add_example_column.sql
```

규칙은 다음과 같습니다.

1. 이미 한 번 적용한 `V1`부터 `V3`는 수정하거나 이름을 바꾸지 않습니다.
2. 새 테이블·컬럼·인덱스는 다음 번호인 `V4`, `V5` 파일로 추가합니다.
3. Supabase SQL Editor에서만 `ALTER TABLE`을 실행하지 않습니다. 반드시 Flyway SQL로 남깁니다.
4. Flyway SQL을 서버 저장소에 커밋하고 PC에서 pull한 뒤 서버를 실행합니다.
5. 그러면 공용 Supabase DB에 아직 없는 버전만 순서대로 적용됩니다.

적용 결과는 Supabase SQL Editor에서 확인할 수 있습니다.

```sql
SELECT installed_rank, version, description, success
FROM flyway_schema_history
ORDER BY installed_rank;
```

새 Supabase DB에서는 `FLYWAY_BASELINE_ON_MIGRATE=false`를 유지합니다.
체크섬 오류가 발생했을 때 migration 파일이나 `flyway_schema_history`를 임의로 지우지 말고
먼저 어떤 적용 완료 파일이 변경됐는지 확인합니다.

## 7. Spring Boot 서버 실행

Supabase 프로젝트가 실행 중이고 인터넷 연결이 가능해야 합니다.

### Mac

```bash
cd /Users/pjh/IdeaProjects/pathetic_people_server
./gradlew bootRun
```

### Windows PowerShell

```powershell
Set-Location C:\dev\pathetic_people_server
.\gradlew.bat bootRun
```

첫 실행에는 Gradle이 라이브러리를 내려받아 시간이 조금 걸릴 수 있습니다. 로그에서 Flyway가
V1·V2를 적용하고 Spring 서버가 `8080` 포트에서 시작됐는지 확인합니다. 다음 요청에서
`401 Unauthorized`가 오면 로그인 토큰이 없다는 뜻이며, 서버 연결 자체는 성공한 것입니다.

```bash
curl -i http://127.0.0.1:8080/api/auth/me
```

서버는 실행한 터미널에서 `Ctrl+C`를 눌러 종료합니다.

## 8. Flutter 앱의 서버 주소

앱은 빌드 시 `API_BASE_URL`로 서버 주소를, `APP_TIMEZONE`으로 계획 생성에 사용할 IANA
시간대를 받습니다. 주소 끝의 `/`는 넣지 않는 것을 권장합니다.

현재 앱은 시작할 때 저장된 로그인 토큰을 서버에서 확인하는 인증 게이트 구조입니다. 서버가
꺼져 있어도 Flutter 앱은 실행되지만 로그인·회원가입 화면까지만 확인할 수 있습니다. 피드,
계획, 채팅, 프로필 등 5개 탭으로 들어가려면 PostgreSQL에 연결된 Spring 서버를 먼저 실행하고 로그인해야
합니다. 계획 조회·생성·텍스트 인증도 서버를 사용하므로 `flutter run`만 성공했다고 전체
기능이 실행 가능한 상태는 아닙니다.

| 앱 실행 위치 | 서버 주소 | 이유 |
| --- | --- | --- |
| Android 에뮬레이터 | `http://10.0.2.2:8080` | 에뮬레이터에서 개발 컴퓨터를 가리키는 특별 주소 |
| macOS 앱 | `http://127.0.0.1:8080` | 앱과 서버가 같은 Mac에서 실행됨 |
| iOS Simulator | `http://127.0.0.1:8080` | Simulator와 서버가 같은 Mac을 사용함 |
| Chrome/web | `http://127.0.0.1:8080` | 브라우저와 서버가 같은 컴퓨터에서 실행됨 |
| 실제 휴대폰 | `http://<Mac의-LAN-IP>:8080` | 휴대폰에서 Mac의 서버로 Wi-Fi를 통해 접속함 |

Android 에뮬레이터는 `localhost`나 `127.0.0.1`을 쓰면 에뮬레이터 자기 자신을 가리키므로
Mac의 Spring 서버에 연결되지 않습니다. 반대로 `10.0.2.2`는 실제 휴대폰에서 쓸 주소가
아닙니다.

먼저 앱 의존성을 받고 실행 가능한 기기 ID를 확인합니다.

```bash
cd /Users/pjh/IdeaProjects/pathetic_people
flutter pub get
flutter devices
```

각 플랫폼 실행 예시는 다음과 같습니다. `<device-id>`는 `flutter devices` 결과로 바꿉니다.

```bash
# Android 에뮬레이터
flutter run -d <android-device-id> \
  --dart-define=API_BASE_URL=http://10.0.2.2:8080 \
  --dart-define=APP_TIMEZONE=Asia/Seoul

# macOS 앱
flutter run -d macos \
  --dart-define=API_BASE_URL=http://127.0.0.1:8080 \
  --dart-define=APP_TIMEZONE=Asia/Seoul

# iOS Simulator
flutter run -d <ios-simulator-id> \
  --dart-define=API_BASE_URL=http://127.0.0.1:8080 \
  --dart-define=APP_TIMEZONE=Asia/Seoul

# Chrome/web
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://127.0.0.1:8080 \
  --dart-define=APP_TIMEZONE=Asia/Seoul
```

값을 생략하면 앱이 Android에서는 `http://10.0.2.2:8080`, macOS·iOS·web에서는
`http://127.0.0.1:8080`을 API 기본값으로, `Asia/Seoul`을 시간대 기본값으로 사용합니다.
다른 지역에서는 `America/Los_Angeles`처럼 실제 IANA 이름을 넣습니다. 명시적으로 적어
두면 어떤 서버와 시간대를 사용하는지 실행 명령만 보고 확인할 수 있습니다.

로컬 web 개발을 위해 서버는 `http://localhost:<임의 포트>`와
`http://127.0.0.1:<임의 포트>`에서 오는 브라우저 요청을 허용합니다. 배포된 외부 웹
도메인은 현재 허용 대상이 아니므로, 나중에 web을 배포할 때 서버 CORS(Cross-Origin
Resource Sharing, 다른 출처의 브라우저 요청 허용) 설정에 그 도메인을 별도로 추가해야 합니다.

### 실제 휴대폰에서 Mac 서버 연결

Mac과 휴대폰을 같은 Wi-Fi에 연결합니다. Mac의 Wi-Fi LAN IP를 확인합니다.

```bash
ipconfig getifaddr en0
```

예를 들어 `192.168.0.23`이 나오면 다음처럼 실행합니다.

```bash
flutter run -d <phone-device-id> \
  --dart-define=API_BASE_URL=http://192.168.0.23:8080 \
  --dart-define=APP_TIMEZONE=Asia/Seoul
```

Mac의 IP는 네트워크가 바뀌면 달라질 수 있으므로 실행할 때 다시 확인합니다. 연결되지 않으면
Mac 방화벽에서 Java의 수신 연결을 허용했는지, 두 기기가 같은 Wi-Fi인지 확인합니다.
iPhone에서는 처음 연결할 때 motive의 로컬 네트워크 접근 확인 창이 나타납니다. 같은 Wi-Fi의
Mac 서버와 통신하려면 `허용`을 선택합니다. 이 안내 문구는 iOS의
`NSLocalNetworkUsageDescription` 설정에 포함되어 있습니다.

## 9. 매번 실행하는 순서

처음 설정을 끝낸 뒤에는 다음 순서만 지키면 됩니다.

1. 앱 저장소와 서버 저장소에서 `git status`를 확인하고 `git pull --ff-only` 합니다.
2. 각 PC의 Git 제외 secret 파일에 Supabase 접속값이 있는지 확인합니다.
3. 서버 폴더에서 `./gradlew bootRun` 또는 `.\gradlew.bat bootRun`을 실행합니다.
4. Flyway 완료와 서버 `8080` 시작 로그가 나올 때까지 기다립니다.
5. Android 에뮬레이터 또는 테스트 기기를 켭니다.
6. 앱 폴더에서 `flutter pub get`을 실행합니다.
7. 대상에 맞는 `API_BASE_URL`과 `APP_TIMEZONE`으로 `flutter run`을 실행합니다.
8. 종료할 때 앱과 서버 터미널에서 `Ctrl+C`를 누릅니다.

데이터 흐름은 다음과 같습니다.

```text
Flutter 입력
-> API_BASE_URL의 Spring 서버:8080 (계획 시각은 APP_TIMEZONE 포함)
-> application-secret.properties의 접속 정보
-> Supabase PostgreSQL의 motive 스키마
-> JSON 응답
-> Flutter 화면 갱신
```

## 10. 자주 생기는 포트 충돌

### `8080` 충돌

`8080`은 Spring 서버 포트입니다. IntelliJ 또는 다른 터미널에서 서버를 이미 켜 두면 새
서버가 `Port 8080 was already in use` 오류로 종료됩니다.

Mac 확인:

```bash
lsof -nP -iTCP:8080 -sTCP:LISTEN
```

Windows 확인:

```powershell
netstat -ano | findstr :8080
```

기존 Spring 실행 창에서 `Ctrl+C`를 누르거나 IntelliJ의 Stop 버튼으로 정상 종료한 뒤 다시
실행합니다. 포트를 임의로 바꾸면 Flutter의 `API_BASE_URL`도 같은 포트로 바꿔야 합니다.

## 11. Git 체크리스트

### Git에 올려야 하는 것

- Flutter의 `lib/`, `test/`, 필요한 플랫폼 설정 코드
- `pubspec.yaml`, `pubspec.lock`
- 서버의 Java 코드, Mapper XML, 테스트 코드
- `src/main/resources/db/migration-postgresql/V숫자__설명.sql` Flyway 파일
- 자리표시자만 있는 `application-secret.properties.example`
- README와 `docs/`의 공통 개발 문서

### Git에 올리면 안 되는 것

- 실제 값이 든 `application-secret.properties`
- 실제 DB 비밀번호, JWT 키, OAuth client secret이 들어간 파일·문서·메모
- DB dump와 Supabase connection string
- Flutter의 `.dart_tool/`, `build/`, Gradle의 `.gradle/` 같은 생성물
- 개인 IDE 설정인 `.idea/`, `.vscode/`
- 운영체제가 만든 `.DS_Store`

커밋 직전에는 두 저장소에서 각각 `git status`와 `git diff`를 확인합니다. 파일 이름에
`secret`, `password`, `.env`가 보이면 실제 값이 없는지 한 번 더 확인합니다.
