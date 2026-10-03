# Project Structure

```text
task-manager/
├── .dockerignore                         # Docker build-context exclusions
├── .env                                  # Local environment variables
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                         # CI workflow
│   │   └── cd.yml                         # CD workflow
│   └── modernize/java-upgrade/            # Java modernization helper hooks
├── .gitignore                             # Git ignore rules
├── .vscode/settings.json                  # Workspace editor settings
├── Dockerfile                             # Spring Boot API image
├── docker-compose.yml                     # Local multi-service stack
├── frontend/
│   ├── Dockerfile                         # Nginx frontend image
│   ├── nginx.conf                         # Static serving and API proxy routes
│   └── public/
│       ├── app.js                          # Frontend behavior and API calls
│       ├── index.html                      # Application page
│       └── styles.css                      # Frontend styles
├── src/
│   ├── main/
│   │   ├── java/com/example/taskmanager/
│   │   │   ├── TaskManagerApplication.java # Spring Boot entry point
│   │   │   ├── controller/
│   │   │   │   ├── HealthController.java
│   │   │   │   ├── SystemStatusController.java
│   │   │   │   └── TaskController.java
│   │   │   ├── entity/Task.java
│   │   │   ├── repository/TaskRepository.java
│   │   │   └── service/TaskService.java
│   │   └── resources/application.yml       # Application configuration
│   └── test/java/com/example/taskmanager/
│       └── TaskManagerApplicationTests.java # Spring context test
├── k8s/                                   # Kubernetes manifests
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── frontend.yaml
│   ├── hpa.yaml
│   ├── ingress.yaml
│   ├── kustomization.yaml
│   ├── monitoring.yaml
│   ├── postgres.yaml
│   ├── secret.yaml
│   └── service.yaml
├── helm/task-manager/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/                          # Helm resource templates
│       ├── configmap.yaml
│       ├── deployment.yaml
│       ├── frontend.yaml
│       ├── hpa.yaml
│       ├── ingress.yaml
│       ├── secret.yaml
│       └── service.yaml
├── kustomize/
│   ├── base/kustomization.yaml
│   └── overlays/
│       ├── dev/
│       │   ├── kustomization.yaml
│       │   └── namespace.yaml
│       └── prod/
│           ├── kustomization.yaml
│           └── namespace.yaml
├── monitoring/
│   ├── prometheus.yml
│   └── grafana/
│       ├── dashboard.json
│       └── provisioning/
│           ├── dashboards/dashboard.yaml
│           └── datasources/prometheus.yaml
├── ansible/
│   ├── inventory.ini
│   └── setup.yml
├── terraform/main.tf                      # Docker infrastructure IaC
├── pom.xml                                # Maven configuration
├── README.md                              # Project documentation
├── SRE.md                                 # SRE notes and runbooks
├── start-devops.sh                        # Starts the local DevOps stack
├── stop-devops.sh                         # Stops the local DevOps stack
├── verify-devops.sh                       # Verification helper
└── structure.md                           # This file
```

Generated build output and provider caches (`target/` and `terraform/.terraform/`) are intentionally omitted.

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
