---
name: settings.local.json 추적 해제 (PC별 로컬 관리)
description: .claude/settings.local.json은 git 추적 해제됨 — pull 후 각 PC에서 로컬로 재생성 필요
type: project
---

`.claude/settings.local.json`은 git에서 추적 해제되었고 `.gitignore`로 차단됨.

**Why:** 과거 커밋에 DB 비밀번호(`qaz12345`)가 평문으로 유출된 이력(`4ad2e95`, `36d3bb9`, `41f0198`)이 있어, 추가 노출을 차단하기 위해 `git rm --cached`로 추적 해제.

**How to apply:**

다른 PC(예: 회사 PC)에서 이 커밋을 `git pull` 받으면 로컬의 `settings.local.json`이 **삭제됨**. pull 직후 해당 PC에서 다음을 수행:

1. `.claude/settings.local.json` 파일을 로컬에서 새로 생성
2. **비밀번호 평문 하드코딩 금지** — 이번 유출의 근본 원인
3. Terraform 명령 허용은 값 하드코딩 없이 패턴 형태로 작성:

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
5. 이 파일은 gitignore 대상이므로 commit/push 되지 않음 — PC마다 독립적으로 유지
