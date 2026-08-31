# Mendix IronCalc SpreadUI

**한국어** | [English](README.md)

IronCalc WebAssembly 계산 엔진과 React 워크북을 Glendix 5.2.0 기반 Gleam UI로
연결한 실용적인 오픈소스 Mendix 스프레드시트 위젯이다.

SpreadUI는 단순히 시트를 보여주는 데서 끝나지 않는다. 실제 Mendix datasource를
워크북으로 만들고, 명시적인 다시 불러오기·가져오기·다운로드·저장 흐름을 제공한다.

## 주요 기능

- **실제 Mendix 데이터**: list datasource와 String, 숫자, Boolean, DateTime,
  Enum, AutoNumber attribute를 순서대로 열에 연결한다.
- **선택적 write-back**: 사용자가 **Save to Mendix**를 누를 때만 편집된 일반
  셀을 수정 가능한 Mendix attribute에 반영한다.
- **전체 워크북 보존**: 선택적인 String attribute에 `.ic` 바이트를 base64로
  저장하여 수식, 서식, 시트, 워크북 상태를 다시 복원한다.
- **수식 열**: `=C{row}*D{row}` 같은 템플릿을 지원한다. `{row}`는 실제 시트
  행 번호, `{index}`는 1부터 시작하는 datasource 인덱스로 치환된다.
- **가져오기/내보내기**: IronCalc 기본 `.ic` 파일을 열고 다운로드한다.
- **실용적인 빈 상태**: datasource가 없을 때 업 샘플 또는 빈 워크북을 선택한다.
- **빠른 처리**: WASM 초기화를 캐시하고, 대량 입력 중 계산을 일시 중지한 뒤 한 번만
  평가한다.
- **안전한 저장**: 읽기 전용·미사용·변경 없음 값은 건너뛰고, 타입 변환 실패는
  성공한 변경과 분리하여 개수로 보여준다.
- **반응형 SpreadUI**: light/dark/system 테마, 키보드 포커스, 상태 알림,
  reduced-motion, 모바일 버튼 레이아웃을 제공한다.

## 개발 기준

- Gleam 1.17+
- Glendix **5.2.0**
- Mendraw 2.x
- Lustre 5.7 / Redraw 19.2
- IronCalc workbook 0.8.3 / WASM 0.8.4
- Mendix Pluggable Widgets Tools 11.12
- React 19.2
- Bun 1.4

Glendix 5.2.0이 IronCalc WASM 파일을 AMD/ES 위젯 산출물에 포함하므로, Mendix에
설치한 뒤 CDN이나 외부 런타임 다운로드가 필요하지 않다.

## 빌드

```sh
bun install
gleam deps download
gleam run -m glendix/install --runtime bun
gleam format --check src test
gleam check
gleam build --warnings-as-errors
gleam test --runtime bun
bun test test/*.test.mjs
gleam run -m glendix/build --runtime bun
```

완성된 MPK는 `dist/1.0.0/` 아래에 생성된다.

## Mendix 설정

1. MPK를 Mendix 프로젝트의 `widgets/`에 복사하고 Studio Pro에서 **F4**를 누른다.
2. 상태 저장이 필요하면 위젯을 Data view 안에 둔다.
3. **Rows**에 list datasource를 연결한다.
4. **Columns**를 표시 순서대로 추가하고 attribute, 수식, write-back, 폭을 정한다.
5. 전체 워크북 보존이 필요하면 **Workbook state**에 unlimited String attribute를
   연결한다.
6. 저장 후 commit/refresh/검증이 필요하면 **After save** action을 연결한다.

위젯은 Mendix 객체를 자동 commit하지 않는다. 애플리케이션의 트랜잭션 정책에 맞는
microflow 또는 nanoflow를 After save에 연결하는 방식을 권장한다.

## 데이터 우선순위와 경계 동작

1. 정상적인 저장 워크북 상태가 있으면 가장 먼저 복원한다.
2. 없으면 사용 가능한 datasource와 설정된 columns를 사용한다.
3. 둘 다 없으면 설정에 따라 업무 샘플 또는 빈 워크북을 연다.
4. 중복/빈 헤더는 순서를 유지하면서 자동으로 고유하게 만든다.
5. 수식 열은 계산하지만 Mendix attribute로 write-back하지 않는다.
6. 개별 셀 변환 실패가 다른 성공 저장을 취소하지 않는다.
7. After save는 attribute와 워크북 상태 처리가 끝난 뒤 실행된다.

## 라이선스

이 저장소는 [MIT License](LICENSE)를 적용한다. IronCalc와 Mendix 관련 패키지는
각 upstream 프로젝트의 라이선스와 상표 정책을 그대로 따른다.
