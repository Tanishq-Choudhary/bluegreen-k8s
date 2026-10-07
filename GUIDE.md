# Presentation, Screenshots and Viva Guide

Project: Blue-Green Deployment of a Web Application using Kubernetes

## Part 1: Screenshots to take while you work

Take these in order as you run the project. Each one becomes a slide or backup evidence.

| # | When | What to capture | Command |
| --- | --- | --- | --- |
| 1 | Project folder | File tree showing app, k8s, scripts, workflow | `ls -R` or your editor sidebar |
| 2 | After build | Both images listed | `docker images bluegreen-demo` |
| 3 | After deploy | Pods for blue and green all Running | `kubectl -n bluegreen get pods` |
| 4 | Before switch | Service selector pointing to blue, browser showing blue page | `make status` and `make url` |
| 5 | After switch | Browser showing green page | `make green` |
| 6 | During switch | Probe output flipping from blue v1 to green v2 with no FAIL lines | `make probe` |
| 7 | After rollback | Back to blue | `make blue` |
| 8 | Failure test | Switch refused when target is unhealthy (see demo extra below) | `bash scripts/switch.sh green` |
| 9 | GitHub | Green tick on the Actions run, with the steps expanded | Actions tab |
| 10 | Architecture | The diagram from README or a draw.io version | any |

Tip: take every screenshot at full window size with the command visible above the output. Use a light terminal theme so it prints well on slides.

## Part 2: The 6 slides

Keep each slide to a title, 3 bullets at most, and one screenshot or diagram. Spoken time is about 50 seconds per slide.

**Slide 1: Title**
- Project name, your name, class, date
- One line: "Deploying new versions with zero downtime and instant rollback"

**Slide 2: Problem and idea**
- Traditional deployments stop or degrade the app while updating
- Blue-green runs two full copies; only one serves users
- Switch traffic in one step, roll back in one step
- Visual: two boxes (blue, green) with an arrow from users to blue

**Slide 3: Architecture**
- Screenshot or diagram: Service in front, blue and green Deployments behind it
- The Service selector is the "switch"
- Tools: Docker, Kubernetes (minikube), GitHub Actions
- Visual: README diagram

**Slide 4: Implementation**
- Docker image per version (blue v1, green v2)
- Two Deployments with health probes and resource limits
- switch.sh checks the target is healthy before moving traffic
- Visual: screenshots 2 and 3

**Slide 5: Results**
- Screenshots 4 and 5 side by side: blue page, then green page
- Screenshot 6: request log flips with no failures
- Rollback shown in screenshot 7
- This is where you do the live demo if time allows

**Slide 6: CI/CD, lessons and conclusion**
- Pipeline builds, tests, deploys to a temporary cluster, and tests the switch
- Lessons: cost of running two copies, database changes need care, health checks are what make the switch safe
- Takeaway: a deployment becomes a routine, reversible action
- Visual: screenshot 9 (green Actions run)

## Part 3: Five-minute talk plan

| Time | Slide | What you say |
| --- | --- | --- |
| 0:00 | 1 | Introduce the project in one sentence |
| 0:30 | 2 | Why downtime during deployment is a problem |
| 1:15 | 3 | Walk the diagram left to right |
| 2:00 | 4 | Mention probes and the safety check, no code reading |
| 2:30 | 5 | Live demo (below) |
| 4:15 | 6 | Pipeline, lessons, finish |

## Part 4: Live demo script (2 minutes)

Before you present: cluster running, `make deploy` done, `make url` URL open in a browser tab, a second terminal ready for `make probe`. Do a full dry run once.

1. Show the browser: blue page. Run `make status` to show `live: blue`.
2. Start `make probe` in the second terminal. Lines scroll: `blue v1`.
3. Run `make green` in the first terminal.
4. Point at the probe output: it flips to `green v2`. Say "no failed requests".
5. Refresh the browser: green page.
6. Run `make blue`. Everything flips back. Say "that is the rollback".

Optional extra if you have time (shows the safety check):

```
kubectl -n bluegreen scale deploy/web-green --replicas=0
make green
```

It refuses to switch. Restore with `kubectl -n bluegreen scale deploy/web-green --replicas=2`.

If the demo breaks, play your screenshots on slide 5. That is why you took them.

## Part 5: Viva questions and short answers

**What is blue-green deployment?**
Two identical environments run at once. Users go to one (live) while the other (idle) holds the new version. You switch traffic to the new one and keep the old one for instant rollback.

**How does the switch work in Kubernetes?**
A Service sends traffic to pods whose labels match its selector. Changing the selector from `slot=blue` to `slot=green` redirects all new connections.

**Why is there no downtime?**
The green pods are fully running and passing readiness checks before the selector changes. The change itself is a single update.

**How is rollback done?**
Change the selector back. The old version is still running, so it is instant.

**Blue-green vs rolling update vs canary?**
Rolling replaces pods gradually, so two versions serve at once and rollback is slower. Canary sends a small percentage of traffic to the new version first. Blue-green flips everything at once but needs double capacity.

**What are the drawbacks?**
Double resource cost while both run, and database schema changes must be compatible with both versions.

**How do you handle the database?**
Make schema changes backward compatible (add columns first, remove old ones later) so both versions work against the same database.

**What are readiness and liveness probes?**
Readiness decides whether a pod receives traffic. Liveness decides whether a pod should be restarted. Here both call the `/healthz` endpoint.

**What happens to in-flight requests during the switch?**
Existing connections finish on the old pods. A short `preStop` sleep gives pods time to drain before shutdown.

**What security measures did you apply?**
Non-root user, read-only root filesystem, all Linux capabilities dropped, no service account token mounted, resource limits, and a restricted namespace policy.

**What does the CI pipeline do?**
Lints the scripts, builds both images, smoke tests a container, creates a temporary Kubernetes cluster, deploys, performs the switch and rollback, and fails if anything is wrong.

**Why use a Service selector instead of an Ingress?**
It is the simplest mechanism and needs no extra components. In production you could switch at an Ingress or a service mesh for finer control.

**How would this scale to production?**
Use a container registry instead of local images, an Ingress or load balancer, autoscaling per Deployment, monitoring (Prometheus/Grafana), and automated switching after tests pass. Argo Rollouts can automate blue-green.

**What would you improve?**
Add automated health verification with metrics before switching, a registry push step in the pipeline, and a monitoring dashboard.

**What did you learn?**
Deployment strategy is separate from the application code, and health checks are what make automated switching safe.

## Part 6: Troubleshooting

| Symptom | Fix |
| --- | --- |
| Pods stuck in `ErrImagePull` or `ImagePullBackOff` | Run `make load` after `make build` so the cluster has the images |
| `make url` hangs or shows nothing | Leave that terminal open; it is a tunnel. Open the printed URL in the browser |
| Browser still shows the old colour | Hard refresh (Ctrl+Shift+R). The app sends no-cache headers, so a plain refresh also works |
| `make probe` says pod already exists | Re-run; the script deletes the old probe pod first |
| Windows | Use WSL2 with Docker Desktop for the commands above |
