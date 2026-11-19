# Glossary

**Containerization**: The concept of packaging a program with everything it needs to run, so it runs as an isolated process on a shared kernel. Tool-independent.
_Avoid_: "Docker" when the idea, not the tool, is meant.

**Docker**: The tool students use to build, run and push container images. One implementation of containerization.

**Session**: One of the four in-room meetings of the course (~4h).

**Lesson**: One self-contained study unit teaching a single skill: knowledge, guided terminal steps, quiz. Several lessons support one session.
_Avoid_: "module", "chapter".

**Reference sheet**: A compressed, printable summary that lessons point to and students return to.
_Avoid_: "cheat sheet" in file names.

**Assignment**: A PR-reviewed piece of homework that builds on the student's own repository (A1–A3, final).

**Fault hunt**: A homework where a script builds a local cluster with deliberately planted faults, and the student diagnoses and fixes them.
_Avoid_: "challenge".

**Planted fault**: One deliberate misconfiguration in a fault hunt, chosen to teach one diagnosis habit.

**Spine**: The fixed four-session course structure the material follows.

**Image**: A read-only package of files plus the command to run, in the OCI format. The "class".

**Container**: A running process created from an image, isolated by namespaces and limited by cgroups. The "object": one image, many containers.
_Avoid_: "a lightweight VM".

**Registry**: A server that stores and serves images (Docker Hub, GHCR).

**Chart**: A Helm package: templates plus default values that render into ordinary Kubernetes YAML.

**Release**: One installed instance of a chart in a cluster, with numbered revisions Helm can roll back to.
_Avoid_: "deployment" for a release; a Deployment is a Kubernetes object.

**Values file**: The YAML file of parameters you pass to a chart with `-f`. Committed to git so anyone can reproduce the install.

**Custom resource definition (CRD)**: A new kind of object (a new noun) added to the Kubernetes API. The CRD is the "class"; a **custom resource** is one object of that kind.

**Controller**: A program that watches objects in the API and changes the world until it matches them, again and again. The Deployment controller is one.

**Operator**: A controller for your own custom resources that carries the operational knowledge of one piece of software (here: Prometheus).
_Avoid_: "a template" or "an installer"; Helm installs, the operator keeps running.

**Level-triggered**: Acting on the whole current state rather than on single events, so a missed event is caught up on the next pass.

**ServiceMonitor**: A custom resource that tells the Prometheus operator which Services to scrape. It replaces hand-written scrape config.
