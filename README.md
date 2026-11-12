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
2. Renders **one** GitLab repo content: Helm chart + Argo CD Application manifests + `catalog-info.yaml`
3. Publishes the repository to self-hosted GitLab (`gitlab-gitlab.<ocp-apps-domain>`)
4. Registers the component in the RHDH catalog
5. Bootstraps an Argo CD **app-of-apps** that syncs `./app-of-apps` from that same repo

There is **no CI build**: the chart serves static HTML from a ConfigMap using `nginxinc/nginx-unprivileged`.

### What lands in the GitLab repo

| Path | Role |
|------|------|
| `chart/` | Helm chart deployed to OpenShift |
| `app-of-apps/` | Three Argo CD Applications (development, stage, prod) |
| `catalog-info.yaml` | RHDH catalog entity |

The scaffolder action only creates `${name}-app-of-apps`. That app syncs `app-of-apps/`, which creates three Helm Applications:

| Argo Application | Destination namespace |
|------------------|----------------------|
| `${name}-development` | `tssc-app-development` |
| `${name}-stage` | `tssc-app-stage` |
| `${name}-prod` | `tssc-app-prod` |

There is no environment picker in the template form: all three environments are always created.

### Default parameters

| Parameter | Default | Notes |
|-----------|---------|-------|
| `name` | `demo-landing` | Repo, Argo apps prefix, and entity name |
| `repoOwner` | `development` | GitLab group that will own the repo |
| `repoVisibility` | `public` | GitLab project visibility |
| `argoInstance` | `default` | Must match RHDH Argo CD config |
| `argoNS` | `tssc-gitops` | Namespace for Argo Application CRs |
| `argoProject` | `default` | Argo CD project |

The GitLab host is **not** a form field: it is derived as `gitlab-gitlab.${ocp-apps-domain}` from `provisioning-data`.

### Catalog annotations

The generated `catalog-info.yaml` enables:

- **CD** tab (Argo CD): `argocd/app-selector: tssc/gitops=<name>` (same as laposte-api)
- **Topology / Kubernetes**: `backstage.io/kubernetes-id`
- **Source link**: `backstage.io/source-location`
- **Entity type**: `service`

CI is suppressed on purpose:
- no `janus-idp.io/tekton`
- `gitlab.com/project-slug: ""` and `gitlab.com/instance: ""` so the GitLab filler/SCM slug processor cannot enable the GitLab pipelines CI tab

Argo Applications are labeled `tssc/gitops: <name>` so the CD selector matches. Do not set `argocd/instance-name: default` unless that name exists in the RHDH Argo config (laposte-api omits it).

### Runtime prerequisites

- Catalog entity **`component:default/provisioning-data`** with label `ocp-apps-domain` (same pattern as TSSC workshop templates)
- RHDH with dynamic plugins: GitLab scaffolder, Argo CD (frontend + `argocd:create-resources`), Kubernetes, Topology
- GitLab integration for host `gitlab-gitlab.<ocp-apps-domain>` (token with permission to create projects in the target group)
- Argo CD / OpenShift GitOps configured in RHDH (`argoInstance` must exist)
- Managed namespaces `tssc-app-development`, `tssc-app-stage`, and `tssc-app-prod` available to the `tssc-gitops` Argo CD instance

#### RHDH 1.10 Argo CD UI (CD tab)

After migrating from 1.9 → 1.10, enable the Argo CD frontend mountPoints and a real instance (not `instances: []`). See [`rhdh/dynamic-plugins-argocd.yaml`](rhdh/dynamic-plugins-argocd.yaml) (`bs_1.49.4` overlays).

### Local chart check

```bash
helm template demo-landing charts/demo-landing --namespace demo-landing
```
