# EC2 (Elastic Compute Cloud)

## 개요

포트폴리오 서비스(todolist)의 애플리케이션 서버.

## 관리 방식

**Terraform으로 관리** — EIP는 영구 보유(`prevent_destroy = true`), EC2만 필요 시 올리고 내림.

```bash
# EC2 생성 (EIP association 포함)
terraform apply -target=aws_instance.main -target=aws_eip_association.main -auto-approve

# EC2 삭제 (EIP는 유지)
terraform destroy -target=aws_eip_association.main -target=aws_instance.main -auto-approve
```

## 인스턴스 설정

| 항목 | 값 |
|------|----|
| 인스턴스 ID | destroy/apply 시 변경됨 (`terraform state show aws_instance.main`로 확인) |
| 인스턴스 유형 | t3.micro (vCPU 2, RAM 1GB) |
| AMI | ami-0ada8527e6dc686a3 (Amazon Linux 2023) |
| 키 페어 | todolist-ec2-key |
| 태그 Name | todolist-server |
| 모니터링 | 비활성화 |
| 크레딧 사양 | unlimited |
| IAM 역할 | 없음 |

## 스토리지

| 항목 | 값 |
|------|----|
| 디바이스 | /dev/xvda |
| 크기 | 8 GiB |
| 유형 | EBS |
| 암호화 | 없음 |

## 네트워크

| 항목 | 값 |
|------|----|
| VPC | vpc-0b5ea269fea455d52 |
| 퍼블릭 IP (고정) | 52.78.180.13 (Elastic IP) |
| EIP 할당 ID | eipalloc-07f9265f13b05f6a9 |

## 보안 그룹 (todolist-ec2-sg)

| 방향 | 포트 | 프로토콜 | 허용 대상 |
|------|------|---------|----------|
| 인바운드 | 22 | TCP | 211.201.200.41/32 (SSH 허용 IP) |
| 인바운드 | 8080 | TCP | 0.0.0.0/0 |
| 아웃바운드 | 전체 | 전체 | 0.0.0.0/0 |

> SSH 허용 IP가 변경된 경우 `main.tf`의 보안 그룹 ingress 22 규칙을 업데이트 후 `terraform apply`.

## 관련 파일

- `environments/dev/main.tf` — `aws_instance.main`, `aws_security_group.ec2`, `aws_eip.main`, `aws_eip_association.main`
