# 🚀 DHTAJO: 클라우드 네이티브 무중단 배포 및 인프라 자동화 구축

기존 수동 기반의 가상 서버(AMI) 환경에서 구동되던 레거시 웹 애플리케이션을 클라우드 네이티브 아키텍처로 마이그레이션하고, 인적 개입이 배제된(Zero-Touch) 완전 자동화 파이프라인을 구축한 프로젝트입니다.

---

## 🛠 Tech Stack
- **Compute & Network:** AWS EC2 Auto Scaling, Application Load Balancer, VPC (Public/Private Subnets, NAT Gateway)
- **CI/CD & Security:** GitHub Actions, AWS IAM (OIDC integration)
- **Containerization:** Docker, Amazon ECR
- **Runtime:** Java 17, Tomcat 10

---

## 📐 System Architecture
![Architecture Diagram](./images/architecture.png)

### Architecture Core Principles
1. **논리적 네트워크 격리 (3-Tier):** 컴퓨팅 리소스(EC2)는 퍼블릭 IP를 전면 배제하여 프라이빗 서브넷에 격리하고, 인터넷 인바운드는 오직 ALB를 통해서만 허용하여 공격 표면(Attack Surface)을 최소화했습니다.
2. **체인형 보안 그룹 구조:** 웹 서버의 8080 포트 소스를 ALB의 보안 그룹 ID로 타겟 매핑하여 내부망 우회 공격 및 수평 이동(Lateral Movement) 위협을 원천 차단했습니다.

---

## ✨ Key Engineering Points

### 🔒 1. AWS OIDC 연동을 통한 Keyless 자격 증명 통제
정적 Access Key 노출 위험을 원천 배제하기 위해 GitHub Actions와 AWS STS 간 OIDC 신뢰 관계를 형성했습니다. 특정 리포지토리 컨텍스트(`repo:stanisiu/aws-web-project:*`) 조건절을 강제하여 1시간 유효의 임시 토큰 기반 최소 권한 통제를 확립했습니다.

### 🔄 2. ASG Instance Refresh 기반 무중단 롤링 배포
신규 버전 배포 시 `start-instance-refresh` API를 트리거하여 구버전과 신버전을 안정적으로 점진 교체합니다. ALB의 하트비트 상태 검사(Health Check)를 완벽히 통과하여 `Healthy` 사인을 획득한 인스턴스에만 트래픽을 이관하며, 구버전 인스턴스는 커넥션 드레닝(Connection Draining)을 거쳐 안전하게 퇴역(Terminate)함으로써 다운타임 제로(Zero-downtime) 환경을 실현했습니다.

---

## 📊 Performance & Metrics (마이그레이션 성과)

| 평가 지표 (Metrics) | 마이그레이션 전 (AS-IS) | 마이그레이션 후 (TO-BE) | 개선 효과 |
| :--- | :--- | :--- | :--- |
| **코드 배포 리드 타임** | 약 15~20분 | **단 36초** | **96% 시간 단축** |
| **인프라 프로비저닝** | 100% 수동 세팅 | **0% (Zero Touch)** | 운영 오버헤드 제거 |
| **배포 시 다운타임** | 1~3분 순단 발생 | **0초 (무중단)** | 가용성 극대화 |
| **보안 자격 증명** | 정적 Access Key 유지 | **단기 임시 세션 (OIDC)** | 크레덴셜 탈취 리스크 제로 |

---

## 🛠 Troubleshooting Experience
- **IAM 역할 할당 지연 (Propagation Delay) 해결:** 인스턴스 초기 부팅 직후 발생할 수 있는 AWS 내부 권한 전파 지연 문제를 해결하기 위해, 셸 부트스트랩 스크립트 내에 최대 5회 재시도 및 5초 대기 백오프(Sleep) 로직을 구현하여 내결함성(Fault Tolerance)을 확보했습니다.
- **도커 데몬 생명주기 동기화:** 엔진 설치 직후 발생하는 소켓 비활성화 타이밍 이슈를 `until docker info` 구문을 도입하여 동기화했습니다.
