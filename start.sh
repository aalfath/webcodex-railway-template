#!/bin/sh
# Railway start wrapper for WebCodex Server. Any failure exits non-zero so
# Railway's ON_FAILURE restart policy restarts the service.
set -eu

DATA="${WEBCODEX_DATA:-/var/lib/webcodex}"
export WEBCODEX_DATA="$DATA"

if [ -z "${WEBCODEX_TOKEN:-}" ]; then
  echo "webcodex-railway: WEBCODEX_TOKEN is empty; set it to a long random secret (the template generates one)." >&2
  exit 1
fi

# Listen on Railway's PORT on all interfaces.
export WEBCODEX_ADDR="0.0.0.0:${PORT:-8080}"

# Public HTTPS origin, used for OpenAPI servers[0].url and as the OAuth issuer.
# An explicit WEBCODEX_PUBLIC_URL wins; otherwise derive it from the Railway
# domain. An empty or malformed value is ignored rather than fatal.
url="${WEBCODEX_PUBLIC_URL:-}"
case "$url" in
  https://?*.?*) ;;
  *) url="" ;;
esac
if [ -z "$url" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  url="https://${RAILWAY_PUBLIC_DOMAIN}"
fi
if [ -n "$url" ]; then
  url="${url%/}"
  export WEBCODEX_PUBLIC_URL="$url"
  # Same as `webcodex server init --public-url`: OAuth on, issuer = public URL.
  export WEBCODEX_OAUTH2_ENABLED="${WEBCODEX_OAUTH2_ENABLED:-true}"
  export WEBCODEX_OAUTH2_ISSUER="${WEBCODEX_OAUTH2_ISSUER:-$url}"
else
  unset WEBCODEX_PUBLIC_URL 2>/dev/null || true
  echo "webcodex-railway: no public domain yet; starting without WEBCODEX_PUBLIC_URL (OAuth off)." >&2
fi

# Railway shows every host CPU inside a small service: size Tokio's worker
# pool and glibc's malloc arenas from the cgroup CPU quota instead.
cpus=1
if [ -r /sys/fs/cgroup/cpu.max ]; then
  read -r quota period < /sys/fs/cgroup/cpu.max || true
  if [ "${quota:-max}" != "max" ] && [ "${period:-0}" -gt 0 ] 2>/dev/null; then
    cpus=$(( (quota + period - 1) / period ))
  else
    cpus=$(nproc 2>/dev/null || echo 2)
  fi
fi
[ "$cpus" -ge 2 ] 2>/dev/null || cpus=2
[ "$cpus" -le 8 ] || cpus=8
export TOKIO_WORKER_THREADS="${TOKIO_WORKER_THREADS:-$cpus}"
export MALLOC_ARENA_MAX="${MALLOC_ARENA_MAX:-2}"

# The Railway volume is mounted root-owned: hand it to the webcodex user.
mkdir -p "$DATA"
chown -R webcodex:webcodex "$DATA"
chmod 0700 "$DATA"

cd "$DATA"
export HOME="$DATA"
# Run the server as a child so this script (PID 1) can turn any unexpected
# stop into a non-zero exit, which Railway's ON_FAILURE policy restarts.
# A PID 1 process ignores signals it has no handler for, so keeping the
# server off PID 1 also lets `kill` test crash restarts.
setpriv --reuid=webcodex --regid=webcodex --init-groups -- /usr/local/bin/webcodex-server &
child=$!
stopping=0
trap 'stopping=1; kill -TERM "$child" 2>/dev/null' TERM INT
rc=0
while :; do
  wait "$child" && rc=0 || rc=$?
  kill -0 "$child" 2>/dev/null || break
done
if [ "$stopping" = 0 ] && [ "$rc" = 0 ]; then
  echo "webcodex-railway: webcodex-server exited unexpectedly; exiting 1 so Railway restarts it." >&2
  rc=1
fi
echo "webcodex-railway: webcodex-server stopped (exit $rc)." >&2
exit "$rc"
