# SGLang Helm Chart Makefile
# Provides convenient commands for managing SGLang deployments

.PHONY: help lint template install upgrade uninstall test-single test-distributed test-lws

# Default target
help:
	@echo "SGLang Helm Chart Management"
	@echo "============================"
	@echo ""
	@echo "Available commands:"
	@echo "  lint              - Lint the Helm chart"
	@echo "  template          - Render chart templates"
	@echo "  install-single    - Install single-node deployment"
	@echo "  install-dist      - Install distributed deployment"
	@echo "  install-lws       - Install LeaderWorkerSet deployment"
	@echo "  upgrade           - Upgrade existing deployment"
	@echo "  uninstall         - Uninstall deployment"
	@echo "  test-single       - Test single-node deployment"
	@echo "  test-distributed  - Test distributed deployment"
	@echo "  test-lws          - Test LWS deployment"
	@echo "  status            - Show deployment status"
	@echo "  logs              - Show pod logs"
	@echo "  clean             - Clean up all resources"

# Variables
CHART_PATH = ./helm-charts/sglang
NAMESPACE = sglang
RELEASE_NAME = sglang

# Lint the Helm chart
lint:
	@echo "Linting Helm chart..."
	helm lint $(CHART_PATH)

# Render templates for verification
template:
	@echo "Rendering chart templates..."
	helm template test-sglang $(CHART_PATH) --dry-run

# Create namespace if it doesn't exist
create-namespace:
	@kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -

# Install single-node deployment
install-single: create-namespace
	@echo "Installing single-node SGLang deployment..."
	helm install $(RELEASE_NAME) $(CHART_PATH) \
		--namespace $(NAMESPACE) \
		-f $(CHART_PATH)/examples/single-node.yaml

# Install distributed deployment
install-dist: create-namespace
	@echo "Installing distributed SGLang deployment..."
	helm install $(RELEASE_NAME)-distributed $(CHART_PATH) \
		--namespace $(NAMESPACE) \
		-f $(CHART_PATH)/examples/distributed-rdma.yaml

# Install LeaderWorkerSet deployment
install-lws: create-namespace
	@echo "Installing LeaderWorkerSet SGLang deployment..."
	@echo "Note: Ensure LeaderWorkerSet CRD is installed"
	helm install $(RELEASE_NAME)-lws $(CHART_PATH) \
		--namespace $(NAMESPACE) \
		-f $(CHART_PATH)/examples/lws-rdma.yaml

# Install simple test deployment
install-simple: create-namespace
	@echo "Installing simple test deployment..."
	helm install $(RELEASE_NAME)-simple $(CHART_PATH) \
		--namespace $(NAMESPACE) \
		-f $(CHART_PATH)/examples/simple.yaml

# Upgrade deployment
upgrade:
	@echo "Upgrading SGLang deployment..."
	helm upgrade $(RELEASE_NAME) $(CHART_PATH) \
		--namespace $(NAMESPACE)

# Uninstall deployment
uninstall:
	@echo "Uninstalling SGLang deployment..."
	-helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE)
	-helm uninstall $(RELEASE_NAME)-distributed --namespace $(NAMESPACE)
	-helm uninstall $(RELEASE_NAME)-lws --namespace $(NAMESPACE)
	-helm uninstall $(RELEASE_NAME)-simple --namespace $(NAMESPACE)

# Show deployment status
status:
	@echo "Deployment Status:"
	@echo "=================="
	@kubectl get all -n $(NAMESPACE)
	@echo ""
	@echo "Helm Releases:"
	@echo "=============="
	@helm list -n $(NAMESPACE)

# Show pod logs
logs:
	@echo "Fetching pod logs..."
	@kubectl logs -l app.kubernetes.io/name=sglang -n $(NAMESPACE) --tail=100

# Test single-node deployment
test-single:
	@echo "Testing single-node deployment..."
	@kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=sglang -n $(NAMESPACE) --timeout=300s
	@kubectl port-forward svc/$(RELEASE_NAME) 8000:30000 -n $(NAMESPACE) &
	@sleep 5
	@curl -f http://localhost:8000/health || echo "Health check failed"
	@pkill -f "kubectl port-forward" || true

# Test distributed deployment
test-distributed:
	@echo "Testing distributed deployment..."
	@kubectl wait --for=condition=ready pod -l component=distributed -n $(NAMESPACE) --timeout=600s
	@kubectl get pods -l component=distributed -n $(NAMESPACE)

# Test LWS deployment
test-lws:
	@echo "Testing LWS deployment..."
	@kubectl wait --for=condition=ready pod -l role=leader -n $(NAMESPACE) --timeout=600s
	@kubectl get leaderworkerset -n $(NAMESPACE)

# Clean up all resources
clean: uninstall
	@echo "Cleaning up resources..."
	@kubectl delete namespace $(NAMESPACE) --ignore-not-found=true

# Install prerequisites
install-prerequisites:
	@echo "Installing prerequisites..."
	@echo "1. Installing NVIDIA GPU Operator..."
	helm repo add nvidia https://helm.ngc.nvidia.com/nvidia || true
	helm repo update
	-helm install gpu-operator nvidia/gpu-operator \
		--namespace gpu-operator \
		--create-namespace \
		--wait
	@echo "2. Installing LeaderWorkerSet CRDs..."
	kubectl apply --server-side -f https://github.com/kubernetes-sigs/lws/releases/download/v0.6.0/manifests.yaml || true

# Validate cluster readiness
validate-cluster:
	@echo "Validating cluster readiness..."
	@echo "Checking GPU nodes..."
	@kubectl get nodes -l nvidia.com/gpu.present=true
	@echo "Checking GPU Operator..."
	@kubectl get pods -n gpu-operator
	@echo "Checking LeaderWorkerSet CRDs..."
	@kubectl get crd leaderworkersets.leaderworkerset.x-k8s.io || echo "LWS CRD not found"

# Monitor deployment
monitor:
	@echo "Monitoring SGLang deployment..."
	@watch kubectl get pods,svc -n $(NAMESPACE)

# Debug deployment issues
debug:
	@echo "Debugging deployment..."
	@echo "Pod status:"
	@kubectl get pods -n $(NAMESPACE) -o wide
	@echo ""
	@echo "Recent events:"
	@kubectl get events -n $(NAMESPACE) --sort-by='.lastTimestamp' | tail -20
	@echo ""
	@echo "Pod logs (last 50 lines):"
	@kubectl logs -l app.kubernetes.io/name=sglang -n $(NAMESPACE) --tail=50

# Show resource usage
resources:
	@echo "Resource usage:"
	@kubectl top nodes
	@echo ""
	@kubectl top pods -n $(NAMESPACE)

# Complete installation workflow
install-complete: install-prerequisites validate-cluster install-single test-single
	@echo "Complete SGLang installation finished!"
	@echo "Access your deployment at: kubectl port-forward svc/$(RELEASE_NAME) 8000:30000 -n $(NAMESPACE)"

# Development workflow
dev: lint template install-simple
	@echo "Development deployment ready!"
