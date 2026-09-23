# Project Structure

```text
task-manager/
├── frontend/                            # Production Nginx-served web application
│   ├── Dockerfile                        # Minimal Nginx image for the SPA
│   ├── nginx.conf                        # Static UI plus /api, /health proxy routes
│   └── public/
│       ├── index.html                    # Responsive Task Manager application shell
│       ├── styles.css                    # Monochrome, technical visual system
│       └── app.js                        # API-backed CRUD, filtering, status, and UI state
├── src/
│   ├── main/java/com/example/taskmanager/
│   │   ├── TaskManagerApplication.java   # Spring Boot entry point
│   │   ├── controller/
│   │   │   ├── TaskController.java       # Task CRUD REST endpoints
│   │   │   ├── HealthController.java     # Lightweight /health endpoint
│   │   │   └── SystemStatusController.java # API/database status for the web UI
│   │   ├── service/                      # CRUD business layer
│   │   ├── repository/                   # Spring Data JPA repository
│   │   └── entity/                       # PostgreSQL task entity
│   ├── main/resources/application.yml    # DB, Actuator, and probe configuration
│   └── test/                             # Spring context smoke test
├── Dockerfile                            # Multi-stage, non-root Spring Boot API image
├── docker-compose.yml                    # Frontend, API, PostgreSQL volume, Prometheus, Grafana
├── README.md                             # Setup, verified validation, operations, troubleshooting
├── SRE.md                                # SLI/SLO, recovery and failure scenarios
├── .dockerignore / .gitignore            # Small contexts and secret protection
├── .github/workflows/
│   ├── ci.yml                            # Test, package, build, Trivy scan
│   └── cd.yml                            # Approved GitOps-style production deployment
├── k8s/
│   ├── configmap.yaml / secret.yaml      # Database non-secret and secret settings
│   ├── postgres.yaml                     # PostgreSQL Service and `postgres-data` PVC
│   ├── deployment.yaml / service.yaml    # API workload and Service
│   ├── frontend.yaml                     # Nginx frontend workload and Service
│   ├── ingress.yaml                      # / frontend; /api and /health API routing
│   ├── hpa.yaml                          # CPU-based API autoscaling
│   └── kustomization.yaml                # Reusable Kubernetes resource bundle
├── helm/task-manager/
│   ├── Chart.yaml / values.yaml           # Chart metadata and image/replica values
│   └── templates/                        # API and frontend Deployments/Services plus supporting resources
├── kustomize/
│   ├── base/                             # Shared Kubernetes resources
│   └── overlays/dev|prod/                # Namespace and API replica differences
├── terraform/main.tf                     # Docker network, volume, and PostgreSQL demo IaC
├── ansible/setup.yml                     # Safe host directory and Compose-config setup
├── monitoring/
│   ├── prometheus.yml                    # Actuator metrics scrape configuration
│   └── grafana/
│       ├── dashboard.json                # HTTP, JVM, CPU, pod-count, and health panels
│       └── provisioning/                 # Automatic Prometheus and dashboard setup
└── verify-devops.sh                      # Optional full local/Minikube verification helper
```

## Request and persistence flow

```text
Browser → Nginx frontend → Spring Boot REST API → Service → JPA repository
                                                       ↓
                                            PostgreSQL named volume / PVC
```

Tasks are never stored in browser storage. The frontend refreshes and mutates tasks through `/api/tasks`; PostgreSQL is the source of truth. Docker Compose mounts `postgres-data`, while Kubernetes mounts the `postgres-data` PersistentVolumeClaim.

## Concept-to-code map

| Concept | Files demonstrating it |
|---|---|
| Web interface and API integration | `frontend/`, `TaskController.java`, `SystemStatusController.java` |
| REST API and durable database | `src/`, `pom.xml`, `application.yml`, `postgres.yaml` |
| Docker and Compose | `Dockerfile`, `frontend/Dockerfile`, `docker-compose.yml` |
| Kubernetes and scaling | `k8s/deployment.yaml`, `frontend.yaml`, `service.yaml`, `ingress.yaml`, `hpa.yaml` |
| Helm and Kustomize | `helm/`, `kustomize/` |
| CI/CD, GitOps, and vulnerability scan | `.github/workflows/ci.yml`, `.github/workflows/cd.yml` |
| Observability and SRE | `monitoring/`, Actuator configuration, `SRE.md` |
| IaC and configuration management | `terraform/main.tf`, `ansible/setup.yml` |
