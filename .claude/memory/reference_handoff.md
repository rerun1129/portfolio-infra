---
name: 핸드오프 파일 경로
description: 프로젝트 간 공유 쓰기 인터페이스 HAND-OFF.md의 위치 및 접근 방법
type: reference
---

## HAND-OFF 역할 (infra)

- 작업 시작 전 반드시 HAND-OFF.md를 읽고 현재 상태 파악
- `[STATUS] infra` 섹션을 항상 최신 상태로 유지
- `[REQUEST] infra → fullstack`에 fullstack에 대한 요청 등록
- `[REQUEST] → obsidian`에 기술 조사/정리 요청 등록
- 자신에게 온 `[REQUEST] fullstack → infra` 처리 후 상태 변경 → 완료 시 `[LOG]`로 이동
- REQUEST ID 형식: `infra-001`, `infra-002` ...
- 상태 lifecycle: PENDING → IN_PROGRESS → DONE / BLOCKED

## HAND-OFF.md 접근 방법

두 PC의 절대 경로를 순서대로 Read 시도. 첫 번째가 실패하면 두 번째 사용.

- 회사 PC: `D:\vive_coding\vault-rerun\rerun\.handoff\HAND-OFF.md`
- 집 PC:   `C:\저장소\vive-coding\obsidian-vault\rerun\.handoff\HAND-OFF.md`

## 쓰기 규칙

- 이 파일만 다른 프로젝트에서 수정 허용
- 다른 프로젝트의 나머지 파일은 읽기 전용

## 참여자

- **infra** (이 프로젝트): `[STATUS] infra`, `[REQUEST] infra → fullstack`
- **fullstack**: `[STATUS] fullstack`, `[REQUEST] fullstack → infra`
- **obsidian**: `[NOTES] obsidian`, `[REQUEST] → obsidian` 응답
