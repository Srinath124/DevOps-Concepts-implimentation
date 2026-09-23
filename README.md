# Task Manager API

A deliberately small Java 21/Spring Boot REST API that demonstrates a practical DevOps delivery path. It stores tasks in PostgreSQL and exposes Prometheus metrics.

## Architecture and delivery flow

```
Client -> Kubernetes Ingress -> Task Manager API -> PostgreSQL
             /api, /health

Developer -> GitHub -> Pull Request -> GitHub Actions -> Tests
  -> Docker Build -> Trivy Scan -> Container Image -> Kubernetes
  -> Ingress -> Task Manager API -> PostgreSQL

Task Manager API -> Actuator -> Prometheus -> Grafana

Local: Docker Compose -> API + PostgreSQL + Prometheus + Grafana
```

The full file map is in [structure.md](structure.md). Git is the source of truth for both source code and Kubernetes configuration: that GitOps principle means a reviewed Git change is the auditable desired deployment state. This project demonstrates the concept without adding an Argo CD or Flux controller.

## Technologies

| Tool | What / why / where |
|---|---|
| Spring Boot, JPA, PostgreSQL | Small REST API and durable task data; `src/`. |
| Docker / Compose | Reproducible non-root image and two-container local environment. |
| GitHub Actions + Trivy | Builds, tests, images, and scans high/critical image issues in `.github/workflows/ci.yml`. |
| Kubernetes | Runs and exposes replicas with probes, resources, ingress, and HPA in `k8s/`. |
| Helm / Kustomize | Parameterized chart and small dev/prod deployment differences. |
| Terraform / Ansible | Demonstrate local Docker infrastructure and safe host inspection. |
| Prometheus / Grafana | Scrape metrics and visualize request/JVM health. |

## API

`GET /api/tasks`, `GET /api/tasks/{id}`, `POST /api/tasks`, `PUT /api/tasks/{id}`, `DELETE /api/tasks/{id}`, and `GET /health`.

Actuator endpoints: `GET /actuator/health` and `GET /actuator/prometheus`.

Example: `curl -X POST localhost:8080/api/tasks -H 'Content-Type: application/json' -d '{"title":"Study Docker","description":"Build image","completed":false}'`

## Local development

Requires Java 21 and Maven. Configure no source-code secrets: environment variables are `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`, and `DB_PASSWORD`.

```bash
export DB_HOST=localhost DB_PORT=5432 DB_NAME=taskmanager DB_USERNAME=taskuser DB_PASSWORD=taskpass
mvn spring-boot:run
```

## Useful Linux and shell commands

```bash
pwd && ls                         # locate and inspect the project
cd /path/to/task-manager
java -version && mvn -version     # verify the Java/Maven toolchain
grep -R "DB_HOST" .              # find configuration references
ps aux | grep java                # inspect a running local application
ss -ltnp | grep -E '8080|9090|3000' # inspect local listening ports
curl -i http://localhost:8080/health
docker ps && docker compose ps
docker compose logs -f task-manager-api
```

For the complete local stack (API, PostgreSQL, Prometheus at `:9090`, and Grafana at `:3000`), set local passwords first. Docker Compose deliberately refuses to start until both are provided:

```bash
export DB_PASSWORD='choose-a-local-password'
export GRAFANA_PASSWORD='choose-a-grafana-password'
docker compose up --build -d
curl localhost:8080/health
docker compose logs -f task-manager-api
docker compose down
```

`Dockerfile` uses a build stage and a non-root `spring` user. Never commit `.env`; it is ignored. The CI job does not push an image. Add a registry login/push step later only with GitHub Secrets.

## CI/CD, GitOps, and container security

`ci.yml` checks out the code, sets up Java 21, runs Maven tests and packaging, builds the image, then runs Trivy for high/critical vulnerabilities. It needs no private credentials.

`cd.yml` is the GitOps-style delivery workflow. Once CI succeeds on `main`, it checks out that exact reviewed commit and applies `kustomize/overlays/prod`. The Git repository is therefore the deployment configuration source of truth. GitHub's protected `production` Environment provides an approval point before cluster changes. CD reads `KUBECONFIG_DATA` only from a GitHub Actions secret; it is never committed. Configure it as a base64-encoded kubeconfig before enabling production deployment:

```bash
base64 -w 0 ~/.kube/config
```

Add that output as the repository or Environment secret named `KUBECONFIG_DATA`. Ensure `k8s/deployment.yaml` references an image your production cluster can pull before merging. For local Minikube, keep using the documented local deployment commands instead of the hosted CD workflow.

The multi-stage Docker image, non-root runtime user, `.dockerignore`, Git-ignored local secrets, and Trivy scan provide appropriately small security controls for this project.

## Git workflow

Create a branch, make focused commits, open a pull request, let CI pass, review, then merge:

```bash
git switch -c feature/task-endpoint
git add . && git commit -m "Add task endpoint"
git push -u origin feature/task-endpoint
```

The expected path is `feature branch -> commit -> pull request -> GitHub Actions -> review -> merge`. Treat the Kubernetes, Helm, and Kustomize files as GitOps configuration: reviewed changes in the repository declare the intended cluster configuration.

## Kubernetes (Minikube)

Minikube is the primary path. Start its ingress add-on, build the image in Minikube’s Docker daemon, then apply the manifests. The secret has a safe placeholder: change it locally before production; do not commit a real password.

```bash
minikube start
minikube addons enable ingress
eval $(minikube docker-env)
docker build -t task-manager-api:latest .
kubectl create namespace task-manager-dev
kubectl apply -n task-manager-dev -f k8s/
kubectl get pods,svc,ingress,hpa -n task-manager-dev
kubectl scale deployment/task-manager-api -n task-manager-dev --replicas=3
kubectl get hpa -n task-manager-dev
kubectl get pods -n task-manager-dev
```

The Deployment starts two replicas; readiness and liveness use Spring Boot health probes. CPU requests allow the HPA to scale from 2 to 5 when Metrics Server is available. The Service selects every matching ready replica, distributing traffic between them. Ingress routes `/api` and `/health`. `k8s/postgres.yaml` is a small PVC-backed PostgreSQL demo dependency; replace it with a managed, backed-up database for production.

Helm renders the API with image, replica count, port, resources, and autoscaling values:

```bash
helm lint helm/task-manager
helm upgrade --install task-manager helm/task-manager -n task-manager-dev --create-namespace
```

Kustomize uses the same base; dev sets one API replica and prod three:

```bash
kubectl apply -k kustomize/overlays/dev
kubectl apply -k kustomize/overlays/prod
```

## Infrastructure and configuration management

Terraform in `terraform/main.tf` manages a Docker network, persistent volume, and PostgreSQL demo container—only local Docker infrastructure. Supply its password outside Git, then run `terraform init`, `terraform validate`, and review `terraform plan`; apply only when you intend to create it.

```bash
export TF_VAR_postgres_password='choose-a-local-password'
terraform -chdir=terraform init
terraform -chdir=terraform validate
terraform -chdir=terraform plan
```

Ansible in `ansible/setup.yml` provides a safe, limited deployment-host setup. Define an inventory and inspect its planned changes first:

```bash
ansible-playbook -i inventory.ini ansible/setup.yml --check
```

Terraform provisions infrastructure resources (the local Docker network, volume, and PostgreSQL container). Ansible configures a prepared host: it verifies Docker, creates `/opt/task-manager`, and copies the Compose and monitoring configuration. It does not install software or start containers; run it only against a host you intentionally place in `inventory.ini`.

## Monitoring, logging, and SRE

Actuator exposes `/actuator/prometheus`, including HTTP request and JVM metrics; `/actuator/health` provides health. Prometheus scrapes the Compose service using `monitoring/prometheus.yml`. Grafana is automatically provisioned with Prometheus and the dashboard, which shows request rate, request count, p95 latency, error rate, and JVM memory.

## Logging

Spring Boot writes clear application logs to standard output. Use `docker compose logs -f task-manager-api` locally or `kubectl logs deployment/task-manager-api -n task-manager-dev` in Kubernetes. Startup errors reveal configuration problems; connection-refused or authentication errors point to PostgreSQL settings; request error logs help diagnose failed API calls. No centralized log stack is needed for this demonstration.

Example SLI: percentage of successful HTTP requests and request latency. Example SLO: 99% successful requests per month and 95% under 500 ms. The error budget is the allowed 1% failure rate; consuming it too quickly signals that changes should pause while reliability is improved.

## Troubleshooting

```bash
docker ps
docker compose ps
kubectl get pods -n task-manager-dev
kubectl describe pod POD_NAME -n task-manager-dev
kubectl logs POD_NAME -n task-manager-dev
kubectl get svc,ingress -n task-manager-dev
kubectl get events -n task-manager-dev --sort-by=.lastTimestamp
kubectl get endpoints -n task-manager-dev
```

| Problem | Inspect | Likely cause and fix |
|---|---|---|
| `CrashLoopBackOff` | `kubectl describe pod POD`, `kubectl logs POD` | Bad startup configuration or a missing database. Correct the ConfigMap/Secret and redeploy. |
| `ImagePullBackOff` | `kubectl describe pod POD` | Incorrect image/tag or unavailable registry. Check the image reference, or build it with `eval $(minikube docker-env)`. |
| Readiness probe failure | `kubectl logs POD`; `curl /actuator/health/readiness` from a port-forward | The API is not ready, often because PostgreSQL is unavailable. Check `DB_*` values and `kubectl get pods` for PostgreSQL. |
| Service not reachable | `kubectl get svc,ingress,endpoints`; `kubectl describe ingress task-manager-api` | Selector, target port, endpoint, or ingress-controller issue. Verify labels, port `80 -> 8080`, and enable the Minikube ingress add-on. |
| Database connection failure | `kubectl logs deployment/task-manager-api`; `kubectl logs deployment/postgres` | Invalid credentials, missing Service, or an unready database. Check `task-manager-secret`, `postgres` Service, and PVC status. |

## Validation

Run `mvn test`, `mvn package`, `docker build -t task-manager-api:local .`, `docker compose config`, `kubectl apply --dry-run=client -f k8s/`, `helm lint helm/task-manager`, `kubectl kustomize kustomize/overlays/dev`, `terraform init -backend=false && terraform validate`, and `ansible-playbook --syntax-check ansible/setup.yml`.
