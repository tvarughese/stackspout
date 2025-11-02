#!/bin/sh -x

kubectl get namespace stackspout 2>/dev/null ||
  kubectl create namespace stackspout

echo "Creating / Updating gitRepository stackspout"
flux create source git stackspout \
  --url=https://open.greenhost.net/xeruf/stackspout.git \
  --branch=main \
  --interval=5m
# Don't depend on a repo hosted by this cluster
#url=https://forge.ftt.gmbh/polygon/stackspout.git \

echo "Creating / Updating kustomization stackspout"
flux create kustomization stackspout \
  --source=GitRepository/stackspout \
  --path="./infrastructure/kustomizations/" \
  --prune=true \
  --interval=5m
