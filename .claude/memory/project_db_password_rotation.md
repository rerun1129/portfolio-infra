---
name: RDS 비밀번호 교체 대기 (apply 전 필수)
description: RDS를 다시 올리기 전에 DB 비밀번호를 반드시 교체해야 함 — 기존 qaz12345는 git 히스토리에 유출됨
type: project
---

**RDS를 다시 `terraform apply`로 올리기 전에 DB 비밀번호를 반드시 교체할 것.**

**Why:** 기존 비밀번호 `qaz12345`가 `.claude/settings.local.json`을 통해 git 커밋 히스토리 3건에 평문으로 남았음 (`4ad2e95`, `36d3bb9`, `41f0198`). 현재 RDS는 down 상태라 즉시 위험은 없지만, 다음 apply로 RDS를 생성/재생성하는 순간 유출된 비번이 유효해짐.

**How to apply:** RDS 기동 관련 apply 요청이 들어오면 작업 시작 전 사용자에게 다음을 확인:

1. 새 비밀번호 준비 여부 (긴 랜덤 문자열 권장)
2. `terraform.tfvars`의 `db_password` 교체 완료 여부
3. `TF_VAR_db_password` 환경변수 갱신 여부
4. (권장) `aws_db_instance.main`에 `manage_master_user_password = true` 전환 검토 — AWS Secrets Manager 자동 관리로 평문이 tfvars/state에 남지 않음
5. `.claude/settings.local.json`의 하드코딩된 비번 제거 (이미 gitignore 처리됨, 그러나 파일 내용 자체 정리 필요)
6. 애플리케이션(fullstack)이 DB 연결 중이라면 HAND-OFF로 새 비번 전달 요청

조치 완료 전에는 apply 실행을 **보류**하고 사용자에게 경고.
