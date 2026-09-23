#!/bin/bash

set -e

PROJECT="/run/media/srinath/New Volume/Internship proj"

cd "$PROJECT"

echo "========================================"
echo " TASK MANAGER DEVOPS VERIFICATION"
echo "========================================"

echo
echo "===== JAVA / MAVEN ====="
java -version
mvn clean test

echo
echo "===== DOCKER ====="
docker --version
docker build -t task-manager:latest .
docker tag task-manager:latest task-manager-api:latest
docker build -t task-manager-frontend:latest frontend

echo
echo "===== MINIKUBE ====="
minikube start --driver=docker
minikube addons enable ingress
minikube addons enable metrics-server

MINIKUBE_IP=$(minikube ip)

echo "Minikube IP: $MINIKUBE_IP"

echo
echo "===== LOAD APPLICATION IMAGE ====="
minikube image load task-manager-api:latest
minikube image load task-manager-frontend:latest

echo
echo "===== KUBERNETES APPLICATION ====="
kubectl apply -k k8s/

echo
echo "===== ENSURE GRAFANA PASSWORD EXISTS ====="

if [ -f "$PROJECT/.env" ]; then
    set -a
    source "$PROJECT/.env"
    set +a

    kubectl patch secret task-manager-secret \
        -p "{\"data\":{\"GRAFANA_PASSWORD\":\"$(printf '%s' "$GRAFANA_PASSWORD" | base64 -w0)\"}}"
else
    echo ".env not found"
    exit 1
fi

echo
echo "===== RESTART APPLICATION WITH CURRENT IMAGE ====="
kubectl rollout restart deployment/task-manager-api
kubectl rollout status deployment/task-manager-api --timeout=180s

echo
echo "===== KUBERNETES STATUS ====="
kubectl get nodes
kubectl get pods -o wide
kubectl get svc
kubectl get ingress
kubectl get hpa

echo
echo "===== APPLICATION ====="
curl -i "http://${MINIKUBE_IP}/api/tasks"
curl -i "http://${MINIKUBE_IP}/health"
curl -I "http://${MINIKUBE_IP}/"

echo
echo "===== HELM ====="
helm lint helm/task-manager
helm template task-manager helm/task-manager > /tmp/task-manager-rendered.yaml
kubectl apply --dry-run=client -f /tmp/task-manager-rendered.yaml

echo
echo "===== KUSTOMIZE ====="
kubectl kustomize k8s/ > /tmp/task-manager-kustomize.yaml
kubectl apply --dry-run=client -k k8s/

echo
echo "===== TRIVY ====="
trivy image --timeout 10m task-manager-api:latest

echo
echo "===== TERRAFORM ====="
cd "$PROJECT/terraform"
terraform fmt
terraform init
terraform validate
cd "$PROJECT"

echo
echo "===== ANSIBLE SYNTAX ====="
ansible-playbook \
    --syntax-check \
    ansible/setup.yml \
    -i ansible/inventory.ini

echo
echo "===== MONITORING ====="
kubectl apply -f k8s/monitoring.yaml

echo
echo "===== WAIT FOR PROMETHEUS ====="
kubectl rollout status deployment/prometheus --timeout=180s

echo
echo "===== WAIT FOR GRAFANA ====="
kubectl rollout status deployment/grafana --timeout=180s

echo
echo "===== OPEN PROMETHEUS TERMINAL ====="

foot sh -c "
    echo 'PROMETHEUS'
    echo '================'
    kubectl port-forward svc/prometheus 9090:9090
" >/dev/null 2>&1 &

echo
echo "===== OPEN GRAFANA TERMINAL ====="

foot sh -c "
    echo 'GRAFANA'
    echo '=============='
    kubectl port-forward svc/grafana 3000:3000
" >/dev/null 2>&1 &

echo
echo "===== WAIT FOR PORT FORWARDS ====="

for i in {1..20}; do
    if curl -sf http://localhost:9090/-/healthy >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

for i in {1..20}; do
    if curl -sf http://localhost:3000/api/health >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

echo
echo "===== PROMETHEUS ====="
curl -s http://localhost:9090/api/v1/targets

echo
echo
echo "===== GRAFANA ====="
curl -i http://localhost:3000/api/health

echo
echo "========================================"
echo " ALL AUTOMATED CHECKS COMPLETED"
echo "========================================"
