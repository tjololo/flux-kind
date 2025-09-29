# Ensure current kubectl context is not pointing to any cluster
kubectl config unset current-context

cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 8080
    hostPort: 8080
    protocol: TCP
EOF

kubectl config use-context kind-kind

flux install

kubectl wait --for=condition=available --timeout=90s deployment -n flux-system source-controller
kubectl wait --for=condition=available --timeout=90s deployment -n flux-system kustomize-controller
kubectl wait --for=condition=available --timeout=90s deployment -n flux-system helm-controller
kubectl wait --for=condition=available --timeout=90s deployment -n flux-system notification-controller

kubectl apply -f ./base-kustomize