# Deploy and Host WebCodex on Railway

WebCodex is an open-source, self-hosted MCP server that gives ChatGPT, Claude and other MCP clients a real development environment on your own machines. The Server authenticates requests and routes them to a Runner on the computer that holds your repositories, where the assistant can read and edit code, run tests and use Git.

## About Hosting WebCodex

This template deploys the WebCodex Server 0.5.1 from its official image, built from a public GitHub repo so you get update notices. Railway gives it a public HTTPS domain, which MCP clients and Runners need. The SQLite database, users, tokens and Runner registry live on a volume, so they survive restarts and redeploys. A 64-character admin token is generated on deploy; the server refuses to start without one, and every MCP and API call needs a credential. The Runner is not part of the template: it runs on your own computer or server, next to your code, and joins with a one-time pairing code.

## Common Use Cases

* Let ChatGPT or Claude inspect, edit, test and commit code in repositories that stay on your own machines
* Give one MCP endpoint access to several computers (laptop, home server, cloud VM), each with its own Runner
* Keep an always-on public HTTPS server for AI coding work without opening ports on your workstation

## Dependencies for WebCodex Hosting

* WebCodex Server (this template): one service with a volume, no database needed
* WebCodex Runner on each computer that holds your code (Linux, macOS or Windows; `npm install -g @yyjeqhc/webcodex` or a release archive)

### Deployment Dependencies

* [WebCodex on GitHub](https://github.com/yyjeqhc/webcodex) and the [v0.5.1 release](https://github.com/yyjeqhc/webcodex/releases/tag/v0.5.1)
* [Deployment guide](https://github.com/yyjeqhc/webcodex/blob/v0.5.1/docs/DEPLOYMENT.md), [MCP guide](https://github.com/yyjeqhc/webcodex/blob/v0.5.1/docs/MCP.md) and [authentication model](https://github.com/yyjeqhc/webcodex/blob/v0.5.1/docs/AUTH_MODEL.md)
* Template repo: [aalfath/webcodex-railway-template](https://github.com/aalfath/webcodex-railway-template)

### Implementation Details

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

## Why Deploy WebCodex on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying WebCodex on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
