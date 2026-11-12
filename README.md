# rhdh-templates

Software Templates, Helm charts, and demo applications for [Red Hat Developer Hub](https://developers.redhat.com/rhdh) demonstrations.

## Layout

| Path | Purpose |
|------|---------|
| `templates/` | RHDH Software Templates (`template.yaml` + skeleton) |
| `charts/` | Helm charts used by templates / GitOps |
| `apps/` | Application sources (reference content for demos) |
| `locations.yaml` | Single catalog entry point for RHDH |

## Register templates in RHDH

Point Developer Hub at `locations.yaml` so every template in this repo is discovered:

```yaml
catalog:
  locations:
    - type: url
      target: https://github.com/slallemand/rhdh-templates/blob/main/locations.yaml
      rules:
        - allow: [Template, Location]
```

When you add a new template under `templates/<name>/template.yaml`, also append it to `spec.targets` in [`locations.yaml`](locations.yaml).

## Template: Deploy Demo Landing (Helm + GitOps)

[`templates/demo-landing`](templates/demo-landing) scaffolds a visual nginx landing page and deploys it with OpenShift GitOps.

**Flow**

1. Renders a Helm chart + `catalog-info.yaml`
2. Creates a repository on a **self-hosted GitLab** (host is a template parameter)
3. Registers the component in the RHDH catalog
4. Creates an Argo CD Application via `argocd:create-resources`

There is **no CI build**: the chart serves static HTML from a ConfigMap using `nginxinc/nginx-unprivileged`.

### Default parameters

| Parameter | Default | Notes |
|-----------|---------|-------|
| `name` | `demo-landing` | Repo, Argo app, and entity name |
| `gitlabHost` | `gitlab.apps.example.demo` | Replace with your demo GitLab hostname |
| `gitlabGroup` | `demos` | Group that will own the repo |
| `namespace` | `demo-landing` | OpenShift target namespace |
| `argoInstance` | `default` | Must match RHDH Argo CD config |

### Catalog annotations

The generated `catalog-info.yaml` enables:

- **Argo CD** tab: `argocd/app-name`, `argocd/instance-name`
- **Topology / Kubernetes** tabs: `backstage.io/kubernetes-id`, `backstage.io/kubernetes-namespace`

Matching labels (`backstage.io/kubernetes-id`, `app.openshift.io/runtime: nginx`) are set on the Helm workloads.

### Runtime prerequisites

- RHDH with dynamic plugins: GitLab scaffolder, Argo CD (frontend + `argocd:create-resources`), Kubernetes, Topology
- GitLab integration (token with permission to create projects in the target group)
- Argo CD / OpenShift GitOps configured in RHDH (`argoInstance` must exist)
- Target OpenShift namespace available (or allow Argo CD to create it)

### Local chart check

```bash
helm template demo-landing charts/demo-landing --namespace demo-landing
```
