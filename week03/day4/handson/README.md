
# 2-2:  External Secrets Operator 적용
# cluster secret manager

brew install helm

helm repo update
helm repo add external-secrets https://charts.external-secrets.io

# external-secrets-system 만들며 설정
helm upgrade --install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets-system \
  --create-namespace \
  --set installCRDs=true

 # 우리 클러스터에 외부 로봇들을 고용하는 작업
 # (DB 접속정보, 외부서비스 API키, 메시지큐, TLS 인증서 등 거의 모든 통신에서 필요한)
 # ESO 설치 > secretStore 설정 >  ExternalSecret 설정

  - configMap 공개해도 되는 일반 설정 보관함(key:value)-pt(plain text)

  - kind: SecretStore - ESO가 어떻게 externalStore에 접근해서 secret을 가져올지 "설명서"; 특정 ns만 적용; cf. ClusterSecretStore  ns전역

  - kind: ExternalSecret - secret을 가져와서 어떻게 해 "설명서"; 

# 아래가 ESO를 구성하는 한팀
  - external-secrets- : 팀장이자 실제 배달부 / external-secrets-webhook- : 문지기 / external-secrets-cert-controller- : 보안 담당자

# 법과 법집행 
# ConstraintTemplate > Constraint



