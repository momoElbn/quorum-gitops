#!/usr/bin/env bash
# Bootstraps the local Quorum cluster: k3d cluster + Argo CD + root app.
# Everything else in the cluster is then synced by Argo CD from this repo.
set -euo pipefail

CLUSTER_NAME="quorum"
ARGOCD_MANIFEST="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
ROOT_APP="$(cd "$(dirname "$0")/.." && pwd)/bootstrap/root-app.yaml"

if k3d cluster list "$CLUSTER_NAME" >/dev/null 2>&1; then
  echo "==> k3d cluster '$CLUSTER_NAME' already exists, reusing it"
else
  echo "==> Creating k3d cluster '$CLUSTER_NAME' with 2 agents"
  k3d cluster create "$CLUSTER_NAME" --agents 2
fi

kubectl config use-context "k3d-$CLUSTER_NAME" >/dev/null

echo "==> Installing Argo CD (stable)"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
# Server-side apply: Argo CD's CRDs are too large for client-side apply annotations.
kubectl apply -n argocd --server-side --force-conflicts -f "$ARGOCD_MANIFEST"

echo "==> Waiting for Argo CD to be ready"
kubectl wait --for=condition=Available deployment --all -n argocd --timeout=300s
kubectl rollout status statefulset/argocd-application-controller -n argocd --timeout=300s

echo "==> Applying root app"
kubectl apply -n argocd -f "$ROOT_APP"

echo
echo "==> Argo CD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
echo
