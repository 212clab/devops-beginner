#!/bin/bash

# Step 4-1: HPA (Horizontal Pod Autoscaler)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: load-generator
  namespace: day3-lab
spec:
  containers:
  - name: load-generator
    image: busybox:1.36
    command: ["/bin/sh"]
    args: ["-c", "while true; do sleep 3600; done"]
    resources:
      requests:
        cpu: 10m
        memory: 16Mi
EOF
