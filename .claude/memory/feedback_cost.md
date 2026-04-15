---
name: Cost Analysis Feedback
description: 비용 분석 시 주의할 점 — RDS 역산 오류 경험
type: feedback
---

RDS 과금을 역산할 때 인스턴스 시간만 계산하지 말고 스토리지 prorated 비용도 함께 계산할 것.

**Why:** RDS $0.18을 10시간으로 역산했으나 실제는 3시간. 인스턴스($0.084) + 스토리지 prorated($0.09) 합산이었음.

**How to apply:** RDS 과금 역산 시 항상 "인스턴스 시간 + 스토리지 일할계산" 두 항목으로 분리해서 계산.
