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

1. Fetches `component:default/provisioning-data` to resolve the demo cluster domain
2. Renders a Helm chart + `catalog-info.yaml`
3. Creates a repository on the self-hosted GitLab (`gitlab-gitlab.<ocp-apps-domain>`)
4. Registers the component in the RHDH catalog
5. Creates an Argo CD Application via `argocd:create-resources`

There is **no CI build**: the chart serves static HTML from a ConfigMap using `nginxinc/nginx-unprivileged`.

### Default parameters

| Parameter | Default | Notes |
|-----------|---------|-------|
| `name` | `demo-landing` | Repo, Argo app, and entity name |
| `repoOwner` | `demos` | GitLab group that will own the repo |
| `repoVisibility` | `public` | GitLab project visibility |
| `namespace` | `demo-landing` | OpenShift target namespace |
| `argoInstance` | `default` | Must match RHDH Argo CD config |

The GitLab host is **not** a form field: it is derived as `gitlab-gitlab.${ocp-apps-domain}` from `provisioning-data`.

### Catalog annotations

The generated `catalog-info.yaml` enables:

- **Argo CD** tab: `argocd/app-name`, `argocd/instance-name`
- **Topology / Kubernetes** tabs: `backstage.io/kubernetes-id`, `backstage.io/kubernetes-namespace`
- **Source link**: `backstage.io/source-location`, `gitlab.com/project-slug`

Matching labels (`backstage.io/kubernetes-id`, `app.openshift.io/runtime: nginx`) are set on the Helm workloads.

### Runtime prerequisites

- Catalog entity **`component:default/provisioning-data`** with label `ocp-apps-domain` (same pattern as TSSC workshop templates)
- RHDH with dynamic plugins: GitLab scaffolder, Argo CD (frontend + `argocd:create-resources`), Kubernetes, Topology
- GitLab integration for host `gitlab-gitlab.<ocp-apps-domain>` (token with permission to create projects in the target group)
- Argo CD / OpenShift GitOps configured in RHDH (`argoInstance` must exist)
- Target OpenShift namespace available (or allow Argo CD to create it)

### Local chart check

```bash
helm template demo-landing charts/demo-landing --namespace demo-landing
```
