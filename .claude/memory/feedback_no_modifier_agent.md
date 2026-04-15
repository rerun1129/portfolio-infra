---
name: infra-modifier 서브 에이전트 제거
description: 파일 쓰기는 Main Claude가 직접 수행, infra-modifier 서브 에이전트는 사용하지 않음
type: feedback
---

파일 수정/생성은 Main Claude가 직접 수행한다. infra-modifier 서브 에이전트는 제거됨.

**Why:** 실제 운영에서 infra-modifier가 투입되지 않았고, Main Claude가 직접 쓰기를 하는 것이 효율적이라 판단.

**How to apply:** Terraform 파일이든 문서든 쓰기 작업은 서브 에이전트 위임 없이 Main Claude가 직접 처리. 서브 에이전트는 읽기 전용(infra-explorer, infra-reviewer)과 웹서치(web-searcher)만 사용.
