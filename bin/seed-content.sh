#!/usr/bin/env bash
# Seed demo content into a fresh site with WP-CLI, from the host:
#   bin/seed-content.sh
# Needs the studio-site plugin and Secure Custom Fields active. Set NIXANT to
# the nixant command when it is not on PATH.
set -euo pipefail

nixant=${NIXANT:-nixant}
wp() { "$nixant" exec -- wp "$@"; }

if [ "$(wp post list --post_type=project --format=count)" != 0 ]; then
  echo "seed-content: projects exist already; reset with \`nixant exec -- wp site empty --yes\`" >&2
  exit 0
fi

echo "==> settings and starter content"
wp option update blogdescription "Design and development for brands that ship"
starter=$(wp post list --post_type=post,page --post_status=any --format=ids)
if [ -n "$starter" ]; then
  # shellcheck disable=SC2086 # one argument per id
  wp post delete $starter --force >/dev/null
fi

echo "==> pages"
home=$(wp post create --post_type=page --post_status=publish --post_title=Home --porcelain \
  --post_content='<!-- wp:paragraph --><p>We are a small studio designing and building websites, brands and digital products.</p><!-- /wp:paragraph -->')
about=$(wp post create --post_type=page --post_status=publish --post_title=About --porcelain \
  --post_content='<!-- wp:paragraph --><p>Founded in 2016, the studio is four designers and developers working with clients across Europe.</p><!-- /wp:paragraph -->')
journal=$(wp post create --post_type=page --post_status=publish --post_title=Journal --porcelain)
contact=$(wp post create --post_type=page --post_status=publish --post_title=Contact --porcelain \
  --post_content='<!-- wp:paragraph --><p>Write to hello@studio.example or call +358 40 123 4567.</p><!-- /wp:paragraph -->')
wp option update show_on_front page
wp option update page_on_front "$home"
wp option update page_for_posts "$journal"

echo "==> journal posts"
wp post create --post_status=publish --post_title="Why we design in the browser" \
  --post_content='<!-- wp:paragraph --><p>Static mockups hide the hard parts. Designing in code surfaces them early.</p><!-- /wp:paragraph -->' >/dev/null
wp post create --post_status=publish --post_title="Launching the Nordic Bakery shop" \
  --post_content='<!-- wp:paragraph --><p>A look behind the scenes of our biggest launch this year.</p><!-- /wp:paragraph -->' >/dev/null

echo "==> services"
for service in Branding "Web Design" Development Strategy; do
  wp term create service "$service" >/dev/null
done

echo "==> projects"
# title | client | year | url | featured | services (comma separated slugs) | excerpt
# Read from fd 3: nixant exec forwards stdin, so commands in the loop would
# otherwise consume the list.
while IFS='|' read -r -u 3 title client year url featured services excerpt; do
  id=$(wp post create --post_type=project --post_status=publish --porcelain \
    --post_title="$title" --post_excerpt="$excerpt" \
    --post_content="<!-- wp:paragraph --><p>$excerpt We worked with $client from the first workshop to launch.</p><!-- /wp:paragraph -->")
  # update_field stores the value and SCF's field reference, as the editor
  # would. eval-file, unlike eval, passes arguments through as $args.
  wp eval-file - "$id" "$client" "$year" "$url" "$featured" <<'PHP'
<?php
[ $id, $client, $year, $url, $featured ] = $args;
update_field( 'client', $client, (int) $id );
update_field( 'year', (int) $year, (int) $id );
update_field( 'project_url', $url, (int) $id );
update_field( 'featured', (bool) $featured, (int) $id );
PHP
  IFS=',' read -ra slugs <<<"$services"
  wp post term set "$id" service "${slugs[@]}" >/dev/null
  echo "  $title ($id)"
done 3<<'PROJECTS'
Nordic Bakery online shop|Nordic Bakery|2026|https://bakery.example|1|web-design,development|A fast online shop with same-day delivery slots.
Harbour Festival identity|Harbour Festival|2025|https://festival.example|0|branding,strategy|A flexible identity for a city summer festival.
Lumo Health patient portal|Lumo Health|2025|https://lumo.example|1|development,strategy|Booking and results in one accessible portal.
Kallio Architects website|Kallio Architects|2024|https://kallio.example|0|web-design|A quiet portfolio that lets the buildings speak.
Fjord Coffee rebrand|Fjord Coffee|2023|https://fjord.example|0|branding|From a single roastery to a national brand.
Polar Bikes configurator|Polar Bikes|2023|https://polar.example|0|web-design,development|Build your own bike, in 3D, in the browser.
PROJECTS

echo "==> menu"
wp menu create Primary >/dev/null
wp menu item add-post primary "$home" --title=Home >/dev/null
wp menu item add-custom primary Work /projects/ >/dev/null
wp menu item add-post primary "$about" >/dev/null
wp menu item add-post primary "$journal" >/dev/null
wp menu item add-post primary "$contact" >/dev/null
wp menu location assign primary primary

echo "==> done"
