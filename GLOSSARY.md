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
