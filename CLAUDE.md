# portfolio-infra Claude 운영 규칙

## 메모리

- **저장 위치:** 프로젝트 repo 내 `.claude/memory/` (예: `D:\vive_coding\portfolio-infra\.claude\memory\`)
- 시스템 기본 경로(`~/.claude/projects/.../memory/`)는 사용하지 않는다
- 작업 시작 시 `.claude/memory/` 디렉토리의 모든 파일을 읽어 프로젝트 컨텍스트를 로드하세요

## 프로젝트 개요

Terraform으로 AWS 인프라를 관리하는 프로젝트.
현재 환경: `environments/dev/`

## 핸드오프

### 파일 위치
두 PC의 절대 경로를 순서대로 Read 시도. 첫 번째가 실패하면 두 번째 사용.

- 회사 PC: `D:\vive_coding\vault-rerun\rerun\.handoff\HAND-OFF.md`
- 집 PC:   `C:\저장소\vive-coding\obsidian-vault\rerun\.handoff\HAND-OFF.md`

### 쓰기 규칙
- **HAND-OFF.md**: 읽기 + 쓰기 허용 (다른 프로젝트 파일 중 유일한 쓰기 허용)
- **다른 프로젝트의 나머지 파일**: 읽기 전용

### 작업 시작 시
1. HAND-OFF.md 읽기
2. `[STATUS] infra` 섹션 현재 상태로 업데이트
3. `[REQUEST] → infra` 섹션에 자신에게 온 요청 확인

## 서브 에이전트

### 공통 에이전트

| 에이전트 | 역할 | 사용 시점 |
|----------|------|----------|
| **Explore** (`infra-explorer`) | 코드베이스 탐색 전용 — Terraform 파일 검색, 설정값 확인. **웹서치 금지** | 구현 전 현황 파악이 필요할 때 |
| **web-searcher** | 웹서치 전담 — AWS 공식 문서, Terraform 레퍼런스 검색 | 외부 자료 조사가 필요할 때 |
| **infra-modifier** | 파일 쓰기 전용 — 승인된 계획 실행 | Main Claude가 계획 확정 후 위임 |
| **infra-reviewer** | 코드 리뷰, 보안 점검 (읽기 전용) | 중요 변경 후 2차 검증 필요 시 |

**흐름:** infra-explorer(코드 조사) + web-searcher(웹서치) 병렬 → Main Claude(계획 + 사용자 승인) → infra-modifier(실행)

### 공통 원칙
- 탐색 결과는 Main Claude가 직접 종합 — "결과 보고 판단해줘" 방식으로 위임 금지
- 코드 조사와 웹서치가 동시에 필요한 경우 두 에이전트를 병렬로 스폰
- 에이전트 결과가 사용자에게 직접 노출되지 않으므로, 중요 내용은 Main Claude가 요약해서 전달

## 현재 인프라 상태

| 리소스 | 상태 |
|--------|------|
| EC2 | down (필요 시 terraform apply) |
| RDS | down (필요 시 terraform apply) |
| CloudFront | up (prevent_destroy) |
| EIP | 없음 (필요 시 새로 발급 후 import) |
| Terraform state | S3: `todolist-dev-rerun1129/tfstate/dev/terraform.tfstate` |
