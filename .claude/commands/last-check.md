---
description: 원격 푸시 전 최종 점검 — 변경된 Terraform/문서 파일 재검토 + 시스템 수준 메모리를 프로젝트 수준으로 이관
---

## 1. 변경 파일 내용 재검토

`git status` 는 **검토 대상을 추리는 용도**로만 사용합니다. 리뷰 자체는 git이 아니라 파일 내용에 대한 최종 검수입니다.

### 검토 대상 추리기

- `M (Modified)` / `?? (Untracked)` / `D (Deleted)` 로 감지된 파일을 모두 목록화합니다
- 다음 파일을 우선 검토 대상으로 분류합니다:
  - `environments/**/*.tf`, `modules/**/*.tf` (Terraform 정의)
  - `environments/**/terraform.tfvars.example`, `environments/**/variables.tf`
  - `docs/aws-services/*.md` (AWS 서비스 문서)
  - `COMMANDS.md`, `BOILERPLATE.md`, `POST-APPLY-CHECKLIST.md` (운영 가이드)
  - `CLAUDE.md`, `.claude/` (Claude 운영 규칙)
- `terraform.tfvars`, `.terraform/`, `*.tfstate*`, `*.tfplan`, `connection-info/`, `accesskey/` 가 스테이징에 올라왔다면 **즉시 중단하고 경고** (민감 정보 — `.gitignore`에 존재)
- **`git diff` 전체를 stdout으로 출력하지 않습니다.** `git status --short` + `git diff --stat`으로 범위와 변경량만 파악한 뒤, 의심스럽거나 변경량이 큰 파일, 운영 규칙 파일만 Read 툴로 선별 확인합니다. 사용자가 명시적으로 "전체 diff 보여줘"라고 하지 않는 한 전체 출력 금지.

### 내용 검토 체크리스트

변경된 파일을 읽어 아래 기준으로 검수합니다. 중요도 큰 변경은 `infra-reviewer` 서브 에이전트에 위임해 2차 검증 권장.

**Terraform 파일 (`*.tf`)**
- 리소스 명명 컨벤션: `${var.project_name}-<용도>` / 리소스명 `.main` suffix (`aws_instance.main`)
- 하드코딩 대신 `var.<name>` 사용
- 민감 변수는 `sensitive = true`, 값은 환경변수(`TF_VAR_*`)로 전달되도록 구성
- Security Group: 불필요한 `0.0.0.0/0` 개방 없는지
- `prevent_destroy`, `deletion_protection`, `skip_final_snapshot` 설정 의도가 명확한지
- `default_tags` (Project/Environment/ManagedBy) 적용 여부

**AWS 서비스 문서 (`docs/aws-services/*.md`)**
- 새로 추가/변경된 Terraform 리소스가 해당 서비스 문서에 반영되어 있는지
- 리소스명, 변수명이 실제 `.tf`와 일치하는지

**운영 가이드 (`COMMANDS.md`, `BOILERPLATE.md`, `POST-APPLY-CHECKLIST.md`)**
- 명령어 내 리소스명/경로가 현재 `.tf` 상태와 일치하는지
- `terraform.tfvars.example`의 변수 목록이 `variables.tf`와 동기화되어 있는지

**운영 규칙 (`CLAUDE.md`, `.claude/`)**
- 규칙 변경이 의도된 것인지, 서브 에이전트 정의·메모리 인덱스와 충돌하지 않는지
- `.claude/settings.local.json`이 스테이징에 포함되지 않았는지 (민감 정보, `.gitignore`)

### 보고 형식

```
## 변경 파일 검토 결과

### 조치 필요
- [파일경로] — 이슈 내용 + 권장 조치 (심각도: 높음/중간/낮음)

### 확인 완료
- 변경 파일 N건, 특이사항 없음
```

## 2. 메모리 이관 점검

이 프로젝트의 메모리는 `.claude/memory/` 에 저장되어야 합니다 (`CLAUDE.md` 참조).
Claude가 기본 경로인 시스템 수준(`~/.claude/projects/<encoded>/memory/`)에 실수로 저장한 파일이 있는지 주기적으로 확인합니다.

### 점검 절차

1. 시스템 수준 메모리 디렉토리 탐색 (glob으로 인코딩 이름 매칭):
   - `~/.claude/projects/*portfolio-infra*/memory/` (Windows: `%USERPROFILE%\.claude\projects\*portfolio-infra*\memory\`)
   - `MEMORY.md` 및 개별 메모리 파일 목록화
2. 프로젝트 수준 메모리 디렉토리와 비교:
   - 경로: `<repo>/.claude/memory/` (프로젝트 루트 기준 상대 경로 사용)
3. **이관 대상** 판별:
   - 시스템 수준에만 존재 → 이관 필요
   - 양쪽 존재하고 내용 다름 → 사용자 확인 후 병합 또는 최신본으로 덮어쓰기
   - 양쪽 동일 → 시스템 수준 파일 삭제 (중복 제거)

### 이관 실행

사용자 승인 후:

1. 시스템 수준 파일을 프로젝트 수준으로 복사/병합
2. 프로젝트 수준 `MEMORY.md` 인덱스에 신규 엔트리 추가
3. 시스템 수준 원본 파일 삭제 (중복 방지)

## 3. 최종 요약

```
## last-check 완료

- 변경 파일 검토: N건 (조치 필요 N건, 확인 완료 N건)
- 메모리 이관: N개 이관, N개 중복 제거
- 다음 액션: (커밋/푸시 권고 또는 추가 조치 필요 사항)
```
