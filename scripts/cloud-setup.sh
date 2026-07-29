#!/usr/bin/env bash
#
# Setup script for altdoc in Claude Code (claude.ai/code) cloud sessions.
#
# Paste the CONTENTS of this file into the environment's "Setup script" field
# (claude.ai web UI -> the environment for this repo). Do NOT point the field at
# a repo path: the Setup script runs at environment-build time, before the repo
# checkout, so nothing under the repo is on disk yet. This script touches no
# repo files, so it works whether or not the repo is present.
#
# Source of truth for these steps: .github/workflows/R-CMD-check.yaml, which is
# the setup actually verified in CI. It uses, in order:
#   r-lib/actions/setup-r          -> R 'release' (NOT Ubuntu's r-base-core)
#   r-lib/actions/setup-pandoc     -> pandoc
#   quarto-dev/quarto-actions/setup-> Quarto CLI
#   actions/setup-python + pip     -> Python 3.11 + mkdocs
#   setup-r-dependencies           -> the DESCRIPTION deps
# Keep this file in sync with that workflow when dependencies change.
#
# Scope: system libraries + R + pandoc + Quarto + mkdocs + the R package deps.
# altdoc builds HTML documentation sites; it renders no PDFs, so there is
# deliberately NO TinyTeX/LaTeX step here.
#
# ---------------------------------------------------------------------------
# WHY R COMES FROM CRAN'S APT REPO AND NOT `apt-get install r-base-core`
#
# Ubuntu noble ships R 4.3.3. On 4.3.3 `tools::Rd2HTML()` emits
#   <h2 id='topic'>Title</h2>
# while R/rd2qmd.R:101 matches `grep("^<h2>", tmp)` -- an exact tag, no
# attributes. The grep returns NA, and every test that renders a man page dies
# with "NA/NaN argument". That is 28 test failures with a single cause, none of
# them a real defect in the package under test. CI is green because setup-r
# installs R 'release'. Installing R from CRAN's repo below reproduces CI.
# ---------------------------------------------------------------------------
#
# ---------------------------------------------------------------------------
# NETWORK: which hosts this needs, and one counter-intuitive result
#
# Verified by probing from inside a real cloud session (2026-07-28). If the
# environment uses a restricted network policy rather than 'Full', allowlist:
#   cloud.r-project.org        R itself (apt repo) + every CRAN source package
#   quarto.org                 the Quarto .deb  -- see the note below
#   release-assets.githubusercontent.com   where quarto.org redirects for bytes
#   pypi.org  files.pythonhosted.org       mkdocs via pip (often already allowed)
#
# The counter-intuitive part: in this environment
#   https://github.com/quarto-dev/quarto-cli/releases/latest  -> 403
#   https://quarto.org/download/latest/quarto-linux-amd64.deb -> 200
# which is the OPPOSITE of the usual advice to avoid quarto.org and mirror from
# GitHub releases. So quarto.org is the primary source here and the GitHub
# release is the fallback, not the other way round. Both are attempted; if your
# network inverts this again, the fallback covers it with no edit.
#
# NOT required: api.github.com (nothing here reads it), CTAN mirrors (no LaTeX),
# p3m.dev / packagemanager.posit.co (blocked here -- CRAN source is used
# instead, which is why the R package install is compile-bound and slow).
# ---------------------------------------------------------------------------

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Some cloud environments route HTTPS through a TLS-intercepting proxy whose CA
# is in the system store (so apt/curl/R-via-libcurl work) but NOT in tools that
# bundle their own roots (Deno/Quarto), which then fail with "invalid peer
# certificate: UnknownIssuer". Point those at the system bundle.
export SSL_CERT_FILE="${SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}"
export CURL_CA_BUNDLE="${CURL_CA_BUNDLE:-/etc/ssl/certs/ca-certificates.crt}"
export DENO_TLS_CA_STORE=system

# The cloud Setup script usually runs AS ROOT, where `sudo` is often not
# installed -- a literal `sudo` then fails with exit 127 and aborts the build
# under `set -e`. Resolve once. (`$SUDO cmd` with an empty $SUDO word-splits to
# just `cmd`.)
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
elif command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  echo "ERROR: not root and 'sudo' is not installed; cannot install packages." >&2
  exit 1
fi

# Some Claude Code base images preconfigure the `deadsnakes` and `ondrej/php`
# launchpad PPAs, whose signing returns 403 ("no longer signed") -- that makes
# ANY `apt-get update` fail with exit 100 before anything installs. altdoc needs
# neither. Harmless no-op on images that do not have them (this one did not).
echo "==> Removing broken third-party apt sources, if present"
while IFS= read -r src; do
  echo "    removing $src"
  $SUDO rm -f "$src"
done < <(grep -rlE 'launchpadcontent\.net|deadsnakes|ondrej' \
          /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null || true)

echo "==> Installing system libraries (apt)"
# pandoc is the CI `setup-pandoc` step. The -dev libraries are what the R
# dependency tree needs to compile from source: curl/ssl/xml2 for the usual
# suspects, git2 for gert (usethis), and the font/image stack for
# textshaping/ragg (pulled in via downlit/pkgdown-adjacent packages).
$SUDO apt-get update
$SUDO apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  pandoc \
  python3 \
  python3-pip \
  libcurl4-openssl-dev \
  libssl-dev \
  libxml2-dev \
  libgit2-dev \
  libfontconfig1-dev \
  libharfbuzz-dev \
  libfribidi-dev \
  libfreetype6-dev \
  libpng-dev \
  libtiff5-dev \
  libjpeg-dev

echo "==> Installing R (release) from the CRAN apt repository"
# See the "WHY R COMES FROM CRAN'S APT REPO" note above -- Ubuntu's 4.3.3 breaks
# 28 tests. apt uses the system CA store, so this works behind the TLS proxy
# (unlike rig, whose rustls client rejects the proxy cert).
if ! command -v R >/dev/null 2>&1 || \
   ! R --version | head -1 | grep -qE ' 4\.(([6-9])|([1-9][0-9]))'; then
  . /etc/os-release
  $SUDO install -d -m 0755 /etc/apt/keyrings
  curl -fsSL https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc \
    | $SUDO tee /etc/apt/keyrings/cran_r.asc >/dev/null
  echo "deb [signed-by=/etc/apt/keyrings/cran_r.asc] https://cloud.r-project.org/bin/linux/ubuntu ${VERSION_CODENAME:-noble}-cran40/" \
    | $SUDO tee /etc/apt/sources.list.d/cran-r.list >/dev/null
  $SUDO apt-get update
  $SUDO apt-get install -y --no-install-recommends r-base-core r-base-dev
fi

echo "==> Installing Quarto"
# Primary source is quarto.org; the GitHub release is the fallback. See the
# NETWORK note above for why that order is the reverse of the usual advice.
# Best-effort: a failure warns and continues, since R stays usable without it
# (the quarto-dependent tests then skip rather than fail).
if ! command -v quarto >/dev/null 2>&1; then
  arch="$(dpkg --print-architecture)"
  tmp_deb="$(mktemp --suffix=.deb)"
  trap 'rm -f "$tmp_deb"' EXIT
  quarto_got=false

  if curl -fsSL "https://quarto.org/download/latest/quarto-linux-${arch}.deb" \
       -o "$tmp_deb"; then
    quarto_got=true
  else
    # Fallback: resolve the version from the /releases/latest redirect Location
    # (not api.github.com, which is rate-limited on shared cloud egress IPs).
    qv="$(curl -fsS -o /dev/null -w '%{redirect_url}' \
      https://github.com/quarto-dev/quarto-cli/releases/latest 2>/dev/null || true)"
    qv="${qv##*/tag/v}"
    # Sanity-check the shape before building a URL, so a changed redirect format
    # fails fast into the warning instead of fetching garbage.
    if printf '%s' "$qv" | grep -qE '^[0-9]+(\.[0-9]+)+$' \
       && curl -fsSL \
            "https://github.com/quarto-dev/quarto-cli/releases/download/v${qv}/quarto-${qv}-linux-${arch}.deb" \
            -o "$tmp_deb"; then
      quarto_got=true
    fi
  fi

  if [ "$quarto_got" = true ] && $SUDO apt-get install -y --no-install-recommends "$tmp_deb"; then
    :
  else
    echo "WARNING: Could not install Quarto from quarto.org or github.com." >&2
    echo "         R is usable; the Quarto-dependent tests will skip." >&2
    echo "         Allowlist quarto.org + release-assets.githubusercontent.com." >&2
  fi
fi

echo "==> Installing mkdocs"
# tests/testthat/test-render_docs.R exercises the mkdocs output format, which
# shells out to the mkdocs CLI. Mirrors CI's setup-python + pip step.
# --break-system-packages: noble marks the system Python EXTERNALLY-MANAGED
# (PEP 668), and a container build has no reason to spin up a venv for one tool.
if ! command -v mkdocs >/dev/null 2>&1; then
  python3 -m pip install --upgrade --quiet --break-system-packages pip || true
  python3 -m pip install --quiet --break-system-packages mkdocs \
    || echo "WARNING: mkdocs install failed; the mkdocs render tests will fail." >&2
fi

echo "==> Installing R package dependencies"
# The equivalent of CI's setup-r-dependencies: DESCRIPTION's Imports plus the
# Suggests the test suite actually loads, plus pkgload for `load_all()`.
# NOTE: this compiles from CRAN source (p3m.dev binaries are blocked here), so
# it is the slowest step by a wide margin -- budget ~20-30 min on 4 cores. If
# packagemanager.posit.co is ever allowlisted, adding it as the repo turns this
# into a binary install and cuts it to a couple of minutes.
$SUDO Rscript -e '
  options(repos = c(CRAN = "https://cloud.r-project.org"), Ncpus = max(1L, parallel::detectCores()))
  pkgs <- c(
    # Imports
    "cli", "desc", "evaluate", "fs", "quarto", "rmarkdown", "rex",
    # Suggests exercised by the test suite
    "digest", "downlit", "future", "future.apply", "knitr", "servr",
    "testthat", "usethis", "withr", "yaml",
    # dev loop
    "pkgload"
  )
  missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) install.packages(missing)
'

echo "==> Setup complete:"
R --version | head -1
pandoc --version | head -1
if command -v quarto >/dev/null 2>&1; then quarto --version; else echo "quarto: NOT installed (see WARNING above)"; fi
if command -v mkdocs >/dev/null 2>&1; then mkdocs --version; else echo "mkdocs: NOT installed (see WARNING above)"; fi

# Run the suite with:
#   NOT_CRAN=true Rscript -e 'pkgload::load_all(); testthat::test_dir("tests/testthat")'
# NOT_CRAN=true matters: without it the Quarto/mkdocs tests skip and a run can
# look green while never exercising the render paths at all.
#
# Expected result on a correctly built environment, measured 2026-07-28 on
# origin/main at ec2201f:
#
#   [ FAIL 1 | WARN 0 | SKIP 3 | PASS 512 ]
#
# The one failure is pre-existing and unrelated to this script:
#   test-render_docs.R:411 "quarto: autolink" -- expects downlit to autolink
#   library() to https://rdrr.io/r/base/library.html in the rendered vignette.
# It reproduces identically on a clean checkout of main, so treat a run that
# shows exactly this one failure as GREEN. Anything else is a real regression.
#
# For comparison, the same suite on Ubuntu's R 4.3.3 gives FAIL 28 -- all 28
# from the single Rd2HTML `<h2 id=...>` cause described at the top. If you see
# 28 failures, the CRAN apt repo step did not take effect and you are on 4.3.3;
# check with `R --version`.
