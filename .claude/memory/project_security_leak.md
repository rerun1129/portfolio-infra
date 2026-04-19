---
name: qaz12345 유출 사건 — RDS 재기동 및 PC 셋업 주의사항
description: DB 비밀번호 git 유출 이력 및 RDS apply 전 체크리스트, 새 PC 셋업 시 settings.local.json 재생성 방법
type: project
---

**배경:** `.claude/settings.local.json`을 통해 DB 비밀번호 `qaz12345`가 커밋 히스토리 3건에 평문으로 남았음 (`4ad2e95`, `36d3bb9`, `41f0198`). 이후 `git rm --cached`로 추적 해제 및 `.gitignore` 차단 완료.

---

## RDS 재기동 시 (apply 전 필수)

현재 RDS는 down 상태라 즉시 위험은 없지만, 다음 apply로 RDS를 생성/재생성하는 순간 유출된 비번이 유효해짐. **apply 시작 전 반드시 확인:**

1. 새 비밀번호 준비 여부 (긴 랜덤 문자열 권장)
2. `terraform.tfvars`의 `db_password` 교체 완료 여부
3. `TF_VAR_db_password` 환경변수 갱신 여부
4. (권장) `aws_db_instance.main`에 `manage_master_user_password = true` 전환 — AWS Secrets Manager 자동 관리로 평문이 tfvars/state에 남지 않음
5. `.claude/settings.local.json` 내 하드코딩된 비번 제거

조치 완료 전에는 apply 실행을 **보류**하고 사용자에게 경고.

---

## 새 PC 셋업 시 (git pull 후)

`.claude/settings.local.json`은 gitignore 대상 — pull 받으면 로컬 파일이 삭제됨. pull 직후 해당 PC에서 수동 재생성:

1. `.claude/settings.local.json` 파일을 로컬에서 새로 생성
2. **비밀번호 평문 하드코딩 금지**
3. Terraform 명령 허용은 패턴 형태로만 작성:

```json
{
  "permissions": {
    "allow": [
      "Bash(terraform plan:*)",
      "Bash(terraform apply:*)",
      "Bash(terraform destroy:*)",
      "Bash(terraform init:*)",
      "Bash(terraform import:*)",
      "Bash(terraform state list)"
    ]
  }
}
```

4. DB 비번은 쉘 환경변수 `TF_VAR_db_password`로 전달 (파일에 쓰지 않음)
