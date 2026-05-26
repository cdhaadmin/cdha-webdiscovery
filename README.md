# CDHA Web Discovery Docs Site

This repository now includes a lightweight static site build for the migration documentation in `src/`.

## What was added

- `build-docs.py` and `build-docs.sh` generate a publishable site in `docs/`
- `.github/workflows/deploy-docs.yml` builds and deploys the site to GitHub Pages on pushes to `main`
- `docs/` becomes the published artifact and uses `join-renew-profile-ux-rules.md` as the site home page

## Local build

Run this from the repo root on WSL or any Linux shell:

```bash
python3 -m pip install --user markdown-it-py
bash ./build-docs.sh
```

Then open `docs/index.html` in a browser to preview the generated site.

## GitHub Pages deployment

1. Push this repository to GitHub.
2. In GitHub, open `Settings` -> `Pages`.
3. Under `Build and deployment`, choose `GitHub Actions` as the source.
4. Push to `main` or run the `Deploy Docs` workflow manually from the `Actions` tab.
5. After the workflow completes, GitHub Pages will publish the generated site.

If your default branch is `master`, the workflow also supports that. If you use a different branch name, update `.github/workflows/deploy-docs.yml`.

## Content updates

When you edit or add markdown/images under `src/`:

1. Update `build-docs.py` if you want new pages added to the sidebar navigation.
2. Run `bash ./build-docs.sh` locally to preview changes.
3. Commit and push.
4. GitHub Actions will rebuild and redeploy the site.
