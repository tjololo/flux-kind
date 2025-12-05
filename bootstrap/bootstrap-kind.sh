cleanup() {
  echo "Removing entry from hosts file"
  sudo bash -c "sed -i '' '/kind\.418\.local/d' /etc/hosts"
  echo "Deleting kind cluster"
  kind delete cluster
  echo "Killing cloud-provider-kind with PID $1"
  kill $1 2>/dev/null
  exit 0
}
sudo -v
# Ensure current kubectl context is not pointing to any cluster
kubectl config unset current-context
export KIND_EXPERIMENTAL_PROVIDER=podman
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
EOF

kubectl config use-context kind-kind
# kubectl label node kind-control-plane node.kubernetes.io/exclude-from-external-load-balancers-
echo "Starting cloud-provider-kind"
sudo cloud-provider-kind 2>/dev/null &
CPK_PID=$!
echo "cloud-provider-kind process started with PID: $CPK_PID"
flux install

kubectl wait --for=condition=available --timeout=90s deployment -n flux-system source-controller
kubectl wait --for=condition=available --timeout=90s deployment -n flux-system kustomize-controller
kubectl wait --for=condition=available --timeout=90s deployment -n flux-system helm-controller
kubectl wait --for=condition=available --timeout=90s deployment -n flux-system notification-controller

kubectl apply -f ./base-kustomize

kubectl wait kustomizations.kustomize.toolkit.fluxcd.io -n flux-system base  --for=condition=Ready
kubectl wait helmreleases.helm.toolkit.fluxcd.io -n flux-system traefik --for=condition=Ready
kubectl wait --for=jsonpath='{.status.loadBalancer.ingress[0].ip}' -n traefik-system svc traefik

SVC_IP=$(kubectl get service -n traefik-system traefik -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
sudo sh -c 'cat <<EOF >> /etc/hosts
# Kind cluster kind.418.local
'$SVC_IP' kind.418.local
EOF'
trap "cleanup '$CPK_PID' '$SVC_IP'" EXIT INT TERM

echo "Everything should be running. Press enter to cleanup"
read fake_wait