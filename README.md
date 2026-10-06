# From Code to Cluster: containers, CI and Kubernetes

Study material for a four-session, hands-on course: write your own web server, put it in a container, run it on Kubernetes, automate it, observe it, and operate it with GitOps.

Open the lessons in a browser. Each one is a short, self-contained HTML page with background, terminal steps and a self-check quiz.

## Session 1: containerization → Docker → first contact with Kubernetes

| # | Lesson | Time | When |
|---|---|---|---|
| 00 | [Pre-flight check](lessons/s1-00-preflight.html) | ~30' | before the session |
| 01 | [Why containers?](lessons/s1-01-why-containers.html) | 15' | before the session |
| 02 | [Your web server](lessons/s1-02-web-server.html) | 15' | before |
| 03 | [First Dockerfile](lessons/s1-03-first-dockerfile.html) | 15' | after |
| 04 | [Advanced Dockerfile: multi-stage, EXPOSE, VOLUME, USER](lessons/s1-04-advanced-dockerfile.html) | 20' | after |
| 05 | [Why orchestration + kind](lessons/s1-05-why-orchestration.html) | 20' | before |
| 06 | [Looking with kubectl](lessons/s1-06-looking-with-kubectl.html) | 15' | after |
| 07 | [Pod, Deployment, Service: YAML, update and roll back](lessons/s1-07-pod-deployment-service.html) | 60' | after |
| 08 | [Health and resources: requests, limits, QoS, probes, shutdown](lessons/s1-08-health-and-resources.html) | 35' | after |
| 09 | [Recap quiz](lessons/s1-09-recap-quiz.html) | ~12' | before session 2 |

### Homework 1 (between session 1 and session 2)

[Make your server twelve-factor](homework/hw1-twelve-factor.html): a Redis-backed visit counter, 2 replicas, graceful shutdown, JSON logs, startup/readiness/liveness probes. Check your work with [scripts/check-12factor.sh](scripts/check-12factor.sh). About 6–8 hours, submitted as a pull request.

### Homework 2 (between session 1 and session 2)

[Fault hunt: bring a broken deployment back](homework/hw2-fault-hunt.html): eight planted faults in a Deployment and a Service on a local one-node kind cluster, found with `get`, `describe`, events and logs, fixed in files, and written up as a report. Set up with [scripts/fault-hunt-up.sh](scripts/fault-hunt-up.sh), check with [scripts/check-fault-hunt.sh](scripts/check-fault-hunt.sh). About 60–90 minutes, submitted as a pull request.

## Session 2: CI/CD

| # | Lesson | Time | When |
|---|---|---|---|
| 01 | [Push to GHCR](lessons/s2-01-push-ghcr.html) | 10' | after |

The pre-flight lesson uses [scripts/preflight.sh](scripts/preflight.sh) to check your laptop.

Session 1 [cheat sheet](reference/s1-cheat-sheet.html): every command, the Deployment + Service YAML and a symptom → where-to-look table on one printable A4 page.

Also here: [RESOURCES.md](RESOURCES.md) (the sources behind every lesson) and [GLOSSARY.md](GLOSSARY.md) (the course vocabulary).

Questions? Ask your instructor. That's what they're there for.
