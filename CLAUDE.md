# portfolio-infra Claude 운영 규칙

## 메모리 로드

작업 시작 시 `.claude/memory/` 디렉토리의 모든 파일을 읽어 프로젝트 컨텍스트를 로드하세요.

## 프로젝트 개요

Terraform으로 AWS 인프라를 관리하는 프로젝트.
현재 환경: `environments/dev/`

## 핸드오프

### 파일 위치
```
C:\저장소\vive-coding\obsidian-vault\rerun\.handoff\HAND-OFF.md
```
> 절대 경로 prefix는 변경될 수 있음. suffix `\rerun\.handoff\HAND-OFF.md`는 불변.

### 쓰기 규칙
- **HAND-OFF.md**: 읽기 + 쓰기 허용 (다른 프로젝트 파일 중 유일한 쓰기 허용)
- **다른 프로젝트의 나머지 파일**: 읽기 전용

### 작업 시작 시
1. HAND-OFF.md 읽기
2. `[STATUS] infra` 섹션 현재 상태로 업데이트
3. `[REQUEST] → infra` 섹션에 자신에게 온 요청 확인

## 서브 에이전트

| 에이전트 | 역할 | 도구 |
|----------|------|------|
| `infra-explorer` | 파일 탐색, 설정값 확인 (읽기 전용) | Read, Glob, Grep |
| `infra-modifier` | Terraform/문서 파일 수정 | Read, Edit, Write, Glob, Grep |
| `infra-reviewer` | 코드 리뷰, 보안 점검 (읽기 전용) | Read, Glob, Grep |

## 현재 인프라 상태

| 리소스 | 상태 |
|--------|------|
| EC2 | down (필요 시 terraform apply) |
| RDS | down (필요 시 terraform apply) |
| CloudFront | up (prevent_destroy) |
| EIP | 없음 (필요 시 새로 발급 후 import) |
| Terraform state | S3: `todolist-dev-rerun1129/tfstate/dev/terraform.tfstate` |
