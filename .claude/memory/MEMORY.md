# Memory Index

- [Project Overview](project_overview.md) — portfolio-infra: Terraform으로 관리하는 AWS 인프라 프로젝트
- [Project State](project_state.md) — 현재 AWS 인프라 실행 상태, 주요 리소스 정보, 남은 작업
- [User Profile](user_profile.md) — 경력, 기술 방향, 이메일
- [Cost Analysis Feedback](feedback_cost.md) — RDS 과금 역산 시 인스턴스+스토리지 분리 계산 필요
- [핸드오프 파일 경로](reference_handoff.md) — HAND-OFF.md 위치 및 프로젝트 간 쓰기 규칙
- [infra-modifier 제거](feedback_no_modifier_agent.md) — 파일 쓰기는 Main Claude가 직접 수행, modifier 에이전트 미사용
- [RDS 비밀번호 교체 대기](project_db_password_rotation.md) — ⚠️ RDS apply 전 비번 교체 필수 (qaz12345 git 히스토리 유출)
- [settings.local.json 추적 해제](project_settings_local_untracked.md) — pull 후 각 PC에서 로컬로 재생성 필요 (비번 하드코딩 금지)
