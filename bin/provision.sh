#!/usr/bin/env bash
# Provision the site after `nixant up`: third-party plugins, the site plugin and
# theme, and content. Used for local setup and by CI
# (.github/workflows/static.yml); safe to rerun:
#   bin/provision.sh
# Set NIXANT to the nixant command when it is not on PATH.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
nixant=${NIXANT:-nixant}
wp() { "$nixant" exec -- wp "$@"; }

# Plugins from wordpress.org are not in git; pin them so CI builds the site you
# previewed. Bump a version here after testing the update locally.
plugins=(
  secure-custom-fields:6.9.5
  simply-static:3.8.17
)
for entry in "${plugins[@]}"; do
  slug=${entry%%:*}
  version=${entry#*:}
  if [ "$(wp plugin get "$slug" --field=version 2>/dev/null || true)" != "$version" ]; then
    wp plugin install "$slug" --version="$version" --force
  fi
done
# In dependency order: studio-site requires Secure Custom Fields.
wp plugin activate secure-custom-fields simply-static studio-site
wp theme activate studio

# Content: a committed database dump (content/site.sql, from
# `nixant exec -- wp db export /workspace/content/site.sql`) wins, otherwise the
# demo content. A site that has projects already is left alone.
if [ "$(wp post list --post_type=project --format=count)" != 0 ]; then
  echo "provision: the site has content; leaving it"
elif [ -e content/site.sql ]; then
  wp db import /workspace/content/site.sql
  wp rewrite flush
else
  NIXANT=$nixant bin/seed-content.sh
fi
