

kubectl auth can-i create secrets --as=system:serviceaccount:development:developer-sa -n development

<!-- --as=system:serviceaccount:<네임스페이스>:<서비스어카운트_이름>(who) -n development (where) 
-->




kubectl auth can-i --list --as=system:serviceaccount:development:developer-sa -n development
kubectl auth can-i --list --as=system:serviceaccount:production:operator-sa -n production