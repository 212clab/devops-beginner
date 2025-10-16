<!-- 
0.권한
 -->

kubectl auth can-i create secrets --as=system:serviceaccount:development:developer-sa -n development

<!-- --as=system:serviceaccount:<네임스페이스>:<서비스어카운트_이름>(who) -n development (where) 
-->

kubectl auth can-i --list --as=system:serviceaccount:development:developer-sa -n development
kubectl auth can-i --list --as=system:serviceaccount:production:operator-sa -n production


<!-- 
1.네트워크
 -->
1-1. 기본단위는 pod - unique IP(ephemeral단명)
containers can connect each other in a same pod
1-2. pod - pod: 직접 통신 가능 (w/o NAT) 
pods can connect each other between any nodes(CNI)
cf. service(unique ClusterIP, DNS): loadBalancer

1-3(*). ns 는 networkPolicy를 설치하기에 아주 찰떡 구조
1-4(*). 그 외 label들로도 묶어 사용(ex. tier)