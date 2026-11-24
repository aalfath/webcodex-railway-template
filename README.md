[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/webcodex?utm_medium=integration&utm_source=button&utm_campaign=webcodex)

# WebCodex on Railway

One-click Railway template for the [WebCodex](https://github.com/yyjeqhc/webcodex) Server: a self-hosted MCP server that gives ChatGPT, Claude and other MCP clients a real development environment on your own machines, through Runners that join it.

**What it deploys:** one service, `WebCodex`, built from this repo's `Dockerfile` on top of the official image `ghcr.io/yyjeqhc/webcodex-server:0.5.1@sha256:bb77ba605ef7a3f5a7fbad36018d556126cd0691d2b00dd39f3aedd31b0fac2e` (WebCodex 0.5.1), with a volume at `/var/lib/webcodex`, a public Railway domain, health check `/healthz` and restart on failure.

## Variables

| Variable | Default | What it is |
| --- | --- | --- |
| `WEBCODEX_TOKEN` | `${{secret(64, "abcdef0123456789")}}` | Bootstrap admin token, generated on deploy. Server-side only: pairing codes, user creation, recovery. Not an MCP credential. |
| `PORT` | `8080` | Port the server listens on (Railway routes the domain to it). |

Nothing to fill in. Optional: `WEBCODEX_PUBLIC_URL` if you put a custom domain in front (by default it is `https://` + the Railway domain, also used as the OAuth issuer), `RUST_LOG` (default `info`), and the other `WEBCODEX_*` settings in upstream's [deployment guide](https://github.com/yyjeqhc/webcodex/blob/v0.5.1/docs/DEPLOYMENT.md).

## After deploy

**After deploy, join your first Runner.** The template asks you nothing. Create a one-time pairing code on the Server with the Railway CLI (it uses the generated admin token, which never leaves the Server):

```bash
railway ssh --service WebCodex -- sh -c 'webcodex pairing create --server-url http://127.0.0.1:$PORT --username admin --ttl-secs 600'
```

On the computer that holds your code (Node.js 18+), redeem it and start the Runner:

```bash
npm install -g @yyjeqhc/webcodex
webcodex login https://YOUR-DOMAIN.up.railway.app --code wc_pair_... --allowed-root ~/git --project ~/git/my-repo --print-mcp-config
webcodex runner run --config RUNNER-CONFIG-PRINTED-BY-LOGIN
```

`--print-mcp-config` prints the MCP URL (`https://YOUR-DOMAIN.up.railway.app/mcp`) and a personal Bearer credential. In ChatGPT Developer Mode, add a custom MCP app with that URL and "Access token / API key"; for Claude Code or Codex, `webcodex mcp-config --client claude|codex --url https://YOUR-DOMAIN.up.railway.app/mcp --project my-repo` prints a config that reads the credential from an environment variable. Use `webcodex runner install --scope user --config ...` to keep the Runner running in the background.

**Variables:** `WEBCODEX_TOKEN` is the generated bootstrap admin token, used only on the Server (pairing, user creation, recovery); don't give it to MCP clients. `PORT` is 8080. The public URL and OAuth issuer come from the Railway domain; set `WEBCODEX_PUBLIC_URL` only if you add a custom domain.

**Resources:** the Server idles at about 20–35 MB of RAM and fits Railway's Free plan (0.5 GB). Code runs on your Runner machines, not on Railway, and nothing here needs Docker-in-Docker or privileged mode.

**Updates:** the service builds from [aalfath/webcodex-railway-template](https://github.com/aalfath/webcodex-railway-template). When we move it to a new WebCodex release, Railway offers you the update; read the repo's `CHANGELOG.md` first and keep your Runners on a compatible version.

## Files

- `Dockerfile`: the pinned official image plus the start script.
- `start.sh`: listens on `PORT`, derives the public URL from the Railway domain, sizes Tokio worker threads from the CPU quota, hands the volume to the image's `webcodex` user, and supervises the server so an unexpected stop exits non-zero (Railway restarts it).
- `OVERVIEW.md`: the marketplace overview.
- `CHANGELOG.md`: one entry per template update; breaking changes first.

## How updates reach you

The template's service builds from this repo's `main` branch. When we bump WebCodex here, Railway shows deployers an "update available" notice, and you choose when to apply it. Read `CHANGELOG.md` before applying; your data stays on the volume.

WebCodex is Apache-2.0 licensed by its authors. This repo only packages it for Railway.
