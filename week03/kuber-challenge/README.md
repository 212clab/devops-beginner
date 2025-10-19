# 📁 GitHub Repository 구조
필수 디렉토리 구조

kubernetes-challenge/
└── week3/
    └── day3/
        ├── README.md                           # 프로젝트 개요
        ├── k8s-manifests/                      # Kubernetes 매니페스트
        │   ├── namespaces/
        │   │   ├── frontend-ns.yaml
        │   │   ├── backend-ns.yaml
        │   │   └── data-ns.yaml
        │   ├── networking/
        │   │   ├── frontend-service.yaml
        │   │   ├── api-services.yaml
        │   │   ├── database-services.yaml
        │   │   └── ingress.yaml
        │   ├── storage/
        │   │   ├── storage-classes.yaml
        │   │   ├── postgres-pvc.yaml
        │   │   ├── mongodb-pvc.yaml
        │   │   └── logs-pvc.yaml
        │   └── workloads/
        │       ├── frontend-deployment.yaml
        │       ├── api-deployments.yaml
        │       └── database-statefulsets.yaml
        ├── docs/                               # 분석 문서
        │   ├── network-storage-analysis.md    # 네트워크 & 스토리지 분석
        │   └── screenshots/                   # 시각화 캡처
        │       ├── network-topology.png
        │       ├── service-mesh.png
        │       └── storage-usage.png
        └── scripts/                           # 배포/관리 스크립트
            ├── deploy-networking.sh           # 네트워킹 설정
            ├── deploy-storage.sh              # 스토리지 설정
            └── test-connectivity.sh           # 연결 테스트

            
# 📊 시각화 도구 활용
🛠️ 권장 시각화 도구
Kubernetes Dashboard: 서비스 메시 토폴로지
K9s: 실시간 네트워크 연결 상태
kubectl tree: Service와 Endpoint 관계
Grafana: 네트워크 성능 메트릭
📸 필수 캡처 항목
네트워크 토폴로지: 전체 서비스 연결 구조
서비스 메시: Pod 간 통신 흐름
스토리지 사용량: PV/PVC 할당 현황
Ingress 라우팅: 외부 트래픽 분산 현황
