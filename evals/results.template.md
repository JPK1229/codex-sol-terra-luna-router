# J.P Codex Model Router Forward Eval 결과 템플릿

```text
overall_status: NOT_RUN
surface: NOT_RUN
codex_version: NOT_RUN
date: NOT_RUN
evaluator: NOT_RUN
```

실제 새 Codex 대화에서 각 case를 수행한 뒤 관찰값을 기록한다. 이 템플릿의 초기 상태는 모두 `NOT_RUN`이며 정적 테스트 결과로 변경하지 않는다.

| Case | selected route | expected route | model request observed | effort request observed | child count | write-agent count | truthful reporting | result | notes |
|---:|---|---|---|---|---:|---:|---|---|---|
| 1 | NOT_RUN | L0 | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | |
| 2 | NOT_RUN | L1 | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | |
| 3 | NOT_RUN | L1 | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | |
| 4 | NOT_RUN | T0 | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | |
| 5 | NOT_RUN | T0 | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | |
| 6 | NOT_RUN | T1 | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | |
| 7 | NOT_RUN | T1 | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | |
| 8 | NOT_RUN | S0 | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | |
| 9 | NOT_RUN | S0 | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | |
| 10 | NOT_RUN | S1 | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | |
| 11 | NOT_RUN | S1 | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | |
| 12 | NOT_RUN | L0 | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | |
| 13 | NOT_RUN | actual-risk route | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | |
| 14 | NOT_RUN | route-only | NOT_RUN | NOT_RUN | 0 expected | 0 expected | NOT_RUN | NOT_RUN | |
| 15 | NOT_RUN | T1 | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | NOT_RUN | |
| 16 | NOT_RUN | ROUTING_BLOCKED | NOT_RUN | NOT_RUN | 0 expected | 0 expected | NOT_RUN | NOT_RUN | |
| 17 | NOT_RUN | MVP_UNSUPPORTED_OVERRIDE | NOT_RUN | NOT_RUN | 0 expected | 0 expected | NOT_RUN | NOT_RUN | |
| 18 | NOT_RUN | MVP_UNSUPPORTED_OVERRIDE | NOT_RUN | NOT_RUN | 0 expected | 0 expected | NOT_RUN | NOT_RUN | |

## 실행별 증거

각 case에 대해 다음만 추가한다.

```text
case:
request:
route_report:
spawn_evidence:
changed_files:
validation:
remaining_risks:
```
