# RDS (Relational Database Service)

## 개요

포트폴리오 서비스(todolist)의 PostgreSQL 데이터베이스.

## 엔드포인트

```
todolist-db.cdqpv9e2voky.ap-northeast-2.rds.amazonaws.com
```

> identifier가 동일하면 destroy/apply 반복해도 엔드포인트 변경 없음. 앱 설정 고정 가능.

## 관리 방식

**Terraform으로 관리** — 필요할 때 `apply`로 생성, 사용하지 않을 때 `destroy`로 삭제.

```bash
# 생성
cd environments/dev
export TF_VAR_db_password="패스워드"
terraform apply -target=aws_db_instance.main

# 삭제
terraform destroy -target=aws_db_instance.main -auto-approve
```

## 인스턴스 설정

| 항목 | 값 |
|------|----|
| 식별자 | todolist-db |
| 엔진 | PostgreSQL 18.3 |
| 인스턴스 클래스 | db.t3.micro (vCPU 2, RAM 1GB) |
| 스토리지 | 20 GiB, gp2, 최대 1000 GiB 자동 조정 |
| 암호화 | 활성화 (KMS: aws/rds) |
| Multi-AZ | 없음 |
| 가용 영역 | ap-northeast-2b |
| 마스터 사용자 | postgres |
| 포트 | 5432 |
| 퍼블릭 액세스 | 활성화 |

## 네트워크

| 항목 | 값 |
|------|----|
| 서브넷 그룹 | default-vpc-0b5ea269fea455d52 |
| 보안 그룹 | sg-0df35a4a18482821d |
| 파라미터 그룹 | default.postgres18 |
| 옵션 그룹 | default:postgres-18 |

## 백업 및 모니터링

| 항목 | 값 |
|------|----|
| 백업 보존 기간 | 1일 |
| 삭제 방지 | 비활성화 |
| Performance Insights | 활성화, 7일 보존 |
| 향상된 모니터링 | 비활성화 |

## 패스워드 관리

패스워드는 코드/tfvars에 저장하지 않고 환경변수로 전달:
```bash
export TF_VAR_db_password="실제패스워드"
```

## 관련 파일

- `environments/dev/main.tf` — `aws_db_instance.main` 리소스
- `environments/dev/variables.tf` — `db_password` 변수
