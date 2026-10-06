# From Code to Cluster (Kubernetes and DevOps) Resources

Scope so far: Session 1 (containerization → Docker → GHCR → kind → Kubernetes first contact). Links verified 2026-10-05.
Versions at that date: Kubernetes v1.37.1, kind v0.33.0, Go 1.27.1, Rancher Desktop v1.24.0, OCI image-spec v1.1.1.

## Knowledge

### Containerization (concept)

- [Video: "Containers From Scratch" by Liz Rice (GOTO 2018)](https://www.youtube.com/watch?v=8fi7uSYlOdc)
  Builds a container live in Go from namespaces, chroot and cgroups. **Recommended watch** for the containerization lesson: it shows that a container is just a process.
- [Docs: "What is a container?" (Docker)](https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-a-container/)
  Beginner definition plus container vs VM. Use for: the first explainer paragraph.
- [Docs: "What is an image?" (Docker)](https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-an-image/)
  Image vs container, immutability. Use for: the image/container distinction quiz.
- [Docs: "Understanding image layers" (Docker)](https://docs.docker.com/get-started/docker-concepts/building-images/understanding-image-layers/)
  Layers and the union filesystem, with a hands-on. Use for: layers and why cache order matters.
- [Man page: namespaces(7) (Linux man-pages)](https://man7.org/linux/man-pages/man7/namespaces.7.html) and [cgroups(7)](https://man7.org/linux/man-pages/man7/cgroups.7.html)
  Canonical kernel definitions. Use for: citing namespaces and cgroups. Link only, because S1 stays at intuition level.
- [Spec: OCI Image Format Specification (Open Container Initiative)](https://github.com/opencontainers/image-spec/blob/main/spec.md)
  Manifest, config, layers, index. Use for: "why any runtime can run a Docker-built image". Read the overview only.
- [Article: "Learning Containers From The Bottom Up" by Ivan Velichko](https://iximiuz.com/en/posts/container-learning-path/)
  Expert roadmap from runc to Kubernetes. Use for: optional deeper reading and instructor background.

### Docker (tool)

- [Docs: Dockerfile best practices (Docker)](https://docs.docker.com/build/building/best-practices/)
  Covers multi-stage builds, minimal base images, `.dockerignore`, the build cache, digest pinning and `USER` non-root. **Recommended read** for the Dockerfile lesson.
- [Docs: Dockerfile reference (Docker)](https://docs.docker.com/reference/dockerfile/)
  Every instruction. Use for: citing the exact syntax of `FROM`, `COPY`, `USER`, `CMD` and `EXPOSE`.
- [Docs: Multi-stage builds (Docker)](https://docs.docker.com/build/building/multi-stage/)
  `AS build` and `COPY --from`. Use for: the build stage vs runtime stage step.
- [Docs: Build context and .dockerignore (Docker)](https://docs.docker.com/build/concepts/context/)
  What gets sent to the builder. Use for: the `.dockerignore` step.
- [Docs: Base images, including scratch (Docker)](https://docs.docker.com/build/building/base-images/)
  Use for: the `FROM scratch` option.
- [Repo: distroless (Google)](https://github.com/GoogleContainerTools/distroless)
  `gcr.io/distroless/static-debian13` (~2 MiB) and the `:nonroot` tag for static Go binaries. Use for: the final-stage base image.
- [Docs: Go language guide (Docker)](https://docs.docker.com/guides/golang/)
  A complete Go multi-stage, distroless, non-root example. Use for: the overall pattern. **Stale**: it uses `golang:1.19`, so do not copy the version.
- [Docs: Docker CLI reference (Docker)](https://docs.docker.com/reference/cli/docker/)
  Primary source for every `docker` command, including on Rancher Desktop with the dockerd engine.
- [Docs: Install Docker Desktop on Mac (Docker)](https://docs.docker.com/desktop/setup/install/mac-install/)
  The course's macOS engine. Free for personal use and education. Use for: macOS setup in the pre-flight lesson.
- [Docs: Docker Desktop settings (Docker)](https://docs.docker.com/desktop/settings-and-maintenance/settings/)
  The VM memory limit defaults to 50% of the host's memory, and Kubernetes is off by default. Use for: the memory and Kubernetes checks.
- [Docs: Container engine settings (Rancher Desktop, optional alternative)](https://docs.rancherdesktop.io/ui/preferences/container-engine/general/)
  Choose **dockerd (moby)** to get the stock `docker` CLI, not containerd with `nerdctl`. Images do not carry over when you switch engines. Use for: the setup notes for Rancher users.
- [Docs: Kubernetes settings (Rancher Desktop)](https://docs.rancherdesktop.io/ui/preferences/kubernetes/)
  How to disable the built-in k3s to save resources. Use for: telling students to turn it off, since we use kind.

### GHCR

- [Docs: Working with the Container registry (GitHub)](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
  Push requires a **classic** PAT with `write:packages`. Covers `docker login ghcr.io --password-stdin`, tag format, and the `org.opencontainers.image.source` label. **Recommended read** for the push lesson.
- [Docs: Package access control and visibility (GitHub)](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility)
  A newly published package is **private by default**. Use for: making the image public so kind can pull it without a secret.
- [Docs: Managing personal access tokens (GitHub)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
  Use for: the token-creation steps.

### Go (the sample app)

- [Example: "HTTP Server" (Go by Example)](https://gobyexample.com/http-server)
  The shortest correct `net/http` server. **Recommended read** for the Go server step.
- [Docs: net/http package (Go team)](https://pkg.go.dev/net/http) and [os.Getenv](https://pkg.go.dev/os#Getenv)
  Primary citations for `ListenAndServe`, `HandleFunc`, and reading `PORT` from the environment.
- [Blog: "Routing Enhancements for Go 1.22" (Go team)](https://go.dev/blog/routing-enhancements)
  Method and path patterns in the stdlib mux, such as `GET /healthz`. Use for: a health endpoint without extra libraries.
- [Tutorial: Get started with Go (Go team)](https://go.dev/doc/tutorial/getting-started)
  Use for: students who have never run `go mod init`.

### kind

- [Docs: kind Quick Start (Kubernetes SIGs)](https://kind.sigs.k8s.io/docs/user/quick-start/)
  Covers install, `kind create cluster`, and `kind load docker-image`. It also documents the `:latest` → `imagePullPolicy: Always` trap. **Recommended read** for the kind lesson.
- [Docs: kind private registries (Kubernetes SIGs)](https://kind.sigs.k8s.io/docs/user/private-registries/)
  Three options: `imagePullSecrets` (preferred), pull then side-load, or mounting the config on nodes (credential helpers do not work there). Use for: pulling a private GHCR image.
- [Docs: kind known issues (Kubernetes SIGs)](https://kind.sigs.k8s.io/docs/user/known-issues/)
  Use for: the lesson's "if it breaks" box.
- [Docs: Pull an image from a private registry (Kubernetes)](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)
  `kubectl create secret docker-registry` plus `imagePullSecrets`. Use for: the Kubernetes side of a private pull.

### Kubernetes first contact

- [Tutorial: Learn Kubernetes Basics (Kubernetes)](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
  Six modules: deploy, explore, expose, scale, update. **Recommended read** for Pod → Deployment → Service; do modules 2–5 and skip module 1 (minikube), because we use kind.
- [Docs: Objects in Kubernetes (Kubernetes)](https://kubernetes.io/docs/concepts/overview/working-with-objects/)
  spec vs status, and the YAML skeleton. Use for: the hand-written YAML lesson.
- [Docs: Pods](https://kubernetes.io/docs/concepts/workloads/pods/), [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/), [ReplicaSet](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/), [Service](https://kubernetes.io/docs/concepts/services-networking/service/) (Kubernetes)
  Primary concept pages. Use for: citing each object; ReplicaSet explains self-healing.
- [Docs: Debug Pods (Kubernetes)](https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/)
  Diagnosing Pending, CrashLoopBackOff and ImagePullBackOff with get/describe/logs/events. **Recommended read** for the "looking with kubectl" lesson and the fault hunt.
- [Docs: Debug Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/) and [Determine the reason for Pod failure](https://kubernetes.io/docs/tasks/debug/debug-application/determine-reason-pod-failure/) (Kubernetes)
  Selector and port mismatches step by step; termination messages and Last State. Use for: homework 2 (fault hunt).
- [Docs: kubectl diff (Kubernetes)](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_diff/)
  Use for: checking that files match the cluster (lesson 07, homework 2 self-check).
- [Docs: kubectl Quick Reference (Kubernetes)](https://kubernetes.io/docs/reference/kubectl/quick-reference/)
  Use for: the kubectl reference sheet. Per-command pages: [get](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_get/), [describe](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_describe/), [logs](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_logs/), [events](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_events/), [scale](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_scale/), [port-forward](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_port-forward/).
- [Docs: Use port forwarding to access applications (Kubernetes)](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/)
  Use for: reaching the Service from the laptop.
- [Docs: Resource management for Pods and containers (Kubernetes)](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
  Use for: requests and limits.
- [Docs: Liveness, readiness and startup probes (Kubernetes)](https://kubernetes.io/docs/concepts/workloads/pods/probes/) and [the task page](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
  The concept page explains why; the task page has copyable `httpGet` YAML. **Recommended read** for the probes and limits topic.
- [Video: "Kubernetes Explained in 100 Seconds" (Fireship)](https://www.youtube.com/watch?v=PziYflu8cB8)
  Optional 2-minute hook only. Never use it as a citation.

### Also cited in lessons (setup and specifics)

- [Docs: Docker Engine install](https://docs.docker.com/engine/install/), [Ubuntu](https://docs.docker.com/engine/install/ubuntu/), [Linux post-install](https://docs.docker.com/engine/install/linux-postinstall/) (Docker). Use for: Linux and WSL2 setup in the pre-flight lesson.
- [Docs: Rancher Desktop installation (Rancher Desktop)](https://docs.rancherdesktop.io/getting-started/installation/). Use for: macOS setup.
- [Issue: kind on Rancher Desktop + WSL2 (rancher-desktop#5604)](https://github.com/rancher-sandbox/rancher-desktop/issues/5604). The reason Windows uses Docker Engine inside WSL2.
- [Docs: Docker Hub usage and limits (Docker)](https://docs.docker.com/docker-hub/usage/). Use for: the pull-rate limit and why to `docker login`.
- [Docs: docker login](https://docs.docker.com/reference/cli/docker/login/), [docker image tag](https://docs.docker.com/reference/cli/docker/image/tag/), [docker run --restart](https://docs.docker.com/reference/cli/docker/container/run/#restart) (Docker). Use for: exact CLI behaviour.
- [Docs: Images (Kubernetes)](https://kubernetes.io/docs/concepts/containers/images/). Use for: imagePullPolicy and the `:latest` trap.
- [Docs: Controllers (Kubernetes)](https://kubernetes.io/docs/concepts/architecture/controller/). Use for: desired state and reconciliation.
- [Docs: Cluster Architecture (Kubernetes)](https://kubernetes.io/docs/concepts/architecture/). Use for: control plane vs worker nodes.
- [Docs: Kubernetes Components (Kubernetes)](https://kubernetes.io/docs/concepts/overview/components/). Use for: what each component does.
- [Docs: Organizing cluster access using kubeconfig files (Kubernetes)](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/). Use for: clusters, users, contexts, KUBECONFIG.
- [Docs: Init Containers (Kubernetes)](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/). Use for: containers that run to completion before the app starts.
- [Docs: Services, Load Balancing, and Networking (Kubernetes)](https://kubernetes.io/docs/concepts/services-networking/). Use for: the network model (every Pod reaches every Pod), CNI.
- [Docs: Owners and Dependents (Kubernetes)](https://kubernetes.io/docs/concepts/overview/working-with-objects/owners-dependents/). Use for: ownerReferences, garbage collection.
- [Docs: EndpointSlices (Kubernetes)](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/). Use for: the Pods behind a Service.
- [Docs: DNS for Services and Pods (Kubernetes)](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/). Use for: service names, `<service>.<namespace>.svc.cluster.local`.
- [Docs: Pod Quality of Service classes (Kubernetes)](https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/). Use for: BestEffort, Burstable, Guaranteed and eviction order.
- [Docs: Liveness, Readiness and Startup Probes (Kubernetes)](https://kubernetes.io/docs/concepts/workloads/pods/probes/). Use for: what each probe failure does.
- [Docs: Pod lifecycle, termination (Kubernetes)](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination). Use for: SIGTERM, grace period, SIGKILL.
- [Article: The Twelve-Factor App, Config](https://12factor.net/config). Use for: why the port comes from an environment variable.
- [Site: Retrieval Practice (Agarwal & Bain)](https://www.retrievalpractice.org/). Use for: why the recap quiz is spaced.

## Wisdom (Communities)

- [Kubernetes Slack](https://slack.k8s.io/)
  Official, under the Code of Conduct. Use for: beginner questions and kind-specific help.
- [CNCF Slack](https://slack.cncf.io/)
  Use for: the wider cloud native ecosystem; it has a `#budapest` channel.
- [Discuss Kubernetes forum](https://discuss.kubernetes.io/)
  Moderated and searchable. Use for: questions that need long answers.
- [Docker Community Forums](https://forums.docker.com/)
  Use for: Docker build and engine problems.
- [r/kubernetes](https://www.reddit.com/r/kubernetes/), [r/docker](https://www.reddit.com/r/docker/), [r/golang](https://www.reddit.com/r/golang/)
  Medium signal. Use for: "how do people actually do X". (Not fetch-verifiable; check manually.)
- Local: [Cloud Native Budapest (CNCF chapter)](https://community.cncf.io/cloud-native-budapest/)
  The official CNCF meetup chapter. The old Meetup group `k8s-bud` is gone. Use for: in-person talks and networking.
- Local: [Cloud Native Hungary Discord](https://discord.gg/bVuvgGkt8Q)
  The Hungarian community chat, run by the KCD Budapest organisers. Use for: local questions and event news.
- Local: [KCD Budapest 2026](https://kcdbudapest.hu/), 30 Oct 2026, Óbuda University
  A CNCF-supported community conference. Use for: a one-day immersion that students could realistically attend.
- Local: [Go Budapest meetup](https://www.meetup.com/go-budapest/)
  Hungarian-language Go talks; recent activity is unclear. Use for: the Go side of the course.

## Gaps

- No non-vendor, student-level primary source for "container vs VM"; Docker's page plus the Liz Rice talk cover it.
- No official doc covers **Rancher Desktop + kind on macOS** together; our own dry runs must fill this.
- No single official page covers **GHCR private image → kind pull** end to end; combine the GitHub, Kubernetes and kind docs, or make the package public in S1.
- Docker's Go guide uses an old Go version (1.19); we need our own pinned, current example.
- No Hungarian-language primary material (the material is English by design).

Community preferences: none recorded yet.
