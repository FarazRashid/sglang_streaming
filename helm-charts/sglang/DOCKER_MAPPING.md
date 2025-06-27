# SGLang Helm Chart - Docker Command Mapping

This document explains how the SGLang Helm chart has been configured to match your Docker command.

## Docker Command Mapping

Your original Docker command:
```bash
sudo docker run --gpus all -p 30000:30000 \
  -d \
  --name sglang_container \
  --network sg_network \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  -v $(pwd)/Avery_0.2_3_16:/model \
  -v $(pwd)/torch_cache:/root/inductor_root_cache \
  --env "HF_TOKEN=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" \
  --env "PYTORCH_FORCE_FLOAT32=1" \
  --env "TORCHINDUCTOR_CACHE_DIR=/root/inductor_root_cache" \
  lmsysorg/sglang:latest \
  python3 -m sglang.launch_server \
    --model-path /model \
    --tokenizer-path /model \
    --tokenizer-mode auto \
    --attention-backend flashinfer \
    --enable-torch-compile \
    --cuda-graph-max-bs 16 \
    --stream-interval 4 \
    --enable-tokenizer-batch-encode \
    --host 0.0.0.0 \
    --port 30000
```

## Helm Chart Configuration

### Environment Variables
The following environment variables are now automatically set:
- `HF_TOKEN`: From `global.huggingface.token`
- `PYTORCH_FORCE_FLOAT32=1`: Automatically set
- `TORCHINDUCTOR_CACHE_DIR=/root/inductor_root_cache`: Automatically set

### Volume Mounts
Three volumes are configured:
1. **HuggingFace Cache**: `~/.cache/huggingface` → `/root/.cache/huggingface`
2. **Model Data**: `$(pwd)/Avery_0.2_3_16` → `/model`
3. **Torch Cache**: `$(pwd)/torch_cache` → `/root/inductor_root_cache`

### Server Arguments
All server arguments from your Docker command are supported:
- `--model-path /model`
- `--tokenizer-path /model`
- `--tokenizer-mode auto`
- `--attention-backend flashinfer`
- `--enable-torch-compile`
- `--cuda-graph-max-bs 16`
- `--stream-interval 4`
- `--enable-tokenizer-batch-encode`
- `--host 0.0.0.0`
- `--port 30000`

## Deployment Steps

1. **Update the paths in values file**: Edit `values-docker-example.yaml` and replace the placeholder paths with actual absolute paths on your Kubernetes nodes:
   ```yaml
   storage:
     model:
       hostPath:
         path: "/absolute/path/to/your/Avery_0.2_3_16"  # Replace this
     torchCache:
       hostPath:
         path: "/absolute/path/to/your/torch_cache"     # Replace this
   ```

2. **Deploy the chart**:
   ```bash
   helm install sglang ./helm-charts/sglang -f values-docker-example.yaml
   ```

3. **Access the service**: The service will be available on port 30000 via LoadBalancer.

## Important Notes

- **GPU Support**: Ensure your Kubernetes cluster has GPU nodes with the NVIDIA device plugin installed
- **Node Selector**: Update the `nodeSelector` in the values file to match your GPU node labels
- **Paths**: The hostPath volumes require that the model and cache directories exist on the Kubernetes nodes where the pods will be scheduled
- **Security**: The configuration runs as root user (uid 0) to match the Docker behavior

## Differences from Docker

1. **Networking**: Instead of a custom Docker network, the pod uses Kubernetes networking
2. **Volume Management**: Uses Kubernetes hostPath volumes instead of Docker bind mounts
3. **GPU Access**: Uses Kubernetes GPU resource allocation instead of `--gpus all`
4. **Process Management**: Kubernetes handles container lifecycle instead of Docker daemon

## Customization

You can customize the deployment by modifying values in `values.yaml` or creating your own values file:

- Change GPU count: `global.resources.gpu`
- Modify memory allocation: `global.resources.memory`
- Adjust server parameters: `single.server.*`
- Configure storage: `storage.*`
- Set up networking: `networking.*`
