## Stack: Docker
Applies to the directory that contains a `Dockerfile`, `*.Dockerfile`, `compose.yaml`, or `docker-compose.yml`.
- Check: `docker build --check .`. Lint: `hadolint Dockerfile` if it is installed. Compose: `docker compose config -q`.
- Build only to check. Never push images. Do not run `docker system prune` or delete volumes.
- Use multi-stage builds. The final stage has no compilers, package caches, or build-only files.
- Pin each base image to a version tag. Pin the digest too if the project does (`image:1.2.3@sha256:...`).
  Never use `latest`.
- Run as a non-root user: `USER <uid>`. Use a numeric UID.
- Secrets: use `RUN --mount=type=secret`. Never pass secrets with `ARG`, `ENV`, or `COPY`. They stay in the image.
- Keep `.dockerignore` current. It excludes `.git`, `.env*`, and local build output.
- Copy the dependency manifests and install them before you copy the source. This keeps the layer cache.
  Use `RUN --mount=type=cache` for package manager caches.
- Debian or Ubuntu: run `apt-get update` and `apt-get install --no-install-recommends` in one `RUN`.
  Remove `/var/lib/apt/lists/*` in the same `RUN`.
- Use `COPY`. Use `ADD` only for a remote file with `--checksum`, or to extract a local archive.
- Use the exec form for `CMD` and `ENTRYPOINT`: `["app", "--flag"]`.
- Image scan: `docker scout cves` or `trivy image`. Use the tool that the project uses.
