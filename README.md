# Janus gateway docker

## Introduction

This is a docker image for Janus Webrtc Gateway. About the details of setup for this docker image, you should read the
official docs https://janus.conf.meetecho.com/index.html carefully. 

## How to use

### Build and run docker image

```shell
make build
make run
```

### Use docker image from registry

```shell
docker run --network host --name janus -d ghcr.io/bigphuc/janus-gateway-docker:latest
```