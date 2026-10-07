NS ?= bluegreen
IMAGE ?= bluegreen-demo
CLUSTER ?= minikube

.PHONY: build load deploy status blue green probe url clean

build:
	docker build -t $(IMAGE):blue --build-arg VERSION=v1 --build-arg COLOR=blue app
	docker build -t $(IMAGE):green --build-arg VERSION=v2 --build-arg COLOR=green app

load:
ifeq ($(CLUSTER),kind)
	kind load docker-image $(IMAGE):blue $(IMAGE):green
else
	minikube image load $(IMAGE):blue
	minikube image load $(IMAGE):green
endif

deploy:
	kubectl apply -f k8s/00-namespace.yaml -f k8s/10-blue.yaml -f k8s/20-green.yaml
	kubectl -n $(NS) get svc web >/dev/null 2>&1 || kubectl apply -f k8s/30-service.yaml
	kubectl -n $(NS) rollout status deploy/web-blue --timeout=120s
	kubectl -n $(NS) rollout status deploy/web-green --timeout=120s

status:
	@bash scripts/switch.sh status
	@kubectl -n $(NS) get deploy,pods,svc -o wide

blue:
	@bash scripts/switch.sh blue

green:
	@bash scripts/switch.sh green

probe:
	@bash scripts/probe.sh

url:
	minikube service web -n $(NS) --url

clean:
	kubectl delete namespace $(NS) --ignore-not-found
