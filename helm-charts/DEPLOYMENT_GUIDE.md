# SGLang Kubernetes Deployment Guide

This guide provides step-by-step instructions for deploying SGLang on Kubernetes using Helm charts.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation Steps](#installation-steps)
3. [Deployment Scenarios](#deployment-scenarios)
4. [Configuration Examples](#configuration-examples)
5. [Testing and Validation](#testing-and-validation)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### 1. Kubernetes Cluster Setup

Ensure you have a Kubernetes cluster with:
- Kubernetes version 1.19+
- At least 2 nodes with GPU support
- NVIDIA GPU Operator installed
- Sufficient resources (CPU, Memory, GPU)

### 2. Required Tools

```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify Helm installation
helm version

# Install kubectl (if not already installed)
# Follow instructions at https://kubernetes.io/docs/tasks/tools/
```

### 3. GPU Support Setup

```bash
# Install NVIDIA GPU Operator
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update
helm install --wait gpu-operator nvidia/gpu-operator \
  --namespace gpu-operator \
  --create-namespace
```

### 4. LeaderWorkerSet (for LWS deployments)

```bash
# Install LeaderWorkerSet CRDs
kubectl apply --server-side -f https://github.com/kubernetes-sigs/lws/releases/download/v0.6.0/manifests.yaml

# Verify installation
kubectl get crd leaderworkersets.leaderworkerset.x-k8s.io
```

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/FarazRashid/sglang_streaming.git
cd sglang_streaming
```

### 2. Verify Helm Chart

```bash
# Lint the Helm chart
helm lint ./helm-charts/sglang

# Render templates to verify syntax
helm template test-sglang ./helm-charts/sglang --dry-run
```

### 3. Choose Your Deployment Scenario

Select one of the following deployment modes based on your requirements:

- **Single Node**: For testing or small workloads
- **Distributed**: For large models requiring multiple GPUs across nodes
- **LeaderWorkerSet**: For advanced distributed deployments with better scheduling

## Deployment Scenarios

### Scenario 1: Single Node Development

Perfect for development and testing with smaller models.

```bash
# Create namespace
kubectl create namespace sglang

# Deploy with simple configuration
helm install sglang ./helm-charts/sglang \
  --namespace sglang \
  -f ./helm-charts/sglang/examples/simple.yaml
```

**Key Features:**
- Single pod deployment
- Uses small models (DialoGPT-medium)
- ClusterIP service for internal access
- Minimal resource requirements

### Scenario 2: Single Node Production

For production workloads on a single powerful GPU node.

```bash
# Deploy with production settings
helm install sglang-prod ./helm-charts/sglang \
  --namespace sglang \
  -f ./helm-charts/sglang/examples/single-node.yaml \
  --set global.huggingface.token="YOUR_HF_TOKEN"
```

**Key Features:**
- LoadBalancer service for external access
- Health checks and monitoring
- Larger resource allocations
- Production-ready configuration

### Scenario 3: Distributed High-Performance

For large models requiring multiple GPUs across multiple nodes with RDMA networking.

```bash
# Deploy distributed setup
helm install sglang-distributed ./helm-charts/sglang \
  --namespace sglang \
  -f ./helm-charts/sglang/examples/distributed-rdma.yaml \
  --set storage.model.hostPath.path="/path/to/your/model"
```

**Key Features:**
- Multi-node deployment
- RDMA/InfiniBand support
- High-performance networking
- Suitable for 70B+ parameter models

### Scenario 4: LeaderWorkerSet Advanced

For enterprise deployments requiring advanced scheduling and fault tolerance.

```bash
# Deploy with LeaderWorkerSet
helm install sglang-lws ./helm-charts/sglang \
  --namespace sglang \
  -f ./helm-charts/sglang/examples/lws-rdma.yaml \
  --set global.model.path="/data/models/your-large-model"
```

**Key Features:**
- Advanced pod scheduling
- Built-in fault tolerance
- Leader-worker coordination
- Optimized for MoE models

## Configuration Examples

### Custom Model Configuration

```yaml
# values-custom-model.yaml
global:
  model:
    path: "your-org/your-custom-model"
    trustRemoteCode: true
  huggingface:
    token: "hf_your_token_here"
  resources:
    gpu: 2
    memory: "32Gi"

single:
  server:
    port: 8080
    enableMetrics: true
```

Deploy with:
```bash
helm install my-model ./helm-charts/sglang -f values-custom-model.yaml
```

### RDMA Optimization

```yaml
# values-rdma-optimized.yaml
deploymentMode: "distributed"

distributed:
  nodes: 4
  tensorParallelSize: 32
  nccl:
    debug: "INFO"
    ibGidIndex: "3"

rdma:
  enabled: true

security:
  privileged: true

networking:
  hostNetwork: true
  hostIPC: true

nodeSelector:
  node-type: "gpu-rdma"
```

### Resource Limits

```yaml
# values-resource-limits.yaml
global:
  resources:
    gpu: 8
    memory: "128Gi"

# Pod resource limits
resources:
  limits:
    nvidia.com/gpu: 8
    memory: 128Gi
    cpu: 32
  requests:
    nvidia.com/gpu: 8
    memory: 64Gi
    cpu: 16
```

## Testing and Validation

### 1. Deployment Status

```bash
# Check deployment status
kubectl get all -n sglang

# Check pod details
kubectl describe pod -l app.kubernetes.io/name=sglang -n sglang

# View logs
kubectl logs -f deployment/sglang -n sglang
```

### 2. Service Connectivity

```bash
# For LoadBalancer service
kubectl get svc -n sglang
export SERVICE_IP=$(kubectl get svc sglang -n sglang -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test health endpoint
curl http://$SERVICE_IP:30000/health

# For ClusterIP service (port-forward)
kubectl port-forward svc/sglang 8000:8000 -n sglang
curl http://localhost:8000/health
```

### 3. Model Inference Test

```bash
# Test model inference
curl -X POST http://$SERVICE_IP:30000/generate \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Hello, how are you?",
    "sampling_params": {
      "temperature": 0.7,
      "max_new_tokens": 100
    }
  }'
```

### 4. Metrics Monitoring

```bash
# Check metrics endpoint (if enabled)
curl http://$SERVICE_IP:8080/metrics
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Pod Stuck in Pending State

**Symptoms:**
- Pods remain in `Pending` status
- Events show scheduling issues

**Solutions:**
```bash
# Check node resources
kubectl describe nodes

# Check pod events
kubectl describe pod <pod-name> -n sglang

# Common fixes:
# - Add node selectors/tolerations
# - Reduce resource requests
# - Ensure GPU nodes are available
```

#### 2. Model Loading Failures

**Symptoms:**
- Pod starts but model fails to load
- Authentication errors for private models

**Solutions:**
```bash
# Check logs for specific errors
kubectl logs <pod-name> -n sglang

# For HuggingFace authentication:
helm upgrade sglang ./helm-charts/sglang \
  --set global.huggingface.token="your_token"

# For local models, verify path:
kubectl exec <pod-name> -n sglang -- ls -la /model-data
```

#### 3. RDMA/NCCL Issues

**Symptoms:**
- Distributed training fails to start
- NCCL communication errors

**Solutions:**
```bash
# Enable NCCL debugging
helm upgrade sglang ./helm-charts/sglang \
  --set distributed.nccl.debug="TRACE"

# Check InfiniBand devices
kubectl exec <pod-name> -n sglang -- ibstatus
kubectl exec <pod-name> -n sglang -- ibdev2netdev

# Verify RDMA capabilities
kubectl exec <pod-name> -n sglang -- rdma link show
```

#### 4. Memory Issues

**Symptoms:**
- Out of Memory (OOM) kills
- Slow model loading

**Solutions:**
```bash
# Increase shared memory
helm upgrade sglang ./helm-charts/sglang \
  --set storage.shm.size="32Gi"

# Adjust memory fraction
helm upgrade sglang ./helm-charts/sglang \
  --set lws.server.memFractionStatic="0.85"
```

### Debug Commands

```bash
# General debugging
kubectl get events -n sglang --sort-by='.lastTimestamp'
kubectl top pods -n sglang
kubectl describe networkpolicy -n sglang

# For distributed deployments
kubectl logs -f statefulset/sglang-distributed -n sglang
kubectl exec sglang-distributed-0 -n sglang -- nvidia-smi

# For LWS deployments
kubectl get leaderworkerset -n sglang
kubectl describe lws sglang-lws -n sglang
```

### Performance Monitoring

```bash
# Install monitoring tools
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack

# Monitor GPU usage
kubectl exec <pod-name> -n sglang -- nvidia-smi -l 1

# Monitor network (for RDMA)
kubectl exec <pod-name> -n sglang -- iftop -i ib0
```

## Best Practices

1. **Resource Planning**: Always plan for 2x memory overhead for model loading
2. **Node Affinity**: Use node selectors to ensure pods land on appropriate hardware
3. **Health Checks**: Enable health checks for production deployments
4. **Monitoring**: Set up comprehensive monitoring for GPU, memory, and network
5. **Security**: Use least-privilege principles and avoid privileged mode when possible
6. **Backup**: Regularly backup your model data and configurations

## Scaling and Optimization

### Horizontal Scaling

```bash
# Scale single node deployment
kubectl scale deployment sglang --replicas=3 -n sglang

# Scale distributed deployment
helm upgrade sglang ./helm-charts/sglang \
  --set distributed.nodes=4
```

### Vertical Scaling

```bash
# Increase GPU allocation
helm upgrade sglang ./helm-charts/sglang \
  --set global.resources.gpu=4 \
  --set global.resources.memory="64Gi"
```

This guide should help you successfully deploy and manage SGLang on Kubernetes. For additional support, refer to the main README and official documentation.
