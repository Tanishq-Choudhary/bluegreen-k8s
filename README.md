# Blue-Green Deployment on Kubernetes

Two identical versions of a tiny web app run side by side (blue = v1, green = v2). A single Kubernetes Service decides which one receives live traffic. Switching versions is one selector change, and rollback is the same change in reverse.

#Change

```
          +-------------------+
 users -> | Service "web"     |  selector: slot=blue | slot=green
          +---------+---------+
                    |
        +-----------+-----------+
        v                       v
 Deployment web-blue     Deployment web-green
 (2 pods, v1)            (2 pods, v2)
```

## Prerequisites

- Docker
- minikube (or kind) and kubectl
- make, bash

## Quick start

```
minikube start
make build
make load
make deploy
make status
```

Open the app in a browser:

```
make url
```

Switch traffic and roll back:

```
make green
make blue
```

Watch live traffic during a switch (second terminal):

```
make probe
```

Clean up:

```
make clean
```

For kind use `make load CLUSTER=kind`. The browser URL step needs minikube; with kind use `make probe` to watch traffic.

## What is where

| Path | Purpose |
| --- | --- |
| `app/` | nginx app, Dockerfile, health and version endpoints |
| `k8s/` | namespace, blue and green Deployments, Service |
| `scripts/switch.sh` | safe traffic switch with health checks |
| `scripts/probe.sh` | in-cluster request loop that shows which version answers |
| `.github/workflows/ci.yaml` | build, smoke test, deploy to a throwaway cluster, switch and rollback |

## Safety behaviour

- `switch.sh` refuses to switch if the target has no ready pods.
- `make deploy` never moves live traffic; it only creates the Service if missing.
- Pods run as non-root with a read-only filesystem, dropped capabilities and resource limits.
- Rollouts use `maxUnavailable: 0` so capacity never dips during an update.
