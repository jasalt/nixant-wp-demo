# Studio demo site

A demo WordPress site for a design studio: a custom theme, a Project post type with Secure Custom Fields, and a filterable project archive. It runs in its own Incus container managed by [nixant](https://github.com/jasalt/nixant-py), with the WordPress stack from [nixant-wp](https://github.com/jasalt/nixant-wp).

## Components

| Path | What it is |
|---|---|
| `flake.nix` | The nixant project: one NixOS guest (`nixosConfigurations.dev`) built from nixant's container module, nixant-wp's `wordpress` module and `nix/site.nix`. |
| `flake.lock` | Pins nixpkgs, nixant and nixant-wp (currently local checkouts, see below). |
| `nix/site.nix` | Instance settings: name `wpdemo-dev`, guest user UID, forwarded ports (8081 → site, 8025 → Mailpit), and the `wordpress` block (title, web root `public/`). |
| `public/` | The whole WordPress installation, shared with the guest at `/workspace/public`. Core, `wp-config.php`, uploads and third-party plugins are created in place and ignored by git. |
| `public/wp-content/themes/studio/` | The theme (tracked): project archive and service archives (`archive-project.php`, `taxonomy-service.php`), project page (`single-project.php`), card partial and CSS. |
| `public/wp-content/plugins/studio-site/` | The site plugin (tracked): the `project` post type at `/projects/`, the `service` taxonomy at `/services/`, the SCF field group (client, year, live URL, featured) and archive ordering. Requires Secure Custom Fields. |
| `bin/provision.sh` | Provisioning after `nixant up`: pinned plugins from wordpress.org, site plugin and theme, content. Used locally and by CI. |
| `bin/export-static.sh` | Static export for GitHub Pages with Simply Static, committed to the `static` branch (see below). |
| `bin/seed-content.sh` | Demo content through WP-CLI: pages, front page, journal posts, services, six projects with fields, the menu. |
| `.github/workflows/static.yml` | CI: builds the static site on every push to `master` and pushes it to the `static` branch. |
| `.gitignore` | Keeps `public/` out of git except the `!` lines for `studio` and `studio-site`. Add a line for every plugin or theme you write, or git will not see it. |

Inside the guest: MariaDB (socket auth, no password), PHP-FPM and Caddy running as the guest user, Mailpit, WP-CLI, and `wordpress-setup.service`, which seeds the core, writes `wp-config.php`, installs the site and keeps its URL current; it reruns at boot and whenever the settings change.

## Provisioning

Needs Linux, Nix with flakes, Incus with your user in `incus-admin`, and your UID equal to `nixant.user.uid` in `nix/site.nix` (`id -u`). The commands use `nixant`; without it installed, use `nix run github:jasalt/nixant-py --` instead (slower: it re-evaluates for every call).

```console
# 1. Lock nixant and nixant-wp to their published repositories.
$ nix flake update nixant nixant-wp
#    Or, to work on them, point them at local checkouts instead:
$ nix flake lock --override-input nixant path:../nixant --override-input nixant-wp path:../nixant-wp

# 2. Create the container and the WordPress site (core into public/, database, admin user).
$ nixant up

# 3. Plugins (pinned versions from wordpress.org), theme and content.
$ bin/provision.sh                     # NIXANT=<command> if nixant is not on PATH
```

`bin/provision.sh` is safe to rerun. Content comes from `content/site.sql` when that dump exists (`nixant exec -- wp db export /workspace/content/site.sql`), otherwise from `bin/seed-content.sh`; a site that has projects already is left alone. Plugin versions are pinned in the script; bump them there after testing an update locally.

Then:

- site: <http://localhost:8081>, projects at <http://localhost:8081/projects/>
- admin: <http://localhost:8081/wp-admin/> as `admin` / `password` (development only)
- mail: <http://localhost:8025>

Rerun step 1 after pulling changes to nixant or nixant-wp, then `nixant up`.

## Working on it

Edit files under `public/` on the host; changes are live on the next request.

```console
$ nixant exec -- wp-site check                    # site, login redirect and mail
$ tail -f public/wp-content/debug.log             # PHP errors (not shown on the page)
$ nixant exec -- wp db export /workspace/db.sql   # WP-CLI sees the project at /workspace
$ nixant exec -- wp site empty --yes && bin/seed-content.sh   # reset the content
$ nixant destroy                                  # removes the container and database; public/ stays
```

## Static export for GitHub Pages

```console
$ bin/export-static.sh https://<user>.github.io/<repo>
$ git push origin static
```

The script installs [Simply Static](https://wordpress.org/plugins/simply-static/) if needed, exports the site (about 20 files, a few seconds) with links rewritten to the given URL, a `404.html` and `.nojekyll`, and commits the result as the root of the `static` branch. It builds in the git-ignored `.static-build/` and commits with a temporary index, so the working tree and the current branch are left alone; an export without changes adds no commit. In the repository's settings, set Pages to "Deploy from a branch", branch `static`, folder `/ (root)`.

### In CI

`.github/workflows/static.yml` runs the same steps on a GitHub-hosted runner on every push to `master` (or by hand): it installs Nix and Incus, runs `nixant up`, `bin/provision.sh`, `wp-site check` and `bin/export-static.sh`, and pushes `static`. A run takes a few minutes. It needs:

- `flake.lock` pointing at the published nixant and nixant-wp (step 1 above), not at `path:` checkouts;
- write access for the workflow (`contents: write`, set in the file; allow it under Settings → Actions → General if the repository restricts it);
- optionally a `PAGES_URL` repository variable, for a custom domain; the default is `https://<owner>.github.io/<repo>`.

The workflow changes `nixant.user.uid` in its checkout to the runner user's UID (1001, not the 1000 in `nix/site.nix`), because the guest user's UID must equal the host user's for the workspace mount to be writable. The change is never committed. Content in CI comes from the repository only: commit `content/site.sql` (and uploads) for anything beyond the demo content.

The export is plain HTML: anything dynamic (search, comments, forms, login) does not work on Pages. Simply Static fetches the pages over HTTP from the site URL inside the guest; nixant-wp serves the URL's port there for this, and `wp-site check` tests it.

Snapshots (`nixant snapshot <name>`) cover the database but not `public/`; export the database next to the files for a consistent copy.
