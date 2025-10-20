# 01. kind

kind create cluster --config kind-config.yaml

kubectl apply -f k8s-manifests/ns/

kubectl apply -f k8s-manifests/storage/

kubectl apply -f k8s-manifests/networking/

kubectl apply -f k8s-manifests/workloads/

