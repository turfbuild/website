#!/bin/sh
# Turf installer.
#
#   curl -fsSL https://get.turf.build/install.sh | bash
#
# Installs the latest Turf release on macOS or Linux, arm64 or x86_64.
#
# - With Homebrew on PATH: brew install restatedev/tap/restate-server
#   turfbuild/tap/turf, then the engine starts as the turf Homebrew service
#   (brew services start turf).
# - Without it: the release archive, into ~/.turf/bin, with no sudo. That is
#   turf, turf-mcp-server, turf-engine and turf-builtin-provider, plus
#   restate-server, the engine's dependency, as Restate's own build from its
#   GitHub release. You start the engine yourself: turf-mcp-server engine run.
#
# Options (curl -fsSL https://get.turf.build/install.sh | bash -s -- OPTIONS):
#   --no-brew        install from the release archive even when Homebrew is here
#   --dir DIR        install the archive into DIR (default ~/.turf/bin)
#   --version TAG    install release TAG from the archive
#   --no-start       with Homebrew, don't start the engine service
#   --no-telemetry   turn usage telemetry off before the engine starts;
#                    TURF_TELEMETRY=off or DO_NOT_TRACK=1 in this shell do the same
# TURF_INSTALL_DIR and TURF_VERSION stand for --dir and --version, and
# TURF_DOWNLOAD_URL replaces https://github.com/turfbuild/turf/releases with a
# mirror of it. Each of the three installs from the archive.
#
# Fetching this script from get.turf.build is counted by Scarf, which estimates
# the organization a download comes from (https://turf.build/privacy/);
# https://turf.build/install.sh serves the same script without it. Turf and
# restate-server download from github.com.
#
# Turf is free for noncommercial use under PolyForm Noncommercial 1.0.0.
# Commercial use, including a company's internal use, requires a license:
# https://turf.build/licensing

set -eu

RELEASES=https://github.com/turfbuild/turf/releases
INSTALL_LINE='curl -fsSL https://get.turf.build/install.sh | bash'
TURF_BINARIES='turf turf-mcp-server turf-engine turf-builtin-provider'
# The restate-server the engine is tested on, and the sha256 of each of
# Restate's archives of it (its release's .sha256 files).
RESTATE_VERSION=1.7.13
RESTATE_RELEASE=https://github.com/restatedev/restate/releases/download/v$RESTATE_VERSION

say() { printf '%s\n' "$*"; }
warn() { printf '%s\n' "$*" >&2; }
die() { printf 'install.sh: %s\n' "$*" >&2; exit 1; }
has() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<'EOF'
Usage: curl -fsSL https://get.turf.build/install.sh | bash -s -- [OPTIONS]

  --no-brew        install from the release archive even when Homebrew is here
  --dir DIR        install the archive into DIR (default ~/.turf/bin)
  --version TAG    install release TAG from the archive
  --no-start       with Homebrew, don't start the engine service
  --no-telemetry   turn usage telemetry off before the engine starts
  -h, --help       show this help

Environment: TURF_INSTALL_DIR, TURF_VERSION, TURF_TELEMETRY, DO_NOT_TRACK, and
TURF_DOWNLOAD_URL (a mirror of https://github.com/turfbuild/turf/releases).
EOF
}

# fetch URL FILE [SECONDS] prints the final HTTP status, or 000 when nothing
# answered (curl's message is then in $tmp/curl.err). curl's own exit status
# isn't used: some builds report an HTTP/2 404 as a receive error.
fetch() {
  _proto=
  case $1 in https://*) _proto='--proto =https --tlsv1.2' ;; esac
  # shellcheck disable=SC2086
  curl -sSL $_proto --retry 2 --connect-timeout 20 --max-time "${3:-900}" \
    -o "$2" -w '%{http_code}' "$1" 2>"$tmp/curl.err" || :
}

# get URL FILE downloads a file the release must have, or stops.
get() {
  _code=$(fetch "$1" "$2")
  case $_code in
    200) ;;
    000) die "couldn't reach $(host_of "$1"): $(tail -n 1 "$tmp/curl.err")" ;;
    *) die "couldn't download $1 (HTTP $_code). Nothing was installed." ;;
  esac
}

host_of() { printf '%s' "$1" | sed 's|^[a-zA-Z]*://||; s|/.*||'; }

lower_trim() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

# pretty PATH shows a path under $HOME as "$HOME/…", ready to paste.
pretty() {
  case $1 in
    "${HOME:-/nonexistent}"/*) printf '%s' "\$HOME${1#"$HOME"}" ;;
    *) printf '%s' "$1" ;;
  esac
}

sha256() {
  if has sha256sum; then sha256sum "$1" | awk '{ print $1 }'
  else shasum -a 256 "$1" | awk '{ print $1 }'
  fi
}

check_sum() {
  _got=$(sha256 "$1" | tr '[:upper:]' '[:lower:]')
  _exp=$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')
  if [ -z "$_exp" ] || [ "$_got" != "$_exp" ]; then
    die "$(basename "$1") failed its checksum (expected ${_exp:-none}, got $_got). Nothing was installed."
  fi
}

cleanup() {
  for _b in $staged; do rm -f "$dir/.install-$$-$_b"; done
  rm -rf "$tmp"
}

detect_platform() {
  _s=$(uname -s) _m=$(uname -m)
  case $_s in Darwin) os=darwin ;; Linux) os=linux ;; *) os= ;; esac
  case $_m in arm64 | aarch64) arch=arm64 ;; x86_64 | amd64) arch=amd64 ;; *) arch= ;; esac
  if [ -z "$os" ] || [ -z "$arch" ]; then
    die "Turf runs on macOS and Linux, on arm64 and x86_64; this is $_s $_m."
  fi
  # A shell under Rosetta reports x86_64 on Apple silicon.
  if [ "$os/$arch" = darwin/amd64 ] && [ "$(sysctl -n sysctl.proc_translated 2>/dev/null || :)" = 1 ]; then
    arch=arm64
  fi
  case $os/$arch in
    darwin/arm64)
      restate_triple=aarch64-apple-darwin
      restate_sha=503c9a74eaad9b3579a373a5cd558b6910b179d17d87c2a75307cd975d1a299d ;;
    darwin/amd64)
      restate_triple=x86_64-apple-darwin
      restate_sha=8bebb7787f003530e4959631111505b5003c87470e8ce3c070b6d02aff73ca89 ;;
    linux/arm64)
      restate_triple=aarch64-unknown-linux-musl
      restate_sha=c0218d5ae5052cc2c6f842bbcfa57fd10240cfe30795c381850c452fbcef2b61 ;;
    linux/amd64)
      restate_triple=x86_64-unknown-linux-musl
      restate_sha=5429b216b68f3fa52b7f0e6627a2c2a86fc0c75d19b1e152cd2e7dcd8bab4c82 ;;
  esac
}

# The engine's own rule (TURF_TELEMETRY, then DO_NOT_TRACK), so that a switch
# set in this shell also reaches an engine that never sees this shell: the
# Homebrew service. telemetry_off says why telemetry goes off; empty leaves
# the setting as it is. The installer never turns telemetry on.
resolve_telemetry() {
  telemetry_off=
  if [ "$opt_no_telemetry" = 1 ]; then
    telemetry_off='you passed --no-telemetry'
  elif [ -n "${TURF_TELEMETRY:-}" ]; then
    case $(lower_trim "$TURF_TELEMETRY") in
      on | true | 1 | yes | enabled) ;;
      *) telemetry_off="TURF_TELEMETRY=$TURF_TELEMETRY is set" ;;
    esac
  else
    case $(lower_trim "${DO_NOT_TRACK:-}") in
      '' | 0 | false) ;;
      *) telemetry_off="DO_NOT_TRACK=$DO_NOT_TRACK is set" ;;
    esac
  fi
}

not_yet() {
  _where=github.com/turfbuild/turf
  if [ -n "${TURF_DOWNLOAD_URL:-}" ]; then _where=$releases; fi
  warn "Turf 1.0 isn't available yet. This installer sets up Turf 1.0 and its"
  warn "engine, and that release isn't on $_where yet. Run the same"
  warn "command again once it's out:"
  warn "  $INSTALL_LINE"
  warn "News: https://turf.build"
  exit 1
}

# The release to install: the latest, or --version. It must carry this
# platform's archive and engine; v0.17.0 and earlier have no engine.
resolve_release() {
  releases=${TURF_DOWNLOAD_URL:-$RELEASES}
  releases=${releases%/}
  if [ -n "$opt_version" ]; then
    case $opt_version in v*) ;; *) opt_version=v$opt_version ;; esac
    _sums=$releases/download/$opt_version/checksums.txt
  else
    _sums=$releases/latest/download/checksums.txt
  fi
  _code=$(fetch "$_sums" "$tmp/checksums.txt" 60)
  case $_code in
    200) ;;
    000) die "couldn't reach $(host_of "$_sums"): $(tail -n 1 "$tmp/curl.err"). Check the network, then run it again: $INSTALL_LINE" ;;
    404)
      if [ -n "$opt_version" ]; then die "there is no Turf release $opt_version at $releases."; fi
      not_yet
      ;;
    *) die "$(host_of "$_sums") answered HTTP $_code for $_sums. Run it again in a while: $INSTALL_LINE" ;;
  esac
  _files=$(awk '{ f = $2; sub(/^\*/, "", f); print f }' "$tmp/checksums.txt")
  tarball=$(printf '%s\n' "$_files" | grep -E "^turf_v[^_/]+_${os}_${arch}\.tar\.gz\$" | head -n 1)
  if [ -z "$tarball" ] || ! printf '%s\n' "$_files" | grep -qx "turf-engine-${os}_${arch}"; then
    if printf '%s\n' "$_files" | grep -q '^turf-engine-' &&
      printf '%s\n' "$_files" | grep -q '^turf_v.*\.tar\.gz$'; then
      die "Turf isn't available for $os/$arch yet."
    fi
    if [ -n "$opt_version" ]; then
      die "release $opt_version has no Turf engine for $os/$arch, which this installer sets up."
    fi
    not_yet
  fi
  tag=${tarball#turf_}
  tag=${tag%_"${os}"_"${arch}".tar.gz}
}

header() {
  say "Turf is free for noncommercial use under PolyForm Noncommercial 1.0.0. Commercial"
  say "use, including a company's internal use, requires a license:"
  say "https://turf.build/licensing"
  say ""
}

# telemetry_notice SETTING: the disclosure, before any engine starts. SETTING
# is on or off: what the engine will run with, from the setting file and, for
# an engine started from this shell, TURF_TELEMETRY.
telemetry_notice() {
  say ""
  if [ -n "$telemetry_off" ]; then
    say "Telemetry is off: $telemetry_off, so the installer ran"
    say "\`turf telemetry off\`, which the engine reads when it starts."
    say "\`turf telemetry on\` turns it back on. What it sends: https://turf.build/telemetry"
  elif [ "$1" = off ]; then
    say "Telemetry is off, as your setting says (\`turf telemetry status\`)."
    say "\`turf telemetry on\` turns it back on. What it sends: https://turf.build/telemetry"
  else
    say "Turf sends anonymous usage telemetry to Turf LLC by default: the version, the"
    say "platform, counts of resources, changes and runs, and an anonymous installation"
    say "id. It never includes resource contents, credentials, state, variable values or"
    say "names. Turn it off with \`turf telemetry off\`, then restart the engine;"
    say "\`TURF_TELEMETRY=off\` or \`DO_NOT_TRACK=1\` in the engine's environment also turn it"
    say "off. Details at https://turf.build/telemetry."
  fi
}

telemetry_setting() {
  "$1" telemetry status </dev/null 2>/dev/null | awk '/^Telemetry:/ { print $2; exit }'
}

# shell_telemetry_on: TURF_TELEMETRY in this shell turns it on for an engine
# started here, whatever the setting says.
shell_telemetry_on() {
  case $(lower_trim "${TURF_TELEMETRY:-}") in on | true | 1 | yes | enabled) return 0 ;; esac
  return 1
}

# engine_version MCP: the version of the local engine that is running and
# answering, or nothing.
engine_version() {
  _st=$("$1" engine status </dev/null 2>/dev/null) || return 0
  if printf '%s\n' "$_st" | grep -q '^turf-engine  *running (pid'; then
    printf '%s\n' "$_st" | sed -n 's/^version  *\([^ ]*\) (this server:.*/\1/p'
  fi
}

# engine_running MCP: `engine status` shows the local engine's process.
# engine_up MCP: it also answered the handshake. (`engine status` exits 0
# whatever the engine's state, so these read what it prints.)
engine_running() {
  _st=$("$1" engine status </dev/null 2>/dev/null) || return 1
  printf '%s\n' "$_st" | grep -q '^turf-engine  *running (pid'
}
engine_up() {
  _st=$("$1" engine status </dev/null 2>/dev/null) || return 1
  printf '%s\n' "$_st" | grep -q '^turf-engine  *running (pid' &&
    printf '%s\n' "$_st" | grep -q '^version .*(this server:'
}

# The first start sets up restate-server's store, which can take a minute.
wait_engine() {
  _i=0
  while [ "$_i" -lt 45 ]; do
    if engine_up "$1"; then
      say "The engine is running. \`turf-mcp-server engine status\` says where."
      return 0
    fi
    sleep 2
    _i=$((_i + 1))
  done
  say "The engine is still starting. Check it with: turf-mcp-server engine status"
}

install_brew() {
  _want=${tag#v}
  say "Installing Turf $tag with Homebrew."
  brew tap turfbuild/tap </dev/null
  # Compare against the tap as it is now, not as this machine last fetched it.
  _tap=$(brew --repository turfbuild/tap </dev/null 2>/dev/null || :)
  if [ -n "$_tap" ] && [ -d "$_tap/.git" ]; then
    git -C "$_tap" pull --ff-only --quiet </dev/null >/dev/null 2>&1 || :
  fi
  _have=$(brew info turfbuild/tap/turf </dev/null 2>/dev/null | sed -n '1s/.*: stable \([^ ,]*\).*/\1/p')
  _json=$(brew info --json=v2 turfbuild/tap/turf </dev/null 2>/dev/null | tr -d ' \n\t')
  case $_json in *'"service":{'*) _svc=1 ;; *) _svc=0 ;; esac
  if [ "$_have" != "$_want" ] || [ "$_svc" = 0 ]; then
    if [ "$_have" != "$_want" ]; then
      warn "Homebrew's turfbuild/tap/turf is at ${_have:-an unknown version}, and the release is $_want."
    else
      warn "Homebrew's turfbuild/tap/turf $_have doesn't set up the engine yet."
    fi
    warn "The tap catches up shortly after a release. Run this again later, or install"
    warn "from the release archive now:"
    warn "  curl -fsSL https://get.turf.build/install.sh | bash -s -- --no-brew"
    exit 1
  fi

  _before=$(brew list --versions turfbuild/tap/turf </dev/null 2>/dev/null || :)
  _running=0 _loaded=0
  _svc_json=$(brew services info turf --json </dev/null 2>/dev/null | tr -d ' \n\t' || :)
  case $_svc_json in *'"running":true'*) _running=1 ;; esac
  case $_svc_json in *'"loaded":true'*) _loaded=1 ;; esac
  if [ -n "$_before" ]; then
    brew upgrade turfbuild/tap/turf </dev/null
  else
    # Homebrew loads a formula from a third-party tap only when it is named,
    # so name turf's dependency on Restate's tap too: as turf's dependency
    # alone, Homebrew neither taps restatedev/tap nor trusts restate-server.
    brew install restatedev/tap/restate-server turfbuild/tap/turf </dev/null
  fi
  _after=$(brew list --versions turfbuild/tap/turf </dev/null 2>/dev/null || :)
  _prefix=$(brew --prefix)
  _turf=$_prefix/bin/turf
  _mcp=$_prefix/bin/turf-mcp-server

  # The service reads ~/.turf, whatever TURF_HOME this shell has.
  if [ -n "$telemetry_off" ]; then
    (unset TURF_HOME; "$_turf" telemetry off </dev/null >/dev/null)
  fi
  say ""
  (unset TURF_HOME; "$_turf" --version </dev/null)
  telemetry_notice "$(unset TURF_HOME; telemetry_setting "$_turf")"
  say ""
  if [ "$opt_no_start" = 1 ]; then
    say "Start the engine when you're ready (and at every login from then on):"
    say "  brew services start turf"
  elif [ "$_running" = 1 ] && [ "$_before" != "$_after" ]; then
    say "The engine was running, and this Turf refuses it until it restarts: finish or"
    say "cancel any rollout waiting for approval, then"
    say "  brew services restart turf"
  elif [ "$_running" = 1 ]; then
    say "The engine is running. \`turf-mcp-server engine status\` says where."
    if [ -n "$telemetry_off" ]; then
      say "It applies the telemetry setting when it restarts: brew services restart turf"
    fi
  elif (unset TURF_HOME; engine_running "$_mcp"); then
    # Started some other way: a second one would only fight it for the lock.
    say "An engine is already running for this user, outside Homebrew's service"
    say "(\`turf-mcp-server engine status\` says where). Stop it, then:"
    say "  brew services start turf"
  elif [ "$_loaded" = 1 ] && brew services restart turf </dev/null; then
    (unset TURF_HOME; wait_engine "$_mcp")
  elif [ "$_loaded" = 0 ] && brew services start turf </dev/null; then
    (unset TURF_HOME; wait_engine "$_mcp")
  else
    say "Turf is installed, but Homebrew couldn't start its service here. Start the"
    say "engine in a terminal instead, and leave it running:"
    say "  turf-mcp-server engine run"
  fi
  say ""
  say "Then: turf chat, or connect your agent: claude mcp add turf -- \"$_mcp\""
}

stage() {
  cp "$1" "$dir/.install-$$-$2"
  chmod 755 "$dir/.install-$$-$2"
  staged="$staged $2"
}

path_hint() {
  case ":$PATH:" in
    *":$dir:"*)
      _first=$(command -v turf 2>/dev/null || :)
      if [ -n "$_first" ] && [ "$_first" != "$dir/turf" ]; then
        say ""
        say "Another turf comes first on your PATH: $_first. Put $(pretty "$dir")"
        say "ahead of it, or remove that one (brew uninstall turf, if Homebrew installed it)."
      fi
      ;;
    *)
      say ""
      say "Add $(pretty "$dir") to your PATH; turf needs it to find turf-mcp-server."
      case ${SHELL:-} in
        */fish)
          say "  fish_add_path \"$(pretty "$dir")\""
          return 0
          ;;
        */zsh) _rc=.zshrc ;;
        */bash) if [ "$os" = darwin ]; then _rc=.bash_profile; else _rc=.bashrc; fi ;;
        *) _rc=.profile ;;
      esac
      say "Run this, and add it to ~/$_rc:"
      say "  export PATH=\"$(pretty "$dir"):\$PATH\""
      ;;
  esac
}

install_archive() {
  _home=${TURF_HOME:-$HOME/.turf}
  dir=${opt_dir:-$_home/bin}
  case $dir in /*) ;; *) dir=$(pwd)/$dir ;; esac
  share=$(dirname "$dir")/share
  say "Installing Turf $tag for $os/$arch into $(pretty "$dir")."

  _sum=$(awk -v f="$tarball" '{ n = $2; sub(/^\*/, "", n); if (n == f) { print $1; exit } }' "$tmp/checksums.txt")
  say "Downloading $tarball"
  get "$releases/download/$tag/$tarball" "$tmp/$tarball"
  check_sum "$tmp/$tarball" "$_sum"
  mkdir "$tmp/turf"
  tar -xzf "$tmp/$tarball" -C "$tmp/turf"
  for _b in $TURF_BINARIES; do
    if [ ! -f "$tmp/turf/$_b" ]; then die "$tarball has no $_b. Nothing was installed."; fi
  done

  _restate=fetch
  if [ -n "${TURF_RESTATE_SERVER:-}" ]; then
    _restate=theirs
  elif [ -x "$dir/restate-server" ] &&
    [ "$("$dir/restate-server" --version </dev/null 2>/dev/null | head -n 1)" = "restate-server $RESTATE_VERSION" ]; then
    _restate=kept
  fi
  if [ "$_restate" = fetch ]; then
    _rf=restate-server-$restate_triple.tar.xz
    say "Downloading restate-server $RESTATE_VERSION from github.com/restatedev/restate"
    get "$RESTATE_RELEASE/$_rf" "$tmp/$_rf"
    check_sum "$tmp/$_rf" "$restate_sha"
    mkdir "$tmp/restate"
    if ! tar -xJf "$tmp/$_rf" -C "$tmp/restate" 2>"$tmp/tar.err"; then
      if [ "$os" = linux ] && ! has xz; then
        die "unpacking restate-server needs xz: install it (apt-get install xz-utils, dnf install xz or apk add xz), then run this again."
      fi
      die "couldn't unpack $_rf: $(cat "$tmp/tar.err")"
    fi
    _rd=$tmp/restate/restate-server-$restate_triple
    if [ ! -f "$_rd/restate-server" ]; then die "$_rf has no restate-server. Nothing was installed."; fi
  fi

  case $dir in
    "$_home"/*) if [ ! -d "$_home" ]; then mkdir -p "$(dirname "$_home")" && mkdir -m 700 "$_home"; fi ;;
  esac
  mkdir -p "$dir"
  # An engine of another release keeps running, but the new binaries refuse it.
  _was_running=0 _running_version=''
  if [ -x "$dir/turf-mcp-server" ] && engine_running "$dir/turf-mcp-server"; then
    _was_running=1
    _running_version=$(engine_version "$dir/turf-mcp-server")
  fi

  # Stage everything, then move it into place without stopping for a signal:
  # an interrupted install never leaves a mix of releases, and a running engine
  # keeps the files it has open.
  for _b in $TURF_BINARIES; do stage "$tmp/turf/$_b" "$_b"; done
  if [ "$_restate" = fetch ]; then stage "$_rd/restate-server" restate-server; fi
  trap '' HUP INT TERM
  for _b in $staged; do mv -f "$dir/.install-$$-$_b" "$dir/$_b"; done
  staged=''
  trap 'exit 1' HUP INT TERM
  mkdir -p "$share/turf"
  for _f in LICENSE NOTICE README.md; do
    if [ -f "$tmp/turf/$_f" ]; then cp "$tmp/turf/$_f" "$share/turf/$_f"; fi
  done
  if [ "$_restate" = fetch ]; then
    mkdir -p "$share/restate-server"
    for _f in LICENSE NOTICE README.md; do
      if [ -f "$_rd/$_f" ]; then cp "$_rd/$_f" "$share/restate-server/$_f"; fi
    done
  fi
  if [ -n "$telemetry_off" ]; then "$dir/turf" telemetry off </dev/null >/dev/null; fi
  if [ "$_was_running" = 0 ] && engine_running "$dir/turf-mcp-server"; then
    _was_running=1
    _running_version=$(engine_version "$dir/turf-mcp-server")
  fi

  say ""
  say "Installed turf, turf-mcp-server, turf-engine and turf-builtin-provider $tag."
  case $_restate in
    fetch | kept)
      say "Beside them is restate-server $RESTATE_VERSION, the engine's dependency: Restate's own"
      say "build, from github.com/restatedev/restate, under the Business Source License 1.1"
      say "($(pretty "$share/restate-server"))."
      ;;
    theirs) say "The engine uses the restate-server TURF_RESTATE_SERVER names: $TURF_RESTATE_SERVER" ;;
  esac
  say ""
  "$dir/turf" --version </dev/null
  path_hint
  _setting=$(telemetry_setting "$dir/turf")
  if [ -z "$telemetry_off" ] && shell_telemetry_on; then _setting=on; fi
  telemetry_notice "$_setting"
  say ""
  if [ "$_was_running" = 1 ] && [ "$_running_version" = "$tag" ]; then
    say "The engine is running. \`turf-mcp-server engine status\` says where."
    if [ -n "$telemetry_off" ]; then
      say "It applies the telemetry setting when it restarts."
    fi
  elif [ "$_was_running" = 1 ]; then
    say "The engine was running, and this Turf refuses it until it restarts: finish or"
    say "cancel any rollout waiting for approval, then stop \`turf-mcp-server engine run\`"
    say "and start it again."
  else
    say "Start the engine in a terminal, and leave it running:"
    say "  turf-mcp-server engine run"
    say "Check it with: turf-mcp-server engine status"
  fi
  say ""
  say "Then: turf chat, or connect your agent:"
  say "  claude mcp add turf -- \"$(pretty "$dir")/turf-mcp-server\""
  say ""
  if [ -d "$share/restate-server" ]; then
    say "To uninstall, delete those files from $(pretty "$dir"), and $(pretty "$share/turf")"
    say "and $(pretty "$share/restate-server"). The engine's data stays in $(pretty "$_home")."
  else
    say "To uninstall, delete those files from $(pretty "$dir"), and $(pretty "$share/turf")."
    say "The engine's data stays in $(pretty "$_home")."
  fi
}

main() {
  opt_no_brew=0 opt_no_start=0 opt_no_telemetry=0
  opt_dir=${TURF_INSTALL_DIR:-} opt_version=${TURF_VERSION:-}
  while [ $# -gt 0 ]; do
    case $1 in
      --no-brew) opt_no_brew=1 ;;
      --no-start) opt_no_start=1 ;;
      --no-telemetry) opt_no_telemetry=1 ;;
      --dir)
        if [ $# -lt 2 ]; then die "--dir needs a directory."; fi
        opt_dir=$2
        shift
        ;;
      --dir=*) opt_dir=${1#--dir=} ;;
      --version)
        if [ $# -lt 2 ]; then die "--version needs a release tag."; fi
        opt_version=$2
        shift
        ;;
      --version=*) opt_version=${1#--version=} ;;
      -h | --help)
        usage
        exit 0
        ;;
      *) die "unknown option $1 (try --help)." ;;
    esac
    shift
  done

  if [ -z "${HOME:-}" ] && [ -z "${TURF_HOME:-}" ]; then
    die "HOME is not set: set it, or set TURF_HOME to the directory Turf keeps its engine in."
  fi
  for _c in curl tar awk sed grep mktemp uname; do
    if ! has "$_c"; then die "this installer needs $_c."; fi
  done
  if ! has sha256sum && ! has shasum; then die "this installer needs sha256sum or shasum."; fi
  detect_platform
  resolve_telemetry

  staged='' dir=''
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/turf-install.XXXXXX")
  trap cleanup EXIT
  trap 'exit 1' HUP INT TERM

  resolve_release
  header
  if [ "$opt_no_brew" = 0 ] && [ -z "$opt_dir" ] && [ -z "$opt_version" ] &&
    [ -z "${TURF_DOWNLOAD_URL:-}" ] && [ "$(id -u)" != 0 ] && has brew; then
    install_brew
  else
    install_archive
  fi
}

main "$@"
