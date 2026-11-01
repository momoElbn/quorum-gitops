# quorum-gitops
GitOps repo for the Quorum project. Argo CD syncs this repo into a local k3d cluster
using the app-of-apps pattern: bootstrap/root-app.yaml points at apps/.

## Rules
- Everything in the cluster comes from this repo. The only manual step is
  scripts/bootstrap.sh (create the cluster, install Argo CD, apply the root app).
- Pin every Helm chart to an exact version.
- After every change, explain what each file does in plain English.
- Don't commit; I commit.