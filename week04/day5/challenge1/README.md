1. kind 클러스터 생성
2. 클러스터의 기본적인 "실시간 건강 상태"를 측정하는 도구 셋팅

- 각 노트와 파드가 현재 cpu, memory를 얼마나 사용하고 있는지- 이 서버가 있어야 kubectl top nodes, pods 등을 동작시킬수 있음

3. prometheus

- 클러스터의 거의 모든 상태 데이터를 주기적으로 수집하고 저장하는 정밀 모니터링 시스템

4. kubecost (ns-kubecost)

- prometheus 9090 에서 데이터를 끌어와서

./setup-cluster.sh
kubecost로만 모니터링, latest 아닌 전 버전으로(grafana 제외)
