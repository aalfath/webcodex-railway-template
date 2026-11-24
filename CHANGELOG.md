# Changelog

Each entry is one update of this Railway template. Breaking changes come first.
Railway shows an "update available" notice to everyone who deployed the
template when a change lands on `main`; read the entry before you apply it.

## 0.5.1 (2026-11-24)

- Breaking changes: none (first release of this template).
- WebCodex Server 0.5.1, official image
  `ghcr.io/yyjeqhc/webcodex-server:0.5.1@sha256:bb77ba605ef7a3f5a7fbad36018d556126cd0691d2b00dd39f3aedd31b0fac2e`.
- Data (SQLite database, users, tokens, Runner and project registry) on a Railway
  volume at `/var/lib/webcodex`.
- Generated 64-character bootstrap admin token (`WEBCODEX_TOKEN`); the server
  refuses to start without it.
- Public URL and OAuth issuer derived from the Railway domain.
- Start script: listens on `PORT`, fixes volume ownership, sizes Tokio worker
  threads from the service's CPU quota, and exits non-zero on any unexpected
  stop so Railway's ON_FAILURE policy restarts it.
