#!/usr/bin/env bash
# Export the site as static HTML with Simply Static and commit it as the root
# of the `static` branch, for GitHub Pages ("Deploy from a branch": static, /):
#   bin/export-static.sh [https://<user>.github.io/<repo>]
# Links are rewritten to the given URL. The working tree and the current branch
# are not touched; push with `git push origin static`. Set NIXANT to the nixant
# command when it is not on PATH, STATIC_BRANCH for another branch name, and
# STATIC_SOURCE to describe the source in the commit message (CI does).
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
nixant=${NIXANT:-nixant}
url=${1:-https://jasalt.github.io/nixant-wp-demo}
branch=${STATIC_BRANCH:-static}
build=.static-build # git-ignored; the guest sees it as /workspace/.static-build
wp() { "$nixant" exec -- wp "$@"; }

wp plugin is-installed simply-static || wp plugin install simply-static
wp plugin activate simply-static >/dev/null

# The free version has no WP-CLI command; set the options and start the export
# through its PHP API. It then runs as a background process over loopback
# requests to the site URL.
wp eval-file - "$url" "/workspace/$build/" <<'PHP'
<?php
[ $url, $dir ] = $args;
$parts = wp_parse_url( untrailingslashit( $url ) );
$options = array_merge(
	(array) get_option( 'simply-static', array() ),
	array(
		'delivery_method'               => 'local',
		'local_dir'                     => $dir,
		'clear_directory_before_export' => true,
		'destination_url_type'          => 'absolute',
		'destination_scheme'            => $parts['scheme'] . '://',
		'destination_host'              => $parts['host'] . ( $parts['path'] ?? '' ),
		// Pages and what they reference. smart_crawl and the default crawlers
		// copy all of wp-includes and plugin assets (about 1,900 files, 75 MB).
		'smart_crawl'                   => false,
		'crawlers'                      => array( 'home', 'post_type', 'archive', 'taxonomy', 'pagination', 'sitemap', 'uploads', 'theme_assets' ),
		'generate_404'                  => true,
	)
);
update_option( 'simply-static', $options );
if ( ! \Simply_Static\Plugin::instance()->run_static_export() ) {
	WP_CLI::error( 'Simply Static did not start an export; one may be running already.' );
}
PHP

echo "export-static: exporting for $url"
while wp eval 'exit( \Simply_Static\Plugin::instance()->is_export_active() ? 0 : 1 );'; do
  sleep 2
done
# shellcheck disable=SC2016 # PHP code, expanded by wp eval
wp eval '$m = get_option( "simply-static" ); foreach ( (array) ( $m["archive_status_messages"] ?? array() ) as $k => $v ) { echo "  $k: ", is_array( $v ) ? ( $v["message"] ?? "" ) : $v, "\n"; }'
[ -e "$build/index.html" ] || { echo "export-static: no index.html in $build/; the export failed" >&2; exit 1; }

# GitHub Pages: serve the files as they are, without Jekyll.
touch "$build/.nojekyll"

# Commit the build directory as the branch's root with a temporary index, so
# nothing is checked out and the current branch's index stays as it is.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
GIT_INDEX_FILE="$tmp/index" git --work-tree="$build" add --all --force .
tree=$(GIT_INDEX_FILE="$tmp/index" git write-tree)
parent=$(git rev-parse -q --verify "refs/heads/$branch" || true)
if [ -n "$parent" ] && [ "$(git rev-parse "$parent^{tree}")" = "$tree" ]; then
  echo "export-static: $branch is up to date"
  exit 0
fi
source=${STATIC_SOURCE:-$(git rev-parse --short HEAD)}
if [ -z "${STATIC_SOURCE:-}" ] && ! git diff --quiet HEAD --; then
  source="$source with uncommitted changes"
fi
commit=$(git commit-tree "$tree" ${parent:+-p "$parent"} -m "Static export of $source for $url")
git update-ref "refs/heads/$branch" "$commit" ${parent:+"$parent"}
echo "export-static: committed $(git ls-tree -r --name-only "$commit" | wc -l) files to $branch ($(git rev-parse --short "$commit")); push with: git push origin $branch"
