# Build Image for Streaming with CUDA 12.8.1

Run the following commands to build and run the Docker image for streaming with CUDA 12.8.1:

```bash 
docker build --build-arg CUDA_VERSION=12.8.1 --build-arg BUILD_TYPE=all -t sglang:cuda128 -f docker/Dockerfile .
docker run -it --rm --gpus all sglang:cuda128```