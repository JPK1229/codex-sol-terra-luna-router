# J.P Codex Model Router 작업 계획

## 원칙

- 비어 있는 현재 저장소를 프로젝트 루트로 사용한다.
- 요청된 파일만 만들고 런타임 의존성을 추가하지 않는다.
- 각 Phase는 해당 검증이 끝난 뒤 다음 단계로 넘어간다.
- 정적 테스트 결과를 실제 routing 품질 PASS로 표현하지 않는다.

## Phase별 작업과 검증

### Phase 0. 환경 및 기준 확인

변경: 작업 경로, 기존 파일, Git 상태, 도구 버전, 상위 작업 지침, 공식 OpenAI 사양을 확인한다.

검증: 저장소가 비어 있고 로컬 Git만 존재하는지, remote가 없는지, 필요한 Python과 Bash가 동작하는지 확인한다.

### Phase 1. 문서와 골격

변경: `README.md`, `LICENSE`, 기능 명세와 작업 계획을 작성한다.

검증: 목표, 비범위, 두 파일 런타임, 공식 사양 해석이 문서에 명시되었는지 검토한다.

### Phase 2. Skill 구현

변경: `skill/jpk-model-router/SKILL.md`와 `agents/openai.yaml`을 작성한다.

검증: front matter, 명시적 호출, route 표, single-writer, recursion 방지, fallback, requested/verified 구분을 검사한다.

### Phase 3. 설치와 제거

변경: 외부 다운로드 없는 `install.sh`, `uninstall.sh`를 작성한다.

검증: dry-run, 최초 설치, idempotence, 충돌 중단, force, 안전한 제거를 임시 경로에서 확인한다.

### Phase 4. 테스트와 평가 자료

변경: 표준 라이브러리 package test, shell installer test, 18개 수동 case, 결과 템플릿, GitHub Actions를 작성한다.

검증:

```bash
python3 tests/test_package.py
bash tests/test_install.sh
git diff --check
```

### Phase 5. 사용자 범위 설치

변경: 모든 로컬 테스트가 통과한 뒤 사용자 Skill 경로에 두 런타임 파일을 설치한다.

검증: 먼저 dry-run을 실행하고 충돌이 없을 때만 실제 설치한다.

### Phase 6. 설치 확인

변경: 없음.

검증: 설치 파일 목록, Skill 이름, implicit invocation 정책, 소스와 설치본 SHA-256을 비교한다.

### Phase 7. 최종 보고

구현 파일, 테스트의 실제 결과, 설치 경로와 해시, forward eval 수행 여부, 알려진 한계, 수동 smoke test, 최종 Git 상태를 보고한다.

## 중단 조건

- 기존 대상 Skill 내용이 다르면 사용자 설치만 중단하고 소스와 테스트 결과는 보존한다.
- 명시적 model-aware subagent 실행을 검증할 수 없으면 라우팅 작업을 성공으로 표현하지 않는다.
- 한 번의 동일 자식 수정 요청 후에도 검증이 실패하면 해당 실행을 실패로 보고한다.
