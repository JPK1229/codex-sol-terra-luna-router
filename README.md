# J.P Codex Sol/Terra/Luna Model Router

`jpk-model-router`는 현재 부모 대화의 모델을 바꾸는 도구가 아니다. 요청을 분류한 뒤 GPT-5.6 Luna, Terra, Sol 중 하나와 reasoning effort를 명시하여 서브에이전트 하나에 작업을 위임하고, 부모가 결과를 검증하는 개인용 Codex Skill이다.

기능 범위와 구현 기준은 [기능 명세](docs/FEATURE_SPEC.md), 단계별 검증 계획은 [작업 계획](docs/WORK_PLAN.md)에서 확인할 수 있다.

## 동작 구조

```text
명시적 $jpk-model-router 호출
→ 부모가 clarity / scope / risk / verification을 분류
→ model / reasoning effort / role 결정
→ 서브에이전트 하나 실행
→ 부모가 diff와 테스트를 독립적으로 확인
→ 요청값과 검증값을 구분하여 보고
```

부모 모델 hot-swap, 병렬 writer, 별도 분류 모델, MCP, telemetry, cost dashboard는 범위에 포함하지 않는다.

## 설치

먼저 설치 예정 경로와 충돌을 확인한다.

```bash
bash scripts/install.sh --dry-run
bash scripts/install.sh
```

기본 설치 경로는 `$HOME/.agents/skills/jpk-model-router`이다. 테스트나 별도 루트가 필요하면 `JPK_SKILLS_DIR`에 Skill들이 들어갈 부모 디렉터리를 지정한다.

```bash
JPK_SKILLS_DIR=/tmp/jpk-skills bash scripts/install.sh
```

같은 두 파일이 이미 설치되어 있으면 성공 no-op이다. 내용이 다르면 중단하며, 의도적으로 두 런타임 파일을 교체할 때만 `--force`를 사용한다. 예상 밖 파일이나 심볼릭 링크가 있는 대상은 `--force`로도 삭제하지 않는다.

설치되는 파일은 정확히 다음 두 개다.

```text
$HOME/.agents/skills/jpk-model-router/SKILL.md
$HOME/.agents/skills/jpk-model-router/agents/openai.yaml
```

Codex가 새 Skill을 즉시 표시하지 않으면 새 대화를 열거나 Codex를 재시작한다.

## 제거

```bash
bash scripts/uninstall.sh --dry-run
bash scripts/uninstall.sh
```

제거 스크립트는 대상 `SKILL.md`에서 `name: jpk-model-router`를 확인한 경우에만 해당 Skill 디렉터리를 제거한다. 상위 Skill 디렉터리는 삭제하지 않는다.

## 사용

일반 실행:

```text
$jpk-model-router 현재 브랜치의 테스트 실패 원인을 찾고 최소 수정으로 고쳐라.
```

분류만 확인:

```text
$jpk-model-router route-only: 여러 모듈의 cache invalidation 오류 원인을 찾아라.
```

모델과 effort 강제 지정:

```text
$jpk-model-router force=terra effort=high: validator의 경계 조건을 수정하고 테스트하라.
```

## 라우팅 표

| Route | Model | Effort | 기본 역할 | 적용 조건 |
|---|---|---|---|---|
| L0 | `gpt-5.6-luna` | `low` | explorer 또는 worker | 한 파일 오타, 단순 포맷, 정확한 값 추출, 명령 하나 |
| L1 | `gpt-5.6-luna` | `medium` | explorer | 여러 파일 검색, 상태 수집, 로그 정리, 집중 테스트, 결정적 배치 |
| T0 | `gpt-5.6-terra` | `medium` | worker | 일반 구현, 테스트 추가, 표준 리팩터링, 제한된 디버깅 |
| T1 | `gpt-5.6-terra` | `high` | worker | 여러 모듈, 섬세한 불변조건, 비자명한 실패, 높은 재작업 비용 |
| S0 | `gpt-5.6-sol` | `high` | explorer 또는 worker | 아키텍처, 모호한 요구, 충돌하는 증거, 중요한 설계 판단 |
| S1 | `gpt-5.6-sol` | `xhigh` | worker | 인증·보안 경계, 데이터 무결성, 비가역 변경, 큰 운영 피해 위험 |

가장 강한 위험 신호가 우선한다. “매우 중요하다” 같은 강조 표현만으로 route를 높이지 않는다.

## Fallback 의미

명시적인 model-aware subagent 실행을 사용할 수 없으면 기본적으로 작업을 수행하지 않고 `ROUTING_BLOCKED`를 보고한다. 요청에 `allow-fallback`이 있을 때만 현재 부모 대화가 작업을 수행할 수 있으며, 이 경우 선택 route는 추천일 뿐이고 실제 모델 전환은 검증되지 않았다고 명시한다.

## Max와 Ultra

현재 OpenAI 문서상 Max는 지원되는 reasoning 수준이며 Ultra는 지원되는 계정·모델·surface에서 더 깊은 추론과 서브에이전트 위임을 제공할 수 있다. 다만 이 MVP는 비용과 실행 형태를 예측 가능하게 유지하기 위해 Max 또는 Ultra를 자동 선택하거나 강제 override로 실행하지 않는다.

따라서 `MVP_UNSUPPORTED_OVERRIDE`는 Codex 자체의 미지원 선언이 아니라 이 라우터 버전의 의도적인 기능 경계다. 필요하면 사용자가 모델 UI 또는 `/model`에서 직접 선택해야 한다.

## 테스트

```bash
python3 tests/test_package.py
bash tests/test_install.sh
git diff --check
```

정적 테스트는 파일 구조, 정책 불변조건, 설치 안전성을 확인한다. 실제 라우팅 품질은 별도의 새 Codex 대화에서 [수동 routing cases](evals/routing-cases.md)를 실행하고 [결과 템플릿](evals/results.template.md)에 기록해야 한다.

## 알려진 한계

- model-aware subagent 도구의 제공 여부와 반환 metadata는 Codex surface에 따라 다를 수 있다.
- 실행 도구가 실제 모델 metadata를 반환하지 않으면 `model_execution_verified: unavailable`로 보고한다.
- LLM 기반 분류이므로 정적 테스트만으로 18개 routing case의 실제 성공을 입증할 수 없다.
- implicit invocation은 비활성화되어 있으며 현재 활성화를 권장하지 않는다.
- Max와 Ultra는 이 MVP의 자동 또는 강제 route 대상이 아니다.

## 확인한 공식 문서

- [Codex Skills](https://developers.openai.com/codex/skills)
- [Codex Subagents](https://developers.openai.com/codex/multi-agent)
- [Codex Models](https://developers.openai.com/codex/models)
- [GPT-5.6 model guidance](https://developers.openai.com/api/docs/guides/latest-model)

## 라이선스

[MIT](LICENSE)
