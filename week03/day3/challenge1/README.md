# week03 > day3 > challenge1

# 0-1. cluster 생성
# ./setup-challenge-cluster.sh 
# kind create cluster --name challenge-cluster --config=kind-config.yaml


# 0-2. 시스템 배포
# ./deploy-broken-system.sh
# ns 생성
#  kubectl create namespace day3-challenge --dry-run=client -o yaml | kubectl apply -f - 
# kubectl apply -f broken-database-pvc.yaml
# kubectl apply -f broken-backend-service.yaml
# kubectl apply -f frontend-deployment.yaml
# kubectl apply -f broken-ingress.yaml
# kubectl apply -f broken-network-policy.yaml