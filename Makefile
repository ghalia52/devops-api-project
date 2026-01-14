.PHONY: help install test coverage security build run docker-run docker-stop \
        docker-compose-up docker-compose-down push k8s-deploy k8s-status \
        k8s-logs k8s-delete clean all monitoring-up monitoring-down \
        k8s-deploy-monitoring k8s-delete-monitoring

# Variables
DOCKER_IMAGE := ghaliaba1/devops-api
DOCKER_TAG := latest
K8S_NAMESPACE := default
PYTHON := python3
PIP := pip3

# Default target
.DEFAULT_GOAL := help

## help: Show this help message
help:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  DevOps API Project - Available Commands"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "🔧 Development:"
	@echo "  make install              Install Python dependencies"
	@echo "  make run                  Run application locally"
	@echo "  make clean                Clean temporary files"
	@echo ""
	@echo "🧪 Testing & Security:"
	@echo "  make test                 Run unit tests"
	@echo "  make coverage             Run tests with coverage report"
	@echo "  make security             Run all security scans"
	@echo ""
	@echo "🐳 Docker:"
	@echo "  make build                Build Docker image"
	@echo "  make docker-run           Run app in Docker container"
	@echo "  make docker-stop          Stop Docker container"
	@echo "  make docker-compose-up    Start with Docker Compose"
	@echo "  make docker-compose-down  Stop Docker Compose"
	@echo "  make push                 Push image to DockerHub"
	@echo ""
	@echo "📊 Monitoring (Docker Compose):"
	@echo "  make monitoring-up        Start app + Prometheus + Grafana"
	@echo "  make monitoring-down      Stop monitoring stack"
	@echo ""
	@echo "☸️  Kubernetes:"
	@echo "  make k8s-deploy           Deploy app to Kubernetes"
	@echo "  make k8s-deploy-monitoring Deploy Prometheus + Grafana to K8s"
	@echo "  make k8s-status           Check deployment status"
	@echo "  make k8s-logs             View pod logs"
	@echo "  make k8s-delete           Delete K8s app resources"
	@echo "  make k8s-delete-monitoring Delete monitoring resources"
	@echo ""
	@echo "⚡ Quick Commands:"
	@echo "  make all                  Run full CI/CD locally"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

## install: Install Python dependencies
install:
	@echo "📦 Installing dependencies..."
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt
	@echo "✅ Dependencies installed successfully"

## test: Run unit tests
test:
	@echo "🧪 Running unit tests..."
	pytest tests/ -v
	@echo "✅ All tests passed"

## coverage: Run tests with coverage report
coverage:
	@echo "📊 Running tests with coverage..."
	pytest tests/ --cov=src --cov-report=term --cov-report=html
	@echo ""
	@echo "✅ Coverage report generated:"
	@echo "   - Terminal: See above"
	@echo "   - HTML: Open htmlcov/index.html"

## security: Run all security scans
security:
	@echo "🔒 Running security scans..."
	@echo ""
	@echo "🔍 Running Bandit (SAST)..."
	@bandit -r src/ -f screen || true
	@echo ""
	@echo "🔍 Running Trivy (Dependency Scan)..."
	@trivy fs . --severity HIGH,CRITICAL || true
	@echo ""
	@echo "✅ Security scans complete"

## build: Build Docker image
build:
	@echo "🐳 Building Docker image..."
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	@echo "✅ Image built: $(DOCKER_IMAGE):$(DOCKER_TAG)"

## run: Run application locally
run:
	@echo "🚀 Starting application..."
	@echo "📍 Access at: http://localhost:5000"
	@echo "Press Ctrl+C to stop"
	$(PYTHON) src/app.py

## docker-run: Run application in Docker container
docker-run:
	@echo "🐳 Starting Docker container..."
	docker run -d \
		-p 5000:5000 \
		--name devops-api \
		--health-cmd="python -c 'import urllib.request; urllib.request.urlopen(\"http://localhost:5000/health\")'" \
		--health-interval=30s \
		$(DOCKER_IMAGE):$(DOCKER_TAG)
	@echo "✅ Container started: devops-api"
	@echo "📍 Access at: http://localhost:5000"
	@echo "🔍 Check health: docker inspect devops-api | grep -A 10 Health"

## docker-stop: Stop and remove Docker container
docker-stop:
	@echo "🛑 Stopping Docker container..."
	@docker stop devops-api 2>/dev/null || true
	@docker rm devops-api 2>/dev/null || true
	@echo "✅ Container stopped and removed"

## docker-compose-up: Start services with Docker Compose
docker-compose-up:
	@echo "🐳 Starting Docker Compose services..."
	docker-compose up -d
	@echo "✅ Services started"
	@echo "📍 Access at: http://localhost:5000"
	@echo "📋 View logs: docker-compose logs -f"

## docker-compose-down: Stop Docker Compose services
docker-compose-down:
	@echo "🛑 Stopping Docker Compose services..."
	docker-compose down
	@echo "✅ Services stopped"

## monitoring-up: Start monitoring stack (App + Prometheus + Grafana)
monitoring-up:
	@echo "📊 Starting monitoring stack..."
	@mkdir -p monitoring/grafana/datasources monitoring/grafana/dashboards monitoring/grafana/dashboard-files
	@echo "Creating configuration files..."
	@echo 'global:\n  scrape_interval: 15s\nscrape_configs:\n  - job_name: "devops-api"\n    static_configs:\n      - targets: ["app:5000"]\n    metrics_path: "/metrics"' > monitoring/prometheus.yml
	@echo 'apiVersion: 1\ndatasources:\n  - name: Prometheus\n    type: prometheus\n    access: proxy\n    url: http://prometheus:9090\n    isDefault: true' > monitoring/grafana/datasources/datasources.yaml
	@echo 'apiVersion: 1\nproviders:\n  - name: "Default"\n    orgId: 1\n    folder: ""\n    type: file\n    options:\n      path: /var/lib/grafana/dashboards' > monitoring/grafana/dashboards/dashboards.yaml
	docker-compose -f docker-compose-monitoring.yaml up -d
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "✅ Monitoring stack started successfully!"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "🎯 Access URLs:"
	@echo "   📱 Application:  http://localhost:5000"
	@echo "   📈 Prometheus:   http://localhost:9090"
	@echo "   📊 Grafana:      http://localhost:3000"
	@echo ""
	@echo "🔑 Grafana Login:"
	@echo "   Username: admin"
	@echo "   Password: admin"
	@echo ""
	@echo "📋 View logs: docker-compose -f docker-compose-monitoring.yaml logs -f"
	@echo ""

## monitoring-down: Stop monitoring stack
monitoring-down:
	@echo "🛑 Stopping monitoring stack..."
	docker-compose -f docker-compose-monitoring.yaml down
	@echo "✅ Monitoring stack stopped"

## push: Push Docker image to DockerHub
push:
	@echo "📤 Pushing image to DockerHub..."
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)
	@echo "✅ Image pushed successfully"
	@echo "🔗 View at: https://hub.docker.com/r/$(DOCKER_IMAGE)"

## k8s-deploy: Deploy app to Kubernetes
k8s-deploy:
	@echo "☸️  Deploying app to Kubernetes..."
	kubectl apply -f k8s/deployment.yaml
	kubectl apply -f k8s/service.yaml
	@echo "✅ Deployed to namespace: $(K8S_NAMESPACE)"
	@echo "⏳ Waiting for pods to be ready..."
	@kubectl wait --for=condition=ready pod -l app=devops-api --timeout=60s || true

## k8s-deploy-monitoring: Deploy Prometheus and Grafana to Kubernetes
k8s-deploy-monitoring:
	@echo "📊 Deploying monitoring stack to Kubernetes..."
	kubectl apply -f k8s/prometheus-deployment.yaml
	kubectl apply -f k8s/grafana-deployment.yaml
	@echo "✅ Monitoring stack deployed"
	@echo "⏳ Waiting for pods to be ready..."
	@kubectl wait --for=condition=ready pod -l app=prometheus --timeout=90s || true
	@kubectl wait --for=condition=ready pod -l app=grafana --timeout=90s || true
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "✅ Monitoring deployed successfully!"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "📋 Get access URLs:"
	@echo "   For Minikube: minikube service grafana-service"
	@echo "   Or run: kubectl get svc"
	@echo ""

## k8s-status: Check Kubernetes deployment status
k8s-status:
	@echo "☸️  Kubernetes Status:"
	@echo ""
	@echo "📦 Deployments:"
	@kubectl get deployments -n $(K8S_NAMESPACE)
	@echo ""
	@echo "🐳 Pods:"
	@kubectl get pods -n $(K8S_NAMESPACE)
	@echo ""
	@echo "🌐 Services:"
	@kubectl get services -n $(K8S_NAMESPACE)

## k8s-logs: View Kubernetes pod logs
k8s-logs:
	@echo "📋 Pod logs (last 50 lines):"
	@kubectl logs -l app=devops-api -n $(K8S_NAMESPACE) --tail=50

## k8s-delete: Delete app Kubernetes resources
k8s-delete:
	@echo "🗑️  Deleting app Kubernetes resources..."
	@kubectl delete -f k8s/service.yaml 2>/dev/null || true
	@kubectl delete -f k8s/deployment.yaml 2>/dev/null || true
	@echo "✅ App resources deleted"

## k8s-delete-monitoring: Delete monitoring Kubernetes resources
k8s-delete-monitoring:
	@echo "🗑️  Deleting monitoring Kubernetes resources..."
	@kubectl delete -f k8s/grafana-deployment.yaml 2>/dev/null || true
	@kubectl delete -f k8s/prometheus-deployment.yaml 2>/dev/null || true
	@echo "✅ Monitoring resources deleted"

## clean: Clean up temporary files and caches
clean:
	@echo "🧹 Cleaning up..."
	@find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name '*.pyc' -delete 2>/dev/null || true
	@find . -type d -name '*.egg-info' -exec rm -rf {} + 2>/dev/null || true
	@rm -rf htmlcov/ .coverage .pytest_cache/ 2>/dev/null || true
	@rm -rf build/ dist/ 2>/dev/null || true
	@rm -rf monitoring/ 2>/dev/null || true
	@echo "✅ Cleanup complete"

## all: Run complete CI/CD pipeline locally
all: clean install test coverage security build
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "✅  Full CI/CD Pipeline Complete!"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "Next steps:"
	@echo "  • Run with monitoring:  make monitoring-up"
	@echo "  • Deploy to K8s:        make k8s-deploy && make k8s-deploy-monitoring"
	@echo "  • Push to registry:     make push"
	@echo ""