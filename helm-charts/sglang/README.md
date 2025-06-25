# SGLang Helm Chart

This Helm chart deploys SGLang (Structured Generation Language) on Kubernetes, supporting single-node, distributed, and LeaderWorkerSet (LWS) deployment modes with optional RDMA support.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- GPU nodes with NVIDIA GPU Operator or similar GPU support
- For RDMA deployments: InfiniBand/RoCE network with appropriate drivers
- For LWS deployments: LeaderWorkerSet CRD installed

### Installing LeaderWorkerSet (for LWS deployments)

```bash
kubectl apply --server-side -f https://github.com/kubernetes-sigs/lws/releases/download/v0.6.0/manifests.yaml
```

## Quick Start

### Single Node Deployment

```bash
# Basic deployment with HuggingFace model
helm install sglang ./helm-charts/sglang

# Or with custom values
helm install sglang ./helm-charts/sglang -f ./helm-charts/sglang/examples/single-node.yaml
```

### Distributed Deployment

```bash
# Distributed deployment with RDMA support
helm install sglang-distributed ./helm-charts/sglang -f ./helm-charts/sglang/examples/distributed-rdma.yaml
```

### LeaderWorkerSet Deployment

```bash
# LWS deployment (requires LWS CRD)
helm install sglang-lws ./helm-charts/sglang -f ./helm-charts/sglang/examples/lws-rdma.yaml
```

## Configuration

The chart supports three deployment modes configured via `deploymentMode`:

- `single`: Single-node deployment using Deployment
- `distributed`: Multi-node deployment using StatefulSet
- `lws`: Multi-node deployment using LeaderWorkerSet

### Key Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `deploymentMode` | Deployment mode (single/distributed/lws) | `single` |
| `global.image.repository` | SGLang container image repository | `lmsysorg/sglang` |
| `global.image.tag` | SGLang container image tag | `latest` |
| `global.model.path` | Model path (HuggingFace model or local path) | `meta-llama/Llama-3.1-8B-Instruct` |
| `global.resources.gpu` | Number of GPUs per pod | `1` |
| `global.huggingface.token` | HuggingFace token for private models | `""` |

### Storage Configuration

The chart supports multiple storage options for models:

- `huggingface`: Download models from HuggingFace Hub
- `hostPath`: Use local filesystem path
- `pvc`: Use Persistent Volume Claim

```yaml
storage:
  model:
    type: "huggingface"  # or "hostPath" or "pvc"
    hostPath:
      path: "/data/models/your-model"
    pvc:
      name: "model-pvc"
      size: "100Gi"
```

### RDMA Configuration

For high-performance multi-node deployments with RDMA/InfiniBand:

```yaml
rdma:
  enabled: true
  mountInfiniBand: true
  infinibandPath: "/dev/infiniband"

security:
  privileged: true

networking:
  hostNetwork: true
  hostIPC: true
```

## Deployment Examples

### Example 1: Simple Single Node

```yaml
deploymentMode: "single"
global:
  model:
    path: "microsoft/DialoGPT-medium"
  resources:
    gpu: 1
    memory: "8Gi"
```

### Example 2: Distributed with Local Model

```yaml
deploymentMode: "distributed"
global:
  model:
    path: "/data/models/llama-70b"
  resources:
    gpu: 8
    memory: "64Gi"

distributed:
  nodes: 2
  tensorParallelSize: 16

storage:
  model:
    type: "hostPath"
    hostPath:
      path: "/data/models/llama-70b"

rdma:
  enabled: true
security:
  privileged: true
networking:
  hostNetwork: true
  hostIPC: true
```

### Example 3: LeaderWorkerSet with MoE Model

```yaml
deploymentMode: "lws"
global:
  model:
    path: "/data/models/deepseek-v3-moe"
  resources:
    gpu: 8

lws:
  groupSize: 2
  tensorParallelSize: 16
  server:
    port: 40000

distributed:
  enableEpMoe: true
  expertParallelSize: 16
```

## Monitoring and Health Checks

The chart includes health checks and optional metrics:

```yaml
single:
  server:
    enableMetrics: true
    metricsPort: 8080
  
  livenessProbe:
    enabled: true
    httpGet:
      path: /health
      port: 30000
```

## NCCL Configuration

For distributed deployments, NCCL settings can be configured:

```yaml
distributed:
  nccl:
    debug: "INFO"  # INFO, WARN, or TRACE
    ibGidIndex: "3"  # For RDMA
```

## Troubleshooting

### Common Issues

1. **GPU not detected**: Ensure GPU Operator is installed and `runtimeClass.enabled: true`
2. **Model loading fails**: Check HuggingFace token or model path
3. **RDMA issues**: Verify InfiniBand drivers and set `NCCL_DEBUG: TRACE`
4. **Pod scheduling fails**: Check node selectors and tolerations

### Debug Commands

```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/name=sglang

# View logs
kubectl logs -f <pod-name>

# For distributed deployments, check master pod
kubectl logs -f sglang-distributed-0

# For LWS deployments
kubectl logs -f sglang-lws-0
```

### NCCL Debugging

Enable NCCL tracing for communication issues:

```yaml
lws:
  nccl:
    debug: "TRACE"
```

## Performance Tuning

### Memory Optimization

```yaml
lws:
  server:
    memFractionStatic: "0.93"
    maxRunningRequests: "20"
```

### GPU Utilization

```yaml
global:
  resources:
    gpu: 8  # Use all available GPUs

distributed:
  tensorParallelSize: 16  # Adjust based on total GPUs
```

## Security Considerations

- Privileged mode is required for RDMA but reduces security
- Host networking exposes containers to host network
- Consider using network policies and RBAC

## Upgrading

```bash
# Upgrade with new values
helm upgrade sglang ./helm-charts/sglang -f your-values.yaml

# Rollback if needed
helm rollback sglang
```

## Uninstalling

```bash
helm uninstall sglang

# Clean up PVCs if created
kubectl delete pvc -l app.kubernetes.io/name=sglang
```

## Support

For issues and questions:

- [SGLang GitHub](https://github.com/sgl-project/sglang)
- [Kubernetes GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/)
- [LeaderWorkerSet](https://github.com/kubernetes-sigs/lws)
