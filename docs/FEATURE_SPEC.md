# J.P Codex Model Router 기능 명세

## 1. 목적

`jpk-model-router`는 사용자가 `$jpk-model-router`로 명시적으로 호출한 요청을 분류하여 GPT-5.6 Luna, Terra, Sol 중 하나와 reasoning effort를 선택하고, 서브에이전트 하나에 실제 작업을 맡기는 instruction-only Skill이다.

부모 대화는 분류, 라우팅, 자식 실행, 결과 검증, 실제 실행 경로 보고만 담당한다. 부모 모델 hot-swap은 목표가 아니다.

## 2. Phase 0 공식 사양 확인

2026-08-30 기준 공식 OpenAI 문서에서 다음을 확인했다.

| 확인 항목 | 현재 공식 사양 | MVP 적용 |
|---|---|---|
| Skill 기본 구조 | 폴더의 `SKILL.md`가 필수이고 `agents/openai.yaml`은 UI metadata와 invocation policy에 사용 가능 | 런타임을 두 파일로 제한 |
| 사용자 범위 경로 | `$HOME/.agents/skills` | `$HOME/.agents/skills/jpk-model-router`에 설치 |
| 명시적 호출 전용 | `allow_implicit_invocation: false`이면 `$skill` 명시 호출은 유지하고 암묵 호출은 차단 | 그대로 적용 |
| 서브에이전트 모델·effort | 명시적 spawn 값 또는 agent 설정으로 model과 reasoning effort 지정 가능; 생략하면 상속 또는 기본값 사용 | 둘 다 명시하지 못하면 실행 차단 |
| 기본 역할 | Codex에 `worker`, `explorer` 역할이 존재 | 쓰기 작업은 worker, 읽기 작업은 explorer 우선 |
| 모델 ID | `gpt-5.6-luna`, `gpt-5.6-terra`, `gpt-5.6-sol` | 이 세 ID만 route 대상으로 허용 |
| effort | Codex는 모델·surface에 따라 low, medium, high, xhigh, max 및 ultra 선택지를 제공 | 자동 route는 low, medium, high, xhigh만 사용 |

공식 근거:

- [Codex Skills](https://developers.openai.com/codex/skills)
- [Codex Subagents](https://developers.openai.com/codex/multi-agent)
- [Codex Models](https://developers.openai.com/codex/models)
- [GPT-5.6 model guidance](https://developers.openai.com/api/docs/guides/latest-model)

### 사양 충돌과 해석

공식 문서는 Max와, 지원되는 surface의 Ultra 사용 가능성을 설명한다. MVP의 `MVP_UNSUPPORTED_OVERRIDE`는 OpenAI 제품이 이를 지원하지 않는다는 뜻이 아니라 이 라우터가 Max/Ultra 자동화와 강제 override를 구현하지 않는다는 버전 경계다. 사용자는 필요할 때 모델 UI 또는 `/model`에서 직접 선택한다.

공식 문서는 생략된 자식 model/effort의 상속을 허용하지만, 이 MVP는 경로 검증을 위해 두 값을 항상 명시한다. 이는 공식 기능과 충돌하지 않는 더 엄격한 라우터 불변조건이다.

## 3. 기능 범위

### 3.1 입력

- `$jpk-model-router <작업 요청>`
- `$jpk-model-router route-only: <작업 요청>`
- 선택적 `force=luna|terra|sol`
- 선택적 `effort=low|medium|high|xhigh`
- 선택적 `allow-fallback`

### 3.2 분류

다음 네 차원을 평가한다.

1. Clarity: 완료 조건과 실행 경로의 명확성
2. Scope: 한 파일·한 명령부터 여러 모듈까지의 범위
3. Risk: 보안, 인증, 데이터 손상, 운영 장애, 비가역성
4. Verification: 단순 테스트부터 충돌하는 증거의 판단까지의 난이도

평균 점수를 계산하지 않고 가장 강한 위험 신호를 우선한다.

### 3.3 Route

| Route | Model | Effort | 역할 |
|---|---|---|---|
| L0 | `gpt-5.6-luna` | `low` | explorer 또는 worker |
| L1 | `gpt-5.6-luna` | `medium` | explorer |
| T0 | `gpt-5.6-terra` | `medium` | worker |
| T1 | `gpt-5.6-terra` | `high` | worker |
| S0 | `gpt-5.6-sol` | `high` | explorer 또는 worker |
| S1 | `gpt-5.6-sol` | `xhigh` | worker |

보안·인증·데이터 손실·비가역 변경 신호가 하나라도 있으면 S1을 우선한다. 일반 구현은 T0, 결정적 조회·변환은 L0 또는 L1이 기본이다.

### 3.4 실행 불변조건

- 정상 요청 하나당 쓰기 가능한 자식은 최대 하나다.
- 부모와 자식은 동시에 파일을 수정하지 않는다.
- 자식은 라우터를 재호출하거나 다른 routing child를 만들지 않는다.
- 자식 spawn에 model과 reasoning effort를 명시한다.
- 자식 완료 후 부모가 diff와 테스트를 직접 확인한다.
- 검증 실패 시 같은 자식에게 한 번만 수정 지시한다.
- 자식 실행 도구나 명시적 model/effort 지정이 없으면 기본적으로 수정하지 않는다.

### 3.5 보고

Route-only는 `ROUTE_DECISION`, 실행 차단은 `ROUTING_BLOCKED`, 완료는 `ROUTING_RESULT` 형식을 사용한다. 모든 최종 보고는 requested 값과 verified 값을 분리한다.

## 4. 비기능 요구사항

- 설치 런타임은 `SKILL.md`와 `agents/openai.yaml` 두 파일뿐이다.
- 런타임 코드, 외부 서비스, MCP, 별도 classifier, telemetry를 추가하지 않는다.
- 사용자 설정, shell profile, credential을 읽거나 수정하지 않는다.
- 설치는 idempotent하고 충돌 시 기본 중단한다.
- 사용자에게 보이는 결과는 요청 언어를 따른다.
- 정적 package 검사와 실제 forward evaluation을 구분한다.

## 5. 비범위

- 부모 대화 model hot-swap
- Max 또는 Ultra 자동 선택·강제 override 실행
- 병렬 agent orchestration
- GPT-5.6 외 모델 fallback
- 암묵적 Skill 호출
- 유료 API 호출 또는 중첩 `codex exec` 자동 평가
- GitHub remote, push, release, package publication

## 6. 완료 기준

구현 완료는 package test, 임시 경로 installer test, `git diff --check`, 사용자 범위 dry-run, 설치본과 소스본 해시 일치로 판단한다. 18개 routing case는 새 Codex 대화에서 실제로 실행하기 전까지 미실행 상태로 유지한다.
