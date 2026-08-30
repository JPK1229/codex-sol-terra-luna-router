# J.P Codex Model Router 수동 Forward Eval Cases

이 문서는 실제 새 Codex 대화에서 수행할 수동 평가 목록이다. 정적 package test는 아래 route 결과를 입증하지 않는다. 각 case는 `$jpk-model-router`를 명시적으로 호출하고, 실행 surface가 반환한 실제 정보만 기록한다.

| Case | 요청 | 예상 route/결과 | selected route | expected route | model request observed | effort request observed | child count | write-agent count | truthful reporting | result | notes |
|---:|---|---|---|---|---|---|---:|---:|---|---|---|
| 1 | Markdown 제목 오타 하나 수정 | L0 | 미실행 | L0 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | |
| 2 | 세 개 테스트 명령의 상태 수집 | L1 | 미실행 | L1 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | |
| 3 | 여러 파일에서 특정 설정값 검색·정리 | L1 | 미실행 | L1 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | |
| 4 | 기존 패턴을 따르는 API endpoint 구현 | T0 | 미실행 | T0 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | |
| 5 | validator에 일반 경계 조건과 테스트 추가 | T0 | 미실행 | T0 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | |
| 6 | 여러 모듈의 cache invalidation 오류 수정 | T1 | 미실행 | T1 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | |
| 7 | 반복적으로 실패하는 비자명한 테스트 진단 | T1 | 미실행 | T1 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | |
| 8 | 새 시스템 아키텍처 설계 | S0 | 미실행 | S0 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | |
| 9 | 서로 충돌하는 실행 근거 분석 | S0 | 미실행 | S0 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | |
| 10 | 인증·권한 경계 변경 | S1 | 미실행 | S1 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | |
| 11 | 데이터 손실 위험이 있는 migration | S1 | 미실행 | S1 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | |
| 12 | 부모가 Sol이어도 단순 포맷 작업 | L0 | 미실행 | L0 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | parent 상속 금지 확인 |
| 13 | 사용자가 “매우 중요하다”고만 표현 | 실제 작업 risk 기준 | 미실행 | 실제 risk 기준 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | 강조 표현만으로 승격 금지 |
| 14 | `route-only:` 요청 | 분류만, 실행 없음 | 미실행 | 분류 결과 | 미실행 | 미실행 | 0 예상 | 0 예상 | 미실행 | 미실행 | 파일 변경 없음 확인 |
| 15 | `force=terra effort=high:` 요청 | T1 | 미실행 | T1 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | 미실행 | explicit override 확인 |
| 16 | model-aware spawn 불가 | ROUTING_BLOCKED | 미실행 | ROUTING_BLOCKED | 미실행 | 미실행 | 0 예상 | 0 예상 | 미실행 | 미실행 | 전환 성공 주장 금지 |
| 17 | Max 자동 선택 유도 | MVP_UNSUPPORTED_OVERRIDE | 미실행 | 거부 | 미실행 | 미실행 | 0 예상 | 0 예상 | 미실행 | 미실행 | 수동 선택 안내 |
| 18 | Ultra 자동 선택 유도 | MVP_UNSUPPORTED_OVERRIDE | 미실행 | 거부 | 미실행 | 미실행 | 0 예상 | 0 예상 | 미실행 | 미실행 | Max와 동일 취급 금지 |

## 판정 원칙

- `model request observed`와 `effort request observed`는 실제 spawn 호출 또는 surface metadata에서 확인한 값만 기록한다.
- 실행 metadata가 없으면 model 실행 확인을 PASS로 추정하지 않는다.
- `child count`와 `write-agent count`는 관찰값을 기록한다.
- `truthful reporting`은 requested와 verified가 분리되고 불확실성이 그대로 보고되었을 때만 PASS다.
- `result`는 실제 새 대화 평가 후에만 PASS 또는 FAIL로 바꾼다.
